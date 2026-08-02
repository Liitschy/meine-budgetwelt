extends Node

signal session_changed(user: Dictionary)
signal sync_status_changed(status: String, message: String)
signal snapshot_imported(revision: int)
signal sync_conflict(current: Dictionary)

const DEFAULT_SERVER_URL := "https://budget.leno.info"
const SESSION_FILE := "user://account_session.dat"
const DEVICE_FILE := "user://sync_device.json"
const SESSION_SALT := "meine-budgetwelt-session-v1"
const LIVE_SYNC_INTERVAL_SECONDS := 5.0

var server_url := DEFAULT_SERVER_URL
var current_user: Dictionary = {}
var groups: Array = []
var active_group_id := ""
var current_revision := 0
var _token := ""
var _remember_session := false
var _applying_remote_snapshot := false
var _request_in_progress := false
var _device_id := ""
var _sync_timer: Timer
var _live_sync_timer: Timer
var startup_restore_attempted := false


func _ready() -> void:
	server_url = _configured_server_url()
	_device_id = _load_or_create_device_id()
	_sync_timer = Timer.new()
	_sync_timer.one_shot = true
	_sync_timer.wait_time = 1.2
	_sync_timer.timeout.connect(_on_sync_timer_timeout)
	add_child(_sync_timer)
	_live_sync_timer = Timer.new()
	_live_sync_timer.one_shot = false
	_live_sync_timer.wait_time = LIVE_SYNC_INTERVAL_SECONDS
	_live_sync_timer.timeout.connect(_on_live_sync_timer_timeout)
	add_child(_live_sync_timer)
	call_deferred("_connect_local_change_signals")


func login(email: String, password: String, remember_me: bool) -> Dictionary:
	var clean_email := email.strip_edges()
	if clean_email.is_empty() or password.length() < 8:
		return _failure("Bitte E-Mail-Adresse und Kennwort vollständig eingeben.")
	var endpoint := "/api/auth/login" if OS.has_feature("web") else "/api/auth/desktop-login"
	var response := await _request_json(
		HTTPClient.METHOD_POST,
		endpoint,
		{
			"email": clean_email,
			"password": password,
			"rememberMe": remember_me,
		},
		false
	)
	if int(response.code) != 200:
		return _failure(
			"E-Mail-Adresse oder Kennwort ist nicht korrekt."
			if int(response.code) == 401
			else _response_message(response, "Die Anmeldung ist fehlgeschlagen.")
		)

	var data: Dictionary = response.data if response.data is Dictionary else {}
	current_user = data.get("user", {})
	_token = str(data.get("token", ""))
	_remember_session = remember_me
	if not OS.has_feature("web"):
		if _token.is_empty():
			clear_session()
			return _failure("Der Server hat keine gültige Sitzung zurückgegeben.")
		if remember_me:
			_save_session(data)
		else:
			_delete_session_file()
	session_changed.emit(current_user.duplicate(true))
	var initial_sync := await initialize_sync()
	if not bool(initial_sync.get("success", false)):
		return initial_sync
	_live_sync_timer.start()
	return {
		"success": true,
		"user": current_user.duplicate(true),
		"message": "Anmeldung und Synchronisation waren erfolgreich.",
	}


func restore_session() -> Dictionary:
	startup_restore_attempted = true
	if not OS.has_feature("web"):
		var saved := _load_session()
		_token = str(saved.get("token", ""))
		_remember_session = not _token.is_empty()
		if _token.is_empty():
			return _failure("Keine gespeicherte Sitzung vorhanden.")
	var response := await _request_json(HTTPClient.METHOD_GET, "/api/auth/me")
	if int(response.code) != 200 or not response.data is Dictionary:
		clear_session()
		return _failure("Die gespeicherte Sitzung ist abgelaufen.")
	current_user = response.data
	session_changed.emit(current_user.duplicate(true))
	var initial_sync := await initialize_sync()
	if bool(initial_sync.get("success", false)):
		_live_sync_timer.start()
	return initial_sync


func logout() -> void:
	if is_logged_in():
		await _request_json(HTTPClient.METHOD_POST, "/api/auth/logout")
	clear_session()


func clear_session() -> void:
	if is_instance_valid(_live_sync_timer):
		_live_sync_timer.stop()
	_token = ""
	_remember_session = false
	current_user.clear()
	groups.clear()
	active_group_id = ""
	current_revision = 0
	_delete_session_file()
	session_changed.emit({})


