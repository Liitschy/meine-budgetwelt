extends Node

signal banking_status_changed(status: Dictionary)
signal bank_connections_changed(connections: Array)
signal bank_preview_changed(preview: Dictionary)
signal banking_message_changed(kind: String, message: String)

var _status: Dictionary = {
	"enabled": false,
	"provider": "GoCardless Bank Account Data",
	"mode": "read-only",
	"automaticRefresh": false,
	"payments": false,
}
var _connections: Array = []
var _preview: Dictionary = {}
var _request_in_progress := false


func get_status() -> Dictionary:
	return _status.duplicate(true)


func get_connections() -> Array:
	return _connections.duplicate(true)


func get_preview() -> Dictionary:
	return _preview.duplicate(true)


func is_request_in_progress() -> bool:
	return _request_in_progress


func reload_status() -> Dictionary:
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.request_banking_status()
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	var data: Variant = result.get("data", {})
	if not data is Dictionary:
		return _report_failure(_failure("Der Bankstatus des Servers ist ungültig."))
	_status = normalize_status(data)
	banking_status_changed.emit(get_status())
	return {"success": true, "status": get_status()}


func reload_connections() -> Dictionary:
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.request_bank_connections()
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	var data: Variant = result.get("data", [])
	if not data is Array:
		return _report_failure(_failure("Die Bankverbindungen des Servers sind ungültig."))
	_connections = (data as Array).duplicate(true)
	bank_connections_changed.emit(get_connections())
	return {"success": true, "connections": get_connections()}


func load_institutions(country: String = "DE") -> Dictionary:
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.request_bank_institutions(country)
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	var data: Variant = result.get("data", [])
	if not data is Array:
		return _report_failure(_failure("Die Bankenliste des Servers ist ungültig."))
	return {"success": true, "institutions": (data as Array).duplicate(true)}


func prepare_connection(institution_id: String) -> Dictionary:
	if institution_id.strip_edges().is_empty():
		return _failure("Bitte eine Bank auswählen.")
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.create_bank_connection(institution_id)
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	var data: Variant = result.get("data", {})
	if not data is Dictionary:
		return _report_failure(_failure("Die vorbereitete Bankverbindung ist ungültig."))
	var authorization_url := str(data.get("authorizationUrl", "")).strip_edges()
	if not is_safe_authorization_url(authorization_url):
		return _report_failure(_failure("Die Freigabe-Adresse der Bank ist ungültig."))
	banking_message_changed.emit(
		"ready",
		"Die Bankfreigabe ist vorbereitet und wird erst nach deiner Bestätigung geöffnet."
	)
	return {
		"success": true,
		"authorization_url": authorization_url,
		"connection": data.get("connection", {}),
	}


func open_authorization(authorization_url: String) -> Dictionary:
	if not is_safe_authorization_url(authorization_url):
		return _failure("Die Freigabe-Adresse der Bank ist ungültig.")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"window.location.assign(%s);" % JSON.stringify(authorization_url),
			true
		)
		return {"success": true, "message": "Weiterleitung zur Bank gestartet."}
	var error := OS.shell_open(authorization_url)
	if error != OK:
		return _failure("Die Bankfreigabe konnte nicht im Browser geöffnet werden.")
	return {"success": true, "message": "Bankfreigabe im Browser geöffnet."}


func refresh_connection(connection_id: String) -> Dictionary:
	if connection_id.strip_edges().is_empty():
		return _failure("Keine Bankverbindung ausgewählt.")
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.refresh_bank_connection(
		connection_id,
		TransactionManager.get_bank_import_ids()
	)
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	var data: Variant = result.get("data", {})
	if not data is Dictionary:
		return _report_failure(_failure("Die Bankvorschau des Servers ist ungültig."))
	_preview = normalize_preview(data)
	bank_preview_changed.emit(get_preview())
	banking_message_changed.emit(
		"ready",
		"Bankdaten wurden nur lesend geladen. Es wurde noch nichts übernommen."
	)
	return {"success": true, "preview": get_preview()}


func import_transactions(import_ids: Array[String]) -> Dictionary:
	var selected := select_importable_transactions(_preview, import_ids)
	if selected.is_empty():
		return _failure("Bitte mindestens eine neue, gebuchte EUR-Buchung auswählen.")
	var result := TransactionManager.import_bank_transactions(selected)
	if not bool(result.get("success", false)):
		return _report_failure(_failure("Die ausgewählten Buchungen konnten nicht gespeichert werden."))
	_mark_imported(import_ids)
	bank_preview_changed.emit(get_preview())
	banking_message_changed.emit(
		"success",
		"%d Bankbuchung(en) wurden übernommen." % int(result.get("imported", 0))
	)
	return result


