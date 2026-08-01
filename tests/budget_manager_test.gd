extends Node

const BudgetCalculator := preload("res://core/budget_calculator.gd")
const FixedCostCalculator := preload("res://core/fixed_cost_calculator.gd")
const FixedCostManagerScript := preload("res://core/fixed_cost_manager.gd")
const MonthUtils := preload("res://core/month_utils.gd")
const MainScene := preload("res://app/Main.tscn")
const SavingsCalculator := preload("res://core/savings_calculator.gd")
const SavingsManagerScript := preload("res://core/savings_manager.gd")
const TransactionCalculator := preload("res://core/transaction_calculator.gd")
const ShoppingCalculator := preload("res://core/shopping_calculator.gd")
const MealSuggestionCatalog := preload("res://core/meal_suggestion_catalog.gd")
const RecipeCatalog := preload("res://core/recipe_catalog.gd")
const CustomRecipeManagerScript := preload("res://core/custom_recipe_manager.gd")
const QuantityCalculator := preload("res://core/quantity_calculator.gd")
const WeeklyNeedCalculator := preload("res://core/weekly_need_calculator.gd")
const PackPlanner := preload("res://core/pack_planner.gd")
const StorageManagerScript := preload("res://core/storage_manager.gd")
const SyncManagerScript := preload("res://core/sync_manager.gd")
const UpdateManagerScript := preload("res://core/update_manager.gd")

var _failed := false