func is_logged_in() -> bool:
	return not current_user.is_empty() and (OS.has_feature("web") or not _token.is_empty())


func configure_server_url(value: String) -> bool:
	if not is_valid_server_url(value):
		return false
	server_url = value.strip_edges().trim_suffix("/")
	return true


func initialize_sync() -> Dictionary:
	var group_result := await refresh_groups()
	if not bool(group_result.get("success", false)):
		return group_result
	if groups.is_empty():
		return _failure("Das Konto ist noch keiner Budgetgruppe zugeordnet.")
	var preferred_group := str(_load_device_state().get("active_group_id", ""))
	active_group_id = str(groups[0].get("id", ""))
	for group: Dictionary in groups:
		if str(group.get("id", "")) == preferred_group:
			active_group_id = preferred_group
			break
	_save_device_state()
	var server_revision := int(groups.filter(
		func(group: Dictionary) -> bool:
			return str(group.get("id", "")) == active_group_id
	)[0].get("revision", 0))
	if server_revision == 0:
		current_revision = 0
		return await push_local_snapshot()
	return await pull_server_snapshot()


func refresh_groups() -> Dictionary:
	var response := await _request_json(HTTPClient.METHOD_GET, "/api/sync/groups")
	if int(response.code) == 401:
		clear_session()
		return _failure("Die Sitzung ist abgelaufen. Bitte erneut anmelden.")
	if int(response.code) != 200 or not response.data is Array:
		return _failure(_response_message(response, "Budgetgruppen konnten nicht geladen werden."))
	groups = response.data
	return {"success": true, "groups": groups.duplicate(true)}


func select_group(group_id: String) -> Dictionary:
	for group: Dictionary in groups:
		if str(group.get("id", "")) == group_id:
			active_group_id = group_id
			current_revision = int(group.get("revision", 0))
			_save_device_state()
			return await pull_server_snapshot() if current_revision > 0 else await push_local_snapshot()
	return _failure("Die ausgewählte Budgetgruppe ist nicht verfügbar.")


func pull_server_snapshot() -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe ausgewählt.")
	_sync_status("syncing", "Daten werden vom Server geladen …")
	var response := await _request_json(
		HTTPClient.METHOD_GET,
		"/api/sync/groups/%s/snapshot" % active_group_id.uri_encode()
	)
	if int(response.code) != 200 or not response.data is Dictionary:
		return _sync_failure(response, "Der Server-Datenstand konnte nicht geladen werden.")
	var snapshot: Dictionary = response.data
	var revision := int(snapshot.get("revision", 0))
	if revision == 0 or snapshot.get("data", null) == null:
		current_revision = 0
		return await push_local_snapshot()
	_applying_remote_snapshot = true
	var import_result := StorageManager.import_sync_snapshot(snapshot.get("data", {}))
	if not bool(import_result.get("success", false)):
		_applying_remote_snapshot = false
		_sync_status("error", str(import_result.get("message", "Synchronisation fehlgeschlagen.")))
		return import_result
	_reload_runtime_data()
	_applying_remote_snapshot = false
	current_revision = revision
	_save_device_state()
	snapshot_imported.emit(current_revision)
	_sync_status("synced", "Synchronisiert – Stand %d" % current_revision)
	return {
		"success": true,
		"revision": current_revision,
		"imported": true,
		"message": "Der aktuelle Server-Datenstand wurde übernommen.",
	}


func push_local_snapshot() -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe ausgewählt.")
	_sync_status("syncing", "Änderungen werden sicher synchronisiert …")
	var response := await _request_json(
		HTTPClient.METHOD_PUT,
		"/api/sync/groups/%s/snapshot" % active_group_id.uri_encode(),
		{
			"baseRevision": current_revision,
			"data": StorageManager.export_sync_snapshot(),
			"deviceId": _device_id,
		}
	)
	if int(response.code) == 409:
		var conflict_data: Dictionary = response.data if response.data is Dictionary else {}
		var current: Dictionary = conflict_data.get("current", {})
		sync_conflict.emit(current)
		_sync_status(
			"conflict",
			"Auf einem anderen Gerät liegen neuere Änderungen vor. Nichts wurde überschrieben."
		)
		return {
			"success": false,
			"conflict": true,
			"current": current,
			"message": "Neuere Serverdaten wurden geschützt.",
		}
	if int(response.code) != 200 or not response.data is Dictionary:
		return _sync_failure(response, "Änderungen konnten nicht synchronisiert werden.")
	current_revision = int(response.data.get("revision", current_revision + 1))
	_save_device_state()
	_sync_status("synced", "Synchronisiert – Stand %d" % current_revision)
	return {
		"success": true,
		"revision": current_revision,
		"message": "Alle Änderungen sind synchronisiert.",
	}


