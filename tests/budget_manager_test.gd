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
	_assert_equal(app.dashboard_body.get_child(0), app.world_view, "Landschaft bleibt mobil als Titelbild erhalten")
	_assert_equal(app.world_view._compact_mode, true, "Landschaft nutzt mobil den aufgeräumten Modus")
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
	_assert_equal(app.dashboard_title.text, "Deine Budgetwelt", "Desktop-Titel bleibt unverändert")

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