func _ready() -> void:
	var snapshot := BudgetCalculator.calculate({
		"balance": 2000.0,
		"fixed_costs_total": 1200.0,
		"fixed_costs_paid": 700.0,
		"savings_goal": 150.0,
		"weekly_grocery_budget": 70.0,
	})
	_assert_equal(snapshot.available_now, 1300.0, "Aktuell verfügbar")
	_assert_equal(snapshot.current_balance, 1300.0, "Laufender Kontostand berücksichtigt bezahlte Fixkosten")
	_assert_equal(snapshot.freely_available, 800.0, "Nach allen Fixkosten frei")
	_assert_equal(snapshot.weekly_free_budget, 200.0, "Frei verfügbares Wochenbudget")
	_assert_equal(snapshot.after_savings, 650.0, "Nach Sparziel verfügbar")
	_assert_equal(snapshot.fixed_costs_open, 500.0, "Offene Fixkosten")

	var fixed_summary := FixedCostCalculator.summarize([
		{"amount": 700.0, "paid": true},
		{"amount": 120.0, "paid": false},
		{"amount": 40.0, "paid": false},
		{"amount": 340.0, "paid": false},
	])
	_assert_equal(fixed_summary.total, 1200.0, "Fixkosten gesamt")
	_assert_equal(fixed_summary.paid, 700.0, "Bezahlte Fixkosten")
	_assert_equal(fixed_summary.open, 500.0, "Unbezahlte Fixkosten")
	var interval_summary := FixedCostCalculator.summarize([
		{"amount": 100.0, "due_this_month": true, "paid_amount": 0.0},
		{"amount": 400.0, "due_this_month": false, "paid_amount": 0.0},
	])
	_assert_equal(interval_summary.total, 100.0, "Nicht fällige Fixkosten belasten den Monat nicht")
	_assert_equal(
		FixedCostManagerScript.is_due_in_month("quarterly", 2, "2026-05"),
		true,
		"Quartalskosten sind alle drei Monate fällig"
	)
	_assert_equal(
		FixedCostManagerScript.is_due_in_month("quarterly", 2, "2026-04"),
		false,
		"Quartalskosten bleiben in Zwischenmonaten unberücksichtigt"
	)
	_assert_equal(
		FixedCostManagerScript.is_due_in_month("yearly", 11, "2026-11"),
		true,
		"Jährliche Fixkosten sind im gewählten Monat fällig"
	)
	var partial_fixed_summary := FixedCostCalculator.summarize([
		{"amount": 120.0, "paid": false, "paid_amount": 104.0},
	])
	_assert_equal(partial_fixed_summary.paid, 104.0, "Teilzahlung berücksichtigt")
	_assert_equal(partial_fixed_summary.open, 16.0, "Restbetrag nach Teilzahlung")
	_assert_equal(MonthUtils.add_months("2026-12", 1), "2027-01", "Jahreswechsel vorwärts")
	_assert_equal(MonthUtils.add_months("2026-01", -1), "2025-12", "Jahreswechsel rückwärts")
	_assert_equal(MonthUtils.display_name("2026-07"), "Juli 2026", "Deutscher Monatsname")
	var savings_summary := SavingsCalculator.summarize([
		{
			"target_amount": 3000.0,
			"saved_amount": 2010.0,
			"monthly_contribution": 150.0,
		},
		{
			"target_amount": 1000.0,
			"saved_amount": 250.0,
			"monthly_contribution": 50.0,
		},
	])
	_assert_equal(savings_summary.target_total, 4000.0, "Sparziele gesamt")
	_assert_equal(savings_summary.saved_total, 2260.0, "Gespart gesamt")
	_assert_equal(savings_summary.remaining_total, 1740.0, "Offene Sparziele")
	_assert_equal(savings_summary.monthly_total, 200.0, "Monatliche Sparraten")
	var transaction_summary := TransactionCalculator.summarize([
		{"kind": "income", "amount": 200.0},
		{"kind": "expense", "amount": 100.0},
		{"kind": "saving", "amount": 50.0},
	])
	_assert_equal(transaction_summary.income, 200.0, "Zusätzliche Einnahmen")
	_assert_equal(transaction_summary.expenses, 100.0, "Variable Ausgaben")
	_assert_equal(transaction_summary.savings, 50.0, "Sparzahlungen")
	var weekly_summary := TransactionCalculator.summarize([
		{"kind": "expense", "category": "Wochenbudget", "amount": 35.0, "day": 3},
		{"kind": "expense", "category": "Wochenbudget", "amount": 20.0, "day": 10},
	], 0)
	_assert_equal(weekly_summary.weekly_expenses, 35.0, "Ausgaben der aktuellen Budgetwoche")
	var credited_week := TransactionCalculator.summarize([
		{"kind": "weekly_credit", "category": "Wochenbudget", "amount": 50.0, "day": 3},
		{"kind": "weekly_credit", "category": "Wochenbudget", "amount": 25.0, "day": 10},
	], 0)
	_assert_equal(credited_week.weekly_credit, 50.0, "Zusatzbudget gilt nur für die gewählte Woche")
	_assert_equal(credited_week.weekly_credit_total, 75.0, "Alle Wochenaufladungen erhöhen den Kontobetrag")
	var credited_budget := BudgetCalculator.calculate({
		"balance": 1000.0,
		"weekly_credit": 50.0,
		"weekly_credit_total": 50.0,
	})
	_assert_equal(credited_budget.effective_balance, 1050.0, "Aufladung erhöht den verfügbaren Kontobetrag")
	_assert_equal(credited_budget.weekly_free_budget, 300.0, "Aufladung wird nur der aktiven Woche zugerechnet")

	var booking_snapshot := BudgetCalculator.calculate({
		"balance": 2000.0,
		"additional_income": 200.0,
		"fixed_costs_total": 1200.0,
		"fixed_costs_paid": 700.0,
		"variable_expenses": 100.0,
		"savings_goal": 150.0,
		"savings_payments": 50.0,
	})
	_assert_equal(booking_snapshot.available_now, 1350.0, "Verfügbar nach Buchungen")
	_assert_equal(booking_snapshot.current_balance, 1350.0, "Laufender Kontostand berücksichtigt Buchungen")
	_assert_equal(booking_snapshot.freely_available, 850.0, "Frei nach Buchungen")
	_assert_equal(booking_snapshot.after_savings, 750.0, "Sparzahlung nicht doppelt abgezogen")
	var shopping_summary := ShoppingCalculator.summarize([
		{"estimated_price": 12.5, "checked": true},
		{"estimated_price": 20.0, "checked": false},
	], 70.0)
	_assert_equal(shopping_summary.planned, 32.5, "Geplanter Wocheneinkauf")
	_assert_equal(shopping_summary.checked, 12.5, "Abgehakter Einkaufswert")
	_assert_equal(shopping_summary.remaining, 37.5, "Verbleibendes Wochenbudget")
	_assert_equal(shopping_summary.over_budget, false, "Wochenbudget eingehalten")
	var meal_plan := MealSuggestionCatalog.generate()
	_assert_equal(meal_plan.size(), 7, "Sieben Tagesgerichte")
	_assert_equal(meal_plan[0].recipe_id, "linseneintopf_kette", "Rezeptkette startet mit Eintopf")
	_assert_equal(meal_plan[1].mode, "Reste", "Vorbereitete Kartoffeln weiterverwendet")
	_assert_equal(meal_plan[3].recipe_id, "fried_rice_kette", "Reis am Folgetag weiterverwendet")
	_assert_equal(meal_plan[6].mode, "Reste", "Restetag am Wochenende eingeplant")
	_assert_equal(str(meal_plan[0].chain_note).is_empty(), false, "Vorkochhinweis vorhanden")
	_assert_equal(meal_plan[0].has("shift"), false, "Keine Schichtdaten im Speiseplan")
	_assert_equal(meal_plan[0].has("recipe_id"), true, "Vorschlag enthält Rezeptverknüpfung")
	meal_plan[0].confirmed = true
	meal_plan[1].confirmed = true
	var mixed_plan := MealSuggestionCatalog.mix_unconfirmed(meal_plan, 12345)
	_assert_equal(mixed_plan[0].recipe_id, meal_plan[0].recipe_id, "Bestätigter Montag bleibt erhalten")
	_assert_equal(mixed_plan[1].recipe_id, meal_plan[1].recipe_id, "Bestätigter Dienstag bleibt erhalten")
	_assert_equal(mixed_plan[2].recipe_id != meal_plan[2].recipe_id, true, "Unbestätigter Tag wird gemischt")
	_assert_equal(mixed_plan.size(), 7, "Mischen behält sieben Tage")
	var recipe := RecipeCatalog.get_recipe(str(meal_plan[0].recipe_id))
	_assert_equal(recipe.is_empty(), false, "Verknüpftes Rezept vorhanden")
	_assert_equal(recipe.ingredients.size() > 0, true, "Rezept enthält Einkaufzutaten")
	_assert_equal(str(recipe.preparation).is_empty(), false, "Rezept enthält Zubereitung")
	_assert_equal(recipe.servings, 2, "Sparrezepte gelten für zwei Personen")
	_assert_equal(int(recipe.active_minutes) <= 15, true, "Kurze aktive Kochzeit")
	var day_two_recipe := RecipeCatalog.get_recipe("kartoffel_moehren_kette")
	_assert_equal(
		bool(day_two_recipe.ingredients[0].include_in_shopping),
		false,
		"Vorbereitete Kartoffeln nicht doppelt eingekauft"
	)
	_assert_equal(
		RecipeCatalog.ingredients_for("kartoffel_moehren_kette").size(),
		1,
		"Einzelübernahme enthält nur neu benötigte Eier"
	)
	var parsed_ingredients := CustomRecipeManagerScript.parse_ingredients(
		"Kartoffeln | 2,5 kg | 3,49\nEier | 10 Stück | 2.49"
	)
	_assert_equal(parsed_ingredients.size(), 2, "Eigene Zutatenzeilen werden gelesen")
	_assert_equal(parsed_ingredients[0].estimated_price, 3.49, "Deutsches Preiskomma unterstützt")
	_assert_equal(
		CustomRecipeManagerScript.parse_ingredients("unvollständig").size(),
		0,
		"Ungültige Zutatenzeilen werden ignoriert"
	)
	_assert_equal(
		QuantityCalculator.subtract("2 × 500 ml", "0,5 l").missing_text,
		"500 ml",
		"Mehrfachpackung und Liter verrechnet"
	)
	_assert_equal(
		QuantityCalculator.subtract("10 Stück", "4 Stk").missing_text,
		"6 Stück",
		"Stückzahlen verrechnet"
	)
	_assert_equal(
		QuantityCalculator.subtract("1 Dose", "1 Dose").convertible,
		false,
		"Unbekannte Einheiten nicht künstlich verrechnet"
	)
	var weekly_need := WeeklyNeedCalculator.aggregate([
		{"name": "Reis", "quantity": "500 g", "estimated_price": 1.0},
		{"name": " reis ", "quantity": "1 kg", "estimated_price": 2.0},
		{"name": "Tomaten", "quantity": "1 Dose", "estimated_price": 0.8},
		{"name": "Tomaten", "quantity": "1 Dose", "estimated_price": 0.8},
	])
	_assert_equal(weekly_need.size(), 2, "Gleiche Wochenzutaten zusammengeführt")
	_assert_equal(weekly_need[0].quantity, "1,5 kg", "Wochenmenge über Einheiten addiert")
	_assert_equal(weekly_need[0].estimated_price, 3.0, "Wochenpreise addiert")
	_assert_equal(weekly_need[1].quantity, "2 × 1 Dose", "Gleiche unbekannte Packungen gebündelt")
	var rice_pack_plan := PackPlanner.plan_ingredient({
		"name": "Reis",
		"quantity": "1,1 kg",
		"estimated_price": 4.0,
	})
	_assert_equal(rice_pack_plan.quantity, "1,5 kg", "Ausreichende Reis-Kaufmenge gewählt")
	_assert_equal(rice_pack_plan.pack_plan, "1 × 500 g, 1 × 1 kg", "Günstige Reiskombination gewählt")
	_assert_equal(
		is_equal_approx(float(rice_pack_plan.estimated_price), 3.18),
		true,
		"Eigenmarken-Packpreis berechnet"
	)
	_assert_equal(rice_pack_plan.surplus_quantity, "400 g", "Packungsüberschuss berechnet")
	var potato_pack_plan := PackPlanner.plan_ingredient({
		"name": "Kartoffeln",
		"quantity": "3 kg",
		"estimated_price": 8.0,
	})
	_assert_equal(potato_pack_plan.pack_plan, "1 × 5 kg", "Günstigere Großpackung gewählt")
	_assert_equal(
		PackPlanner.plan_ingredient({
			"name": "Saisonales Gemüse",
			"quantity": "500 g",
			"estimated_price": 1.99,
		}).estimated_price,
		1.99,
		"Unbekanntes Produkt behält Schätzpreis"
	)
	var contains_normal_meal := false
	for day: Dictionary in meal_plan:
		if str(day.mode) == "Normal kochen":
			contains_normal_meal = true
	_assert_equal(contains_normal_meal, true, "Normale Kochgerichte enthalten")
	_test_empty_savings_goals_remain_empty()
	_test_backup_root_validation()
	_test_storage_backup_roundtrip()
	_test_sync_snapshot_roundtrip()
	_test_sync_server_url_validation()
	_test_update_validation()
	await _test_responsive_layout()

	if _failed:
		get_tree().quit(1)
	else:
		print("BudgetManager: alle Tests bestanden.")
		get_tree().quit(0)