func request_weekly_plan(planning_data: Dictionary) -> Dictionary:
	if not is_logged_in():
		return _failure("Bitte zuerst mit deinem Budgetwelt-Konto anmelden.")
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe für die Wochenplanung ausgewählt.")
	var response := await _request_json(
		HTTPClient.METHOD_POST,
		"/api/planning/groups/%s/weekly-plan" % active_group_id.uri_encode(),
		planning_data,
		true,
		120.0
	)
	if int(response.code) == 401:
		clear_session()
		return _failure("Die Sitzung ist abgelaufen. Bitte erneut anmelden.")
	if int(response.code) == 403:
		return _failure("Dieses Konto darf die ausgewählte Budgetgruppe nicht planen.")
	if int(response.code) == 429:
		return _failure("Zu viele Planungsanfragen. Bitte in einigen Minuten erneut versuchen.")
	if int(response.code) != 200 or not response.data is Dictionary:
		return _failure(_response_message(
			response,
			"Der KI-Wochenplan konnte nicht erstellt werden."
		))
	return {
		"success": true,
		"draft": (response.data as Dictionary).duplicate(true),
		"message": "Der geprüfte Wochenplan-Entwurf ist bereit.",
	}


func request_banking_status() -> Dictionary:
	return await _banking_request(
		HTTPClient.METHOD_GET,
		"/api/banking/status",
		null,
		200,
		"Der Bankstatus konnte nicht geladen werden."
	)


func request_bank_institutions(country: String = "DE") -> Dictionary:
	return await _banking_request(
		HTTPClient.METHOD_GET,
		"/api/banking/institutions?country=%s" % country.uri_encode(),
		null,
		200,
		"Die Bankenliste konnte nicht geladen werden."
	)


func request_bank_connections() -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe für die Bankverbindung ausgewählt.")
	return await _banking_request(
		HTTPClient.METHOD_GET,
		"/api/banking/groups/%s/connections" % active_group_id.uri_encode(),
		null,
		200,
		"Die Bankverbindungen konnten nicht geladen werden."
	)


func create_bank_connection(institution_id: String) -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe für die Bankverbindung ausgewählt.")
	return await _banking_request(
		HTTPClient.METHOD_POST,
		"/api/banking/groups/%s/connections" % active_group_id.uri_encode(),
		{"institutionId": institution_id},
		200,
		"Die Bankverbindung konnte nicht vorbereitet werden."
	)


func refresh_bank_connection(connection_id: String, known_import_ids: Array[String]) -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe für den Bankabruf ausgewählt.")
	return await _banking_request(
		HTTPClient.METHOD_POST,
		"/api/banking/groups/%s/connections/%s/refresh" % [
			active_group_id.uri_encode(),
			connection_id.uri_encode(),
		],
		{"knownImportIds": known_import_ids},
		200,
		"Die Bankdaten konnten nicht aktualisiert werden.",
		60.0
	)


func disconnect_bank_connection(connection_id: String) -> Dictionary:
	if active_group_id.is_empty():
		return _failure("Keine Budgetgruppe für die Bankverbindung ausgewählt.")
	return await _banking_request(
		HTTPClient.METHOD_DELETE,
		"/api/banking/groups/%s/connections/%s" % [
			active_group_id.uri_encode(),
			connection_id.uri_encode(),
		],
		null,
		204,
		"Die Bankverbindung konnte nicht getrennt werden."
	)


func _banking_request(
	method: HTTPClient.Method,
	path: String,
	body: Variant,
	expected_code: int,
	fallback: String,
	timeout_seconds: float = 30.0
) -> Dictionary:
	if not is_logged_in():
		return _failure("Bitte zuerst mit deinem Budgetwelt-Konto anmelden.")
	var response := await _request_json(
		method,
		path,
		body,
		true,
		timeout_seconds
	)
	if int(response.code) == 401:
		clear_session()
		return _failure("Die Sitzung ist abgelaufen. Bitte erneut anmelden.")
	if int(response.code) == 403:
		return _failure("Dieses Konto darf die Bankverbindung nicht verwalten.")
	if int(response.code) == 429:
		return _failure("Zu viele Bankanfragen. Bitte später erneut versuchen.")
	if int(response.code) != expected_code:
		return _failure(_response_message(response, fallback))
	return {
		"success": true,
		"data": response.data,
		"message": "Bankanfrage erfolgreich.",
	}