func adopt_balance(account_reference: String) -> Dictionary:
	for raw_balance: Variant in _preview.get("balances", []):
		if not raw_balance is Dictionary:
			continue
		var balance: Dictionary = raw_balance
		if (
			str(balance.get("accountReference", "")) == account_reference
			and str(balance.get("currency", "")).to_upper() == "EUR"
		):
			var amount := float(balance.get("amount", -1.0))
			if amount < 0.0:
				return _failure("Ein negativer Kontostand wird nicht automatisch übernommen.")
			if not BudgetManager.update_budget({"balance": amount}):
				return _failure("Der Kontostand konnte nicht gespeichert werden.")
			return {"success": true, "balance": amount}
	return _failure("Für dieses Konto liegt kein EUR-Kontostand vor.")


func disconnect_connection(connection_id: String) -> Dictionary:
	if connection_id.strip_edges().is_empty():
		return _failure("Keine Bankverbindung ausgewählt.")
	if _request_in_progress:
		return _failure("Eine Bankanfrage läuft bereits.")
	_request_in_progress = true
	var result := await SyncManager.disconnect_bank_connection(connection_id)
	_request_in_progress = false
	if not bool(result.get("success", false)):
		return _report_failure(result)
	_connections = _connections.filter(func(item: Variant) -> bool:
		return not item is Dictionary or str(item.get("id", "")) != connection_id
	)
	if str(_preview.get("connectionId", "")) == connection_id:
		_preview.clear()
	bank_connections_changed.emit(get_connections())
	bank_preview_changed.emit(get_preview())
	return {"success": true, "message": "Bankverbindung getrennt."}


static func normalize_status(data: Dictionary) -> Dictionary:
	return {
		"enabled": bool(data.get("enabled", false)),
		"provider": str(data.get("provider", "GoCardless Bank Account Data")),
		"mode": "read-only",
		"automaticRefresh": false,
		"payments": false,
	}


static func normalize_preview(data: Dictionary) -> Dictionary:
	var transactions: Array = []
	for raw_item: Variant in data.get("transactions", []):
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		transactions.append({
			"importId": str(item.get("importId", "")),
			"accountReference": str(item.get("accountReference", "")),
			"status": str(item.get("status", "")).to_lower(),
			"kind": str(item.get("kind", "")).to_lower(),
			"amount": absf(float(item.get("amount", 0.0))),
			"currency": str(item.get("currency", "")).to_upper(),
			"bookingDate": str(item.get("bookingDate", "")),
			"description": str(item.get("description", "")).strip_edges(),
			"alreadyImported": bool(item.get("alreadyImported", false)),
		})
	return {
		"connectionId": str(data.get("connectionId", "")),
		"institutionName": str(data.get("institutionName", "")),
		"refreshedUtc": str(data.get("refreshedUtc", "")),
		"balances": (data.get("balances", []) as Array).duplicate(true)
			if data.get("balances", []) is Array else [],
		"transactions": transactions,
		"duplicateCount": int(data.get("duplicateCount", 0)),
	}


static func select_importable_transactions(
	preview: Dictionary,
	import_ids: Array[String]
) -> Array:
	var selected_ids: Dictionary = {}
	for import_id: String in import_ids:
		selected_ids[import_id] = true
	var selected: Array = []
	for raw_item: Variant in preview.get("transactions", []):
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var import_id := str(item.get("importId", ""))
		if (
			selected_ids.has(import_id)
			and not bool(item.get("alreadyImported", false))
			and str(item.get("status", "")).to_lower() == "booked"
			and str(item.get("currency", "")).to_upper() == "EUR"
			and str(item.get("kind", "")).to_lower() in ["income", "expense"]
		):
			selected.append(item.duplicate(true))
	return selected


static func is_safe_authorization_url(value: String) -> bool:
	return value.begins_with("https://") and value.length() <= 2048


func _mark_imported(import_ids: Array[String]) -> void:
	var selected: Dictionary = {}
	for import_id: String in import_ids:
		selected[import_id] = true
	var transactions: Array = _preview.get("transactions", [])
	for index in transactions.size():
		if transactions[index] is Dictionary and selected.has(str(
			transactions[index].get("importId", "")
		)):
			transactions[index]["alreadyImported"] = true
	_preview["transactions"] = transactions


func _report_failure(result: Dictionary) -> Dictionary:
	banking_message_changed.emit(
		"error",
		str(result.get("message", "Die Bankanfrage ist fehlgeschlagen."))
	)
	return result


static func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