func _test_empty_savings_goals_remain_empty() -> void:
	var source := SavingsManagerScript._initial_goals_source([], true)
	_assert_equal(source.size(), 0, "Gelöschte Sparziele bleiben nach Neustart leer")
	var defaults := SavingsManagerScript._initial_goals_source([], false)
	_assert_equal(defaults.size(), 1, "Beispielziel erscheint nur beim ersten Start")


func _test_backup_root_validation() -> void:
	_assert_equal(
		StorageManagerScript.is_valid_backup_root("budget_data.json", {}),
		true,
		"Budget-Sicherung akzeptiert ein Objekt"
	)
	_assert_equal(
		StorageManagerScript.is_valid_backup_root("budget_data.json", []),
		false,
		"Budget-Sicherung lehnt einen falschen Wurzeltyp ab"
	)
	_assert_equal(
		StorageManagerScript.is_valid_backup_root("savings_goals.json", []),
		true,
		"Leere Sparzielliste bleibt als gültige Sicherung erhalten"
	)
	_assert_equal(
		StorageManagerScript.is_valid_backup_root("savings_goals.json", {}),
		false,
		"Sparziel-Sicherung lehnt einen falschen Wurzeltyp ab"
	)


func _test_storage_backup_roundtrip() -> void:
	var test_budget := {
		"balance": 4321.09,
		"weekly_grocery_budget": 88.0,
		"test_marker": "backup-roundtrip",
	}
	_assert_equal(
		StorageManager.save_budget_data(test_budget),
		true,
		"Testbudget für Sicherung gespeichert"
	)
	_assert_equal(
		StorageManager.save_savings_goals([]),
		true,
		"Leere Sparzielliste für Sicherung gespeichert"
	)

	var first_backup := StorageManager.create_backup()
	var second_backup := StorageManager.create_backup()
	_assert_equal(first_backup.get("success", false), true, "Erste Datensicherung erstellt")
	_assert_equal(second_backup.get("success", false), true, "Zweite Datensicherung erstellt")
	_assert_equal(
		str(first_backup.get("path", "")) != str(second_backup.get("path", "")),
		true,
		"Sicherungen derselben Sekunde erhalten getrennte Ordner"
	)

	StorageManager.save_budget_data({"balance": 1.0, "test_marker": "changed"})
	StorageManager.save_savings_goals([{
		"id": "temporary",
		"name": "Nur im Test",
		"target_amount": 10.0,
		"saved_amount": 1.0,
		"monthly_contribution": 1.0,
	}])
	var restore_result := StorageManager.restore_backup(str(first_backup.get("path", "")))
	_assert_equal(restore_result.get("success", false), true, "Datensicherung wiederhergestellt")
	_assert_equal(
		StorageManager.load_budget_data().get("test_marker", ""),
		"backup-roundtrip",
		"Budgetdaten stammen nach Wiederherstellung aus der Sicherung"
	)
	_assert_equal(
		StorageManager.load_savings_goals().size(),
		0,
		"Leere Sparzielliste bleibt nach Wiederherstellung leer"
	)
	_assert_equal(
		not str(restore_result.get("safety_backup_path", "")).is_empty(),
		true,
		"Vor Wiederherstellung wurde eine Sicherheitssicherung angelegt"
	)

	var invalid_directory := "user://backups/invalid-root-type"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(invalid_directory))
	var invalid_file := FileAccess.open(
		"%s/budget_data.json" % invalid_directory,
		FileAccess.WRITE
	)
	_assert_equal(invalid_file != null, true, "Ungültige Testsicherung angelegt")
	if invalid_file != null:
		invalid_file.store_string("[]")
		invalid_file.close()
	var invalid_restore := StorageManager.restore_backup(invalid_directory)
	_assert_equal(
		invalid_restore.get("success", true),
		false,
		"Wiederherstellung mit falschem JSON-Wurzeltyp wird abgelehnt"
	)


