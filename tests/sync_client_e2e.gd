extends Node


func _ready() -> void:
	var server_url := OS.get_environment("BUDGETWELT_TEST_SERVER_URL")
	var email := OS.get_environment("BUDGETWELT_TEST_EMAIL")
	var password := OS.get_environment("BUDGETWELT_TEST_PASSWORD")
	var phase := OS.get_environment("BUDGETWELT_TEST_PHASE")
	if not SyncManager.configure_server_url(server_url):
		_fail("Testserver-Adresse ist ungültig.")
		return

	var login_result := await SyncManager.login(email, password, false)
	if not bool(login_result.get("success", false)):
		_fail("Anmeldung fehlgeschlagen: %s" % str(login_result.get("message", "")))
		return

	match phase:
		"seed":
			if not BudgetManager.update_budget({"balance": 1357.24}):
				_fail("Erster Client konnte lokale Daten nicht speichern.")
				return
			var pushed := await SyncManager.push_local_snapshot()
			if not bool(pushed.get("success", false)):
				_fail("Erster Client konnte nicht hochladen.")
				return
		"receive-change":
			if not _expect_balance(1357.24):
				return
			if not BudgetManager.update_budget({"balance": 2468.42}):
				_fail("Zweiter Client konnte lokale Daten nicht speichern.")
				return
			var pushed := await SyncManager.push_local_snapshot()
			if not bool(pushed.get("success", false)):
				_fail("Zweiter Client konnte nicht hochladen.")
				return
		"wait-live-change":
			if not _expect_balance(1357.24):
				return
			var ready_file_path := OS.get_environment("BUDGETWELT_TEST_READY_FILE")
			var ready_file := FileAccess.open(ready_file_path, FileAccess.WRITE)
			if ready_file == null:
				_fail("Bereitschaftsdatei fuer den Live-Abgleich konnte nicht erstellt werden.")
				return
			ready_file.store_string("ready")
			ready_file.close()
			var deadline := Time.get_ticks_msec() + 20_000
			while Time.get_ticks_msec() < deadline:
				if _balance_matches(2468.42):
					break
				await get_tree().create_timer(0.25).timeout
			if not _expect_balance(2468.42):
				return
		"verify-return":
			if not _expect_balance(2468.42):
				return
		_:
			_fail("Unbekannte Testphase.")
			return

	print("SYNC_CLIENT_E2E_OK:%s:revision=%d" % [phase, SyncManager.current_revision])
	get_tree().quit(0)


func _expect_balance(expected: float) -> bool:
	if _balance_matches(expected):
		return true
	_fail("Erwarteter Kontostand %.2f wurde nicht empfangen oder nicht laufend aktualisiert." % expected)
	return false


func _balance_matches(expected: float) -> bool:
	var data := StorageManager.load_budget_data()
	if not is_equal_approx(float(data.get("balance", -1.0)), expected):
		return false
	if not is_equal_approx(float(BudgetManager.get_data().get("balance", -1.0)), expected):
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