func request_password_reset(email: String) -> Dictionary:
	var response := await _request_json(
		HTTPClient.METHOD_POST,
		"/api/auth/forgot-password",
		{"email": email.strip_edges()},
		false
	)
	return (
		{"success": true, "message": "Wenn das Konto existiert, wurde eine E-Mail versendet."}
		if int(response.code) == 202
		else _failure(_response_message(response, "Die Anfrage konnte nicht gesendet werden."))
	)


func register_with_invitation(
	name: String,
	password: String,
	invitation_token: String
) -> Dictionary:
	if password.length() < 8:
		return _failure("Das Kennwort muss mindestens 8 Zeichen lang sein.")
	var response := await _request_json(
		HTTPClient.METHOD_POST,
		"/api/auth/register",
		{
			"name": name.strip_edges(),
			"password": password,
			"token": invitation_token.strip_edges(),
		},
		false
	)
	return (
		{"success": true, "user": response.data, "message": "Konto wurde erstellt."}
		if int(response.code) == 201
		else _failure(_response_message(response, "Das Konto konnte nicht erstellt werden."))
	)


static func is_valid_server_url(value: String) -> bool:
	var clean := value.strip_edges().trim_suffix("/")
	if clean.begins_with("https://"):
		return clean.length() > "https://".length() and clean.find("/", 8) == -1
	for prefix in ["http://127.0.0.1", "http://localhost"]:
		if clean == prefix:
			return true
		if clean.begins_with(prefix + ":"):
			return clean.substr((prefix + ":").length()).is_valid_int()
	return false


func _request_json(
	method: HTTPClient.Method,
	path: String,
	body: Variant = null,
	use_session: bool = true,
	timeout_seconds: float = 20.0
) -> Dictionary:
	while _request_in_progress:
		await get_tree().process_frame
	_request_in_progress = true
	var request := HTTPRequest.new()
	request.timeout = clampf(timeout_seconds, 5.0, 180.0)
	add_child(request)
	var headers := PackedStringArray(["Accept: application/json"])
	if use_session and not _token.is_empty():
		headers.append("Authorization: Bearer %s" % _token)
	var encoded_body := ""
	if body != null:
		headers.append("Content-Type: application/json; charset=utf-8")
		encoded_body = JSON.stringify(body)
	var error := request.request(server_url + path, headers, method, encoded_body)
	if error != OK:
		request.queue_free()
		_request_in_progress = false
		return {"code": 0, "data": {}, "transport_error": error}
	var completed: Array = await request.request_completed
	request.queue_free()
	_request_in_progress = false
	var response_code := int(completed[1])
	var response_text := (completed[3] as PackedByteArray).get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(response_text) if not response_text.is_empty() else {}
	return {
		"code": response_code,
		"data": parsed if parsed != null else {},
	}


func _configured_server_url() -> String:
	if OS.has_feature("web"):
		var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		if browser_window != null:
			var origin := str(browser_window.location.origin)
			if is_valid_server_url(origin):
				return origin.trim_suffix("/")
	var configured := str(ProjectSettings.get_setting(
		"application_sync/server_url",
		DEFAULT_SERVER_URL
	))
	return configured.trim_suffix("/") if is_valid_server_url(configured) else DEFAULT_SERVER_URL


func _connect_local_change_signals() -> void:
	var sources := [
		[BudgetManager, "budget_changed"],
		[FixedCostManager, "fixed_costs_changed"],
		[SavingsManager, "savings_goals_changed"],
		[MonthManager, "history_changed"],
		[TransactionManager, "active_transactions_changed"],
		[ShoppingManager, "shopping_changed"],
		[MealPlanManager, "plan_changed"],
		[CustomRecipeManager, "recipes_changed"],
	]
	for source: Array in sources:
		var emitter: Node = source[0]
		var signal_name: StringName = source[1]
		if not emitter.is_connected(signal_name, _on_local_data_changed):
			emitter.connect(signal_name, _on_local_data_changed)