func _test_sync_snapshot_roundtrip() -> void:
	var snapshot := StorageManager.export_sync_snapshot()
	_assert_equal(
		StorageManagerScript.is_valid_sync_snapshot(snapshot),
		true,
		"Vollständiger lokaler Datenstand ist synchronisierbar"
	)
	var incomplete := snapshot.duplicate(true)
	incomplete.files.erase("shopping.json")
	_assert_equal(
		StorageManagerScript.is_valid_sync_snapshot(incomplete),
		false,
		"Unvollständiger Server-Datenstand wird abgelehnt"
	)
	var wrong_root := snapshot.duplicate(true)
	wrong_root.files["transactions.json"] = []
	_assert_equal(
		StorageManagerScript.is_valid_sync_snapshot(wrong_root),
		false,
		"Server-Datendatei mit falschem Wurzeltyp wird abgelehnt"
	)

	var imported := snapshot.duplicate(true)
	imported.files["budget_data.json"] = {
		"balance": 4321.09,
		"test_marker": "sync-roundtrip",
	}
	var result := StorageManager.import_sync_snapshot(imported)
	_assert_equal(result.get("success", false), true, "Server-Datenstand importiert")
	_assert_equal(
		StorageManager.load_budget_data().get("test_marker", ""),
		"sync-roundtrip",
		"Importierter Datenstand liegt lokal vor"
	)
	_assert_equal(
		not str(result.get("safety_backup_path", "")).is_empty(),
		true,
		"Synchronisation legt vorher eine Sicherheitssicherung an"
	)


func _test_sync_server_url_validation() -> void:
	_assert_equal(
		SyncManagerScript.is_valid_server_url("https://budget.example.de"),
		true,
		"HTTPS-Serveradresse wird akzeptiert"
	)
	_assert_equal(
		SyncManagerScript.is_valid_server_url("http://127.0.0.1:48732"),
		true,
		"Lokaler Testserver darf HTTP verwenden"
	)
	_assert_equal(
		SyncManagerScript.is_valid_server_url("http://budget.example.de"),
		false,
		"Entfernter Server ohne HTTPS wird abgelehnt"
	)
	_assert_equal(
		SyncManagerScript.is_valid_server_url("https://budget.example.de/fremder-pfad"),
		false,
		"Serveradresse mit unerwartetem Pfad wird abgelehnt"
	)


func _test_update_validation() -> void:
	var version := "0.40.0"
	var download_url := (
		"https://github.com/unique1986/meine-budgetwelt/releases/download/"
		+ "v0.40.0/Meine-Budgetwelt-Setup-0.40.0.exe"
	)
	var sha256_url := "%s.sha256" % download_url.trim_suffix(".exe")
	var manifest := UpdateManagerScript.validate_manifest({
		"version": version,
		"download_url": download_url,
		"sha256_url": sha256_url,
	})
	_assert_equal(manifest.get("valid", false), true, "Offizielles Update-Manifest akzeptiert")
	_assert_equal(
		UpdateManagerScript.is_valid_release_urls(
			version,
			download_url.replace("unique1986", "fremdes-konto"),
			sha256_url
		),
		false,
		"Installer eines fremden Repositorys wird abgelehnt"
	)
	_assert_equal(
		UpdateManagerScript.validate_manifest({
			"version": version,
			"download_url": download_url,
		}).get("valid", true),
		false,
		"Manifest ohne SHA-256-Adresse wird abgelehnt"
	)
	var expected_hash := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	_assert_equal(
		UpdateManagerScript.extract_sha256(
			"%s  Meine-Budgetwelt-Setup-0.40.0.exe\n" % expected_hash
		),
		expected_hash,
		"SHA-256-Dateiformat wird gelesen"
	)
	_assert_equal(
		UpdateManagerScript.extract_sha256("nicht-eine-pruefsumme"),
		"",
		"Ungültige SHA-256-Prüfsumme wird abgelehnt"
	)
	var hash_test_path := "user://update-hash-test.bin"
	var hash_test_file := FileAccess.open(hash_test_path, FileAccess.WRITE)
	_assert_equal(hash_test_file != null, true, "Testdatei für SHA-256-Prüfung angelegt")
	if hash_test_file != null:
		hash_test_file.store_buffer("budgetwelt-update-test".to_utf8_buffer())
		hash_test_file.close()
	_assert_equal(
		UpdateManagerScript.file_matches_sha256(
			hash_test_path,
			"9de8a61f85214bd604fde02d5cc4882dcab41bf26120714015bb153c9ba2f589"
		),
		true,
		"Heruntergeladene Datei besteht die passende SHA-256-Prüfung"
	)
	_assert_equal(
		UpdateManagerScript.file_matches_sha256(
			hash_test_path,
			"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		),
		false,
		"Datei mit abweichender SHA-256-Prüfsumme wird abgelehnt"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(hash_test_path))
	_assert_equal(
		UpdateManagerScript.is_newer_version("0.40.0", "0.39.2"),
		true,
		"Neuere Update-Version wird erkannt"
	)
	_assert_equal(
		UpdateManagerScript.is_newer_version("0.39.2-beta", "0.39.2"),
		false,
		"Ungültige Versionsnummer wird nicht als Update akzeptiert"
	)
	var example_local_app_data := "C:/Users/Test/AppData/Local"
	_assert_equal(
		UpdateManagerScript.is_expected_installed_executable(
			"C:/Users/Test/AppData/Local/Programs/Meine Budgetwelt/Meine-Budgetwelt.exe",
			example_local_app_data
		),
		true,
		"Automatisches Update erkennt die regulär installierte Windows-App"
	)
	_assert_equal(
		UpdateManagerScript.is_expected_installed_executable(
			"C:/Portable/Meine-Budgetwelt.exe",
			example_local_app_data
		),
		false,
		"Portable App wird nicht unbeaufsichtigt überschrieben"
	)
	var automatic_script := UpdateManagerScript.AUTOMATIC_UPDATE_SCRIPT_CONTENTS
	_assert_equal(
		automatic_script.contains("-ArgumentList @('/S')"),
		true,
		"Automatischer Updater startet das verifizierte Setup still"
	)
	_assert_equal(
		automatic_script.contains("Get-Process -Id $ParentProcessId"),
		true,
		"Automatischer Updater wartet auf das Ende der laufenden App"
	)
	_assert_equal(
		automatic_script.contains("Start-Process -FilePath $ApplicationPath"),
		true,
		"Automatischer Updater startet die App nach dem Setup erneut"
	)


func _test_responsive_layout() -> void:
	var app := MainScene.instantiate()
	add_child(app)
	await get_tree().process_frame

	_assert_equal(
		app._should_use_compact_layout(Vector2(1179, 2556), true),
		true,
		"iPhone Retina im Hochformat nutzt trotz hoher Pixelbreite das mobile Layout"
	)
	_assert_equal(
		app._should_use_compact_layout(Vector2(2556, 1179), true),
		false,
		"Web-Landschaft mit ausreichender Breite darf das Desktoplayout nutzen"
	)

	app.size = Vector2(390, 844)
	app._apply_responsive_layout()
	await get_tree().process_frame
	_assert_equal(app._compact_layout, true, "Kompaktes Layout bei Mobilbreite")
	_assert_equal(app.sidebar_panel.visible, false, "Seitenleiste mobil ausgeblendet")
	_assert_equal(app.mobile_navigation.visible, true, "Mobile Navigation eingeblendet")
	_assert_equal(app.desktop_backdrop.visible, false, "Landschaftshintergrund ist ausschließlich für Windows aktiv")
	_assert_equal(
		app.app_shell.get_child(app.app_shell.get_child_count() - 1),
		app.mobile_navigation,
		"Mobile Navigation sitzt am unteren Rand"
	)
	_assert_equal(app.dashboard_body.vertical, true, "Budgetinhalt mobil gestapelt")
	_assert_equal(
		app.dashboard_body.get_child(0),
		app.mobile_dashboard_metrics,
		"Die beiden großen Budgetkarten stehen mobil über der Landschaft"
	)
	_assert_equal(
		app.dashboard_body.get_child(1),
		app.world_view,
		"Landschaft bleibt mobil als zentrales Hauptmotiv erhalten"
	)
	_assert_equal(app.summary_panel.visible, false, "Kleine Desktop-Kennzahlenliste ist mobil verborgen")
	_assert_equal(app.mobile_dashboard_actions.visible, true, "Mobile Aktionskarten sind sichtbar")
	_assert_equal(app.world_view._compact_mode, true, "Landschaft nutzt mobil den aufgeräumten Modus")
	_assert_equal(
		app.startup_status_card.custom_minimum_size.x <= 366.0,
		true,
		"Start-/Updatebildschirm bleibt mit Seitenabstand in der Handybreite"
	)
	_assert_equal(app.dashboard_page.size.x <= 390.0, true, "Dashboard bleibt vollständig in der Handybreite")
	_assert_equal(app.summary_panel.size.x <= 390.0, true, "Finanzkarten werden rechts nicht abgeschnitten")
	_assert_equal(app.fixed_summary_row.vertical, false, "Fixkostensummen mobil nebeneinander")
	_assert_equal(app.savings_summary_row.vertical, false, "Sparziele mobil nebeneinander")
	_assert_equal(app.transaction_summary_row.vertical, false, "Buchungssumme mobil kompakt")
	app._show_page("fixed_costs")
	_assert_equal(app.mobile_navigation.visible, true, "Mobile Navigation bleibt auf Unterseiten sichtbar")
	_assert_equal(app.fixed_list_header.visible, false, "Desktop-Tabellenkopf ist mobil verborgen")
	app._show_page("dashboard")
	app.size = Vector2(1440, 900)
	app._apply_responsive_layout()
	_assert_equal(app._compact_layout, false, "Desktoplayout bei großer Breite")
	_assert_equal(app.sidebar_panel.visible, true, "Seitenleiste am Desktop sichtbar")
	_assert_equal(app.desktop_backdrop.visible, true, "Landschaft verbindet die Windows-Unterseiten optisch")
	_assert_equal(app.mobile_navigation.visible, false, "Mobile Navigation am Desktop verborgen")
	_assert_equal(app.dashboard_body.vertical, false, "Budgetinhalt am Desktop nebeneinander")
	_assert_equal(app.dashboard_body.get_child(0), app.world_view, "Landschaft steht am Desktop wieder links")
	_assert_equal(
		app.dashboard_title.text.begins_with("Guten "),
		true,
		"Desktop-Titel verwendet eine tageszeitabhängige Begrüßung"
	)

	var amount_input: SpinBox = app._create_savings_money_input()
	app.add_child(amount_input)
	var amount_line_edit := amount_input.get_line_edit()
	amount_line_edit.text = "0"
	app._select_amount_text(amount_line_edit)
	await get_tree().process_frame
	_assert_equal(amount_line_edit.has_selection(), true, "Geldbetrag beim Fokus markiert")
	_assert_equal(
		amount_line_edit.get_selected_text(),
		"0",
		"Vorhandene Null wird vollständig ausgewählt"
	)
	app._normalize_amount_text("15,50", amount_line_edit, amount_input)
	_assert_equal(amount_input.value, 15.5, "Komma-Betrag wird als Dezimalzahl übernommen")
	_assert_equal(amount_input.step, 0.01, "Geldfelder erlauben Cent-Beträge")
	var weekly_entries: Array = app._filter_weekly_transactions([
		{"kind": "expense", "category": "Wochenbudget", "amount": 14.5},
		{"kind": "expense", "category": "Freizeit", "amount": 8.0},
		{"kind": "expense", "category": "Wochenbudget", "amount": 20.0},
		{"kind": "income", "category": "Wochenbudget", "amount": 100.0},
	])
	weekly_entries = app._filter_weekly_transactions([
		{"kind": "expense", "category": "Wochenbudget", "amount": 14.5},
		{"kind": "weekly_credit", "category": "Wochenbudget", "amount": 50.0},
	])
	_assert_equal(weekly_entries.size(), 2, "Wochenbudget-Filter zeigt Ausgaben und Aufladungen")
	app.queue_free()


func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failed = true
		push_error("%s: erwartet %s, erhalten %s" % [label, expected, actual])