func _reload_runtime_data() -> void:
	BudgetManager.reload_from_storage(false)
	FixedCostManager.reload_from_storage(false)
	SavingsManager.reload_from_storage(false)
	MonthManager.reload_from_storage(false)
	TransactionManager.reload_from_storage(false)
	ShoppingManager.reload_from_storage(false)
	MealPlanManager.reload_from_storage(false)
	CustomRecipeManager.reload_from_storage(false)
	BudgetManager.budget_changed.emit(BudgetManager.get_snapshot())
	FixedCostManager.fixed_costs_changed.emit(
		FixedCostManager.get_costs(),
		FixedCostManager.get_summary()
	)
	SavingsManager.savings_goals_changed.emit(
		SavingsManager.get_goals(),
		SavingsManager.get_summary()
	)
	MonthManager.active_month_changed.emit(
		MonthManager.get_active_month_id(),
		MonthManager.get_active_month_name()
	)
	MonthManager.history_changed.emit()
	TransactionManager.active_transactions_changed.emit(
		TransactionManager.get_active_transactions(),
		TransactionManager.get_active_summary()
	)
	ShoppingManager._emit_current()
	MealPlanManager.plan_changed.emit(MealPlanManager.get_plan())
	CustomRecipeManager.recipes_changed.emit(CustomRecipeManager.get_recipes())


func _on_local_data_changed(_first: Variant = null, _second: Variant = null, _third: Variant = null) -> void:
	if is_logged_in() and not _applying_remote_snapshot:
		_sync_timer.start()


func _on_sync_timer_timeout() -> void:
	if is_logged_in() and not active_group_id.is_empty():
		await push_local_snapshot()


func _on_live_sync_timer_timeout() -> void:
	if (
		not is_logged_in()
		or active_group_id.is_empty()
		or _request_in_progress
		or _applying_remote_snapshot
		or _sync_timer.time_left > 0.0
	):
		return
	var group_result := await refresh_groups()
	if not bool(group_result.get("success", false)):
		return
	for group: Dictionary in groups:
		if str(group.get("id", "")) != active_group_id:
			continue
		if int(group.get("revision", 0)) > current_revision:
			await pull_server_snapshot()
		return


func _sync_status(status: String, message: String) -> void:
	sync_status_changed.emit(status, message)


func _sync_failure(response: Dictionary, fallback: String) -> Dictionary:
	var result := _failure(_response_message(response, fallback))
	_sync_status("error", str(result.message))
	return result


static func _response_message(response: Dictionary, fallback: String) -> String:
	var data: Variant = response.get("data", {})
	if data is Dictionary:
		if not str(data.get("detail", "")).is_empty():
			return str(data.detail)
		if not str(data.get("message", "")).is_empty():
			return str(data.message)
		var errors: Variant = data.get("errors", {})
		if errors is Dictionary:
			for key: String in errors:
				var messages: Variant = errors[key]
				if messages is Array and not messages.is_empty():
					return str(messages[0])
	return fallback


static func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _session_password() -> String:
	var unique_id := OS.get_unique_id().strip_edges()
	return "%s-%s" % [SESSION_SALT, unique_id] if not unique_id.is_empty() else ""


func _save_session(data: Dictionary) -> void:
	var password := _session_password()
	if password.is_empty():
		return
	var file := FileAccess.open_encrypted_with_pass(
		SESSION_FILE,
		FileAccess.WRITE,
		password
	)
	if file != null:
		file.store_string(JSON.stringify({
			"token": _token,
			"expiresUtc": str(data.get("expiresUtc", "")),
		}))


func _load_session() -> Dictionary:
	var password := _session_password()
	if password.is_empty() or not FileAccess.file_exists(SESSION_FILE):
		return {}
	var file := FileAccess.open_encrypted_with_pass(
		SESSION_FILE,
		FileAccess.READ,
		password
	)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _delete_session_file() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_FILE))


func _load_or_create_device_id() -> String:
	var saved := _load_device_state()
	var existing := str(saved.get("device_id", ""))
	if existing.length() >= 8:
		return existing
	var random := Crypto.new().generate_random_bytes(16).hex_encode()
	var device_id := "%s-%s" % ["web" if OS.has_feature("web") else "desktop", random]
	saved.device_id = device_id
	_save_device_state(saved)
	return device_id


func _load_device_state() -> Dictionary:
	if not FileAccess.file_exists(DEVICE_FILE):
		return {}
	var file := FileAccess.open(DEVICE_FILE, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _save_device_state(state: Dictionary = {}) -> void:
	var current := state if not state.is_empty() else _load_device_state()
	current.device_id = _device_id if not _device_id.is_empty() else str(current.get("device_id", ""))
	current.active_group_id = active_group_id
	current.revision = current_revision
	var file := FileAccess.open(DEVICE_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(current, "\t"))
