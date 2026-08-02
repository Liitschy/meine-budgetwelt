extends Control


func _ready() -> void:
	var output_path := OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_PATH")
	if output_path.is_empty():
		push_error("Pfad fuer die visuelle Vorschau fehlt.")
		get_tree().quit(1)
		return

	var preview_width := int(OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_WIDTH"))
	var preview_height := int(OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_HEIGHT"))
	if preview_width <= 0:
		preview_width = 390
	if preview_height <= 0:
		preview_height = 844
	var resize_first := OS.get_environment("BUDGETWELT_VISUAL_RESIZE_FIRST") == "1"
	var initial_size := Vector2i(960, 640) if resize_first else Vector2i(preview_width, preview_height)
	get_window().size = initial_size
	get_window().content_scale_size = initial_size
	var app := preload("res://app/Main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	if resize_first:
		get_window().size = Vector2i(preview_width, preview_height)
		get_window().content_scale_size = Vector2i(preview_width, preview_height)
		app._queue_responsive_layout()
		await get_tree().process_frame
		await get_tree().process_frame
	app.login_panel.visible = false
	app.startup_status_panel.visible = false
	var preview_page := OS.get_environment("BUDGETWELT_VISUAL_PAGE")
	if preview_page.is_empty():
		preview_page = "fixed_costs"
	if preview_page == "weekly_planning":
		var catalog_preview := OS.get_environment("BUDGETWELT_VISUAL_CATALOG")
		var weekly_step := int(OS.get_environment("BUDGETWELT_VISUAL_WEEKLY_STEP"))
		if weekly_step < 1 or weekly_step > 3:
			weekly_step = 2
		if OS.get_environment("BUDGETWELT_VISUAL_SHOPPING") == "1":
			ShoppingManager._months = {
				MonthManager.get_active_month_id(): {
					str(ShoppingManager.get_active_week()): {
						"items": [
							{"id": "preview_1", "name": "Saisonales Gemüse", "quantity": "2 kg", "estimated_price": 7.9, "checked": true},
							{"id": "preview_2", "name": "Kartoffeln", "quantity": "2,5 kg", "estimated_price": 3.49, "checked": false},
							{"id": "preview_3", "name": "Rote Linsen", "quantity": "500 g", "estimated_price": 2.19, "checked": false},
						],
						"booked": false,
					},
				},
			}
		if catalog_preview in ["recipes", "prices"]:
			_seed_catalog_preview_data()
			app.weekly_planning_page.show_recipe_price_preview(catalog_preview)
		else:
			AiPlanningManager._draft = _weekly_planning_fixture() if weekly_step > 1 else {}
			app.weekly_planning_page._step = weekly_step
			app.weekly_planning_page._rebuild_content()
	app._show_page(preview_page)
	app._apply_responsive_layout()
	if preview_page == "banking_preview":
		app._show_page("transactions")
		var banking_panel: Variant = app.banking_panel
		banking_panel.set_status({
			"enabled": true,
			"mode": "read-only",
			"automaticRefresh": false,
			"payments": false,
		})
		banking_panel.set_connections([{
			"id": "preview-connection",
			"institutionName": "Musterbank Deutschland",
			"status": "linked",
			"lastRefreshUtc": "2026-08-02T18:42:00Z",
		}])
		banking_panel.set_compact(preview_width <= 640)
		banking_panel.set_data(_banking_preview_fixture())
		banking_panel.visible = true
		banking_panel.move_to_front()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if (
		preview_page == "weekly_planning"
		and OS.get_environment("BUDGETWELT_VISUAL_SCROLL") == "bottom"
	):
		var scroll_bar: VScrollBar = app.weekly_planning_page._scroll.get_v_scroll_bar()
		scroll_bar.value = scroll_bar.max_value
		await get_tree().process_frame
	if (
		preview_page == "banking_preview"
		and OS.get_environment("BUDGETWELT_VISUAL_SCROLL") == "bottom"
	):
		var bank_preview: Variant = app.transactions_page.get_child(
			app.transactions_page.get_child_count() - 1
		)
		var bank_scroll: Variant = bank_preview.get("_scroll")
		if bank_scroll is ScrollContainer:
			var bank_scroll_bar: VScrollBar = bank_scroll.get_v_scroll_bar()
			bank_scroll_bar.value = bank_scroll_bar.max_value
		await get_tree().process_frame
	print(
		"VISUAL_LAYOUT:name=%s:size=%s:compact=%s" % [
			preview_page,
			str(app.size),
			str(app._compact_layout),
		]
	)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.is_empty() or image.save_png(output_path) != OK:
		push_error("Mobile Vorschau konnte nicht gespeichert werden.")
		get_tree().quit(1)
		return
	print("VISUAL_PREVIEW_OK:%dx%d:%s" % [image.get_width(), image.get_height(), output_path])
	get_tree().quit(0)


func _seed_catalog_preview_data() -> void:
	CustomRecipeManager._recipes = [
		{
			"id": "preview_lentils",
			"title": "Cremiger Linseneintopf",
			"mode": "Meal-Prep",
			"servings": 4,
			"active_minutes": 20,
			"favorite": true,
			"estimated_cost": 7.84,
			"ingredients": [
				{"name": "Rote Linsen", "quantity": "500 g", "estimated_price": 2.19, "include_in_shopping": true},
				{"name": "Suppengemüse", "quantity": "1 Bund", "estimated_price": 2.49, "include_in_shopping": true},
			],
			"preparation": "Gemüse anschwitzen, Linsen zugeben und cremig garen.",
			"custom": true,
		},
		{
			"id": "preview_pasta",
			"title": "Ofengemüse mit Pasta",
			"mode": "Normal kochen",
			"servings": 2,
			"active_minutes": 15,
			"favorite": false,
			"estimated_cost": 6.42,
			"ingredients": [
				{"name": "Pasta", "quantity": "500 g", "estimated_price": 1.29, "include_in_shopping": true},
				{"name": "Saisonales Gemüse", "quantity": "1 kg", "estimated_price": 3.99, "include_in_shopping": true},
			],
			"preparation": "Gemüse rösten, Pasta kochen und miteinander vermengen.",
			"custom": true,
		},
		{
			"id": "preview_ai_curry",
			"title": "Kichererbsen-Curry",
			"mode": "Schnellgericht",
			"servings": 2,
			"active_minutes": 18,
			"favorite": true,
			"estimated_cost": 5.76,
			"generated_by_ai": true,
			"ingredients": [
				{"name": "Kichererbsen", "quantity": "2 Dosen", "estimated_price": 1.78, "include_in_shopping": true},
				{"name": "Kokosmilch", "quantity": "1 Dose", "estimated_price": 1.49, "include_in_shopping": true},
			],
			"preparation": "Zutaten zusammen aufkochen und abschmecken.",
			"custom": true,
		},
	]
	ShoppingManager._personal_prices = [
		{"id": "preview_price_1", "name": "Rote Linsen", "package_quantity": "500 g", "package_price": 2.29, "checkout_price": 2.19, "store": "Lidl"},
		{"id": "preview_price_2", "name": "Haferflocken", "package_quantity": "500 g", "package_price": 0.99, "checkout_price": 1.05, "store": "Edeka"},
		{"id": "preview_price_3", "name": "Saisonales Gemüse", "package_quantity": "1 kg", "package_price": 3.99, "checkout_price": -1.0, "store": "Wochenmarkt"},
	]


func _banking_preview_fixture() -> Dictionary:
	return {
		"connectionId": "preview-connection",
		"institutionName": "Musterbank Deutschland",
		"balances": [{"accountReference": "•••• 4821", "currency": "EUR", "amount": 1428.48}],
		"transactions": [
			{"importId": "preview-1", "accountReference": "•••• 4821", "status": "booked", "kind": "expense", "amount": 64.95, "currency": "EUR", "bookingDate": "01.08.2026", "description": "EDEKA Markt", "alreadyImported": false},
			{"importId": "preview-2", "accountReference": "•••• 4821", "status": "booked", "kind": "income", "amount": 125.00, "currency": "EUR", "bookingDate": "31.07.2026", "description": "Erstattung Energieversorger", "alreadyImported": false},
			{"importId": "preview-3", "accountReference": "•••• 4821", "status": "booked", "kind": "expense", "amount": 49.00, "currency": "EUR", "bookingDate": "30.07.2026", "description": "Tankstelle", "alreadyImported": true},
			{"importId": "preview-4", "accountReference": "•••• 4821", "status": "pending", "kind": "expense", "amount": 12.80, "currency": "EUR", "bookingDate": "02.08.2026", "description": "Kartenzahlung vorgemerkt", "alreadyImported": false},
		],
	}


func _weekly_planning_fixture() -> Dictionary:
	var meals := [
		"Linsen-Bolognese",
		"Kartoffel-Gemüse-Blech",
		"Cremige Restesuppe",
		"Reis-Gemüse-Pfanne",
		"Ofengemüse mit Dip",
		"Bohnen-Chili",
		"Chili-Wraps aus Resten",
	]
	var days: Array = []
	for index in range(7):
		days.append({
			"dayIndex": index,
			"meal": meals[index],
			"mode": "Reste" if index in [2, 6] else "Normal kochen",
			"recipeId": "wochenrezept",
			"servings": 2,
			"estimatedCostCents": [620, 580, 360, 540, 650, 710, 430][index],
			"mealPrepNote": "Gemüse und Sauce vorbereiten" if index == 0 else "",
			"leftoverNote": "Vorbereitete Reste vollständig nutzen" if index in [2, 6] else "",
		})
	return {
		"currency": "EUR",
		"priceBasis": "Vorsichtige Schätzpreise; Kassenpreise können abweichen.",
		"weeklyBudgetCents": 7000,
		"safetyBufferCents": 700,
		"planningTargetCents": 6300,
		"estimatedCostCents": 3890,
		"remainingCents": 2410,
		"days": days,
		"recipes": [{
			"id": "wochenrezept",
			"title": "Alltagstaugliches Wochenrezept",
			"mode": "Meal-Prep",
			"servings": 2,
			"activeMinutes": 25,
			"estimatedCostCents": 620,
			"preparation": "Zutaten vorbereiten, gemeinsam garen und portionsweise verwenden.",
			"ingredients": [{
				"name": "Saisonales Gemüse",
				"quantity": "2 kg",
				"estimatedPriceCents": 790,
				"includeInShopping": true,
				"usesPantry": false,
				"allergens": [],
			}],
		}],
		"shoppingItems": [
			{"name": "Saisonales Gemüse", "quantity": "2 kg", "estimatedPriceCents": 790},
			{"name": "Kartoffeln", "quantity": "2,5 kg", "estimatedPriceCents": 349},
			{"name": "Rote Linsen", "quantity": "500 g", "estimatedPriceCents": 219},
			{"name": "Reis", "quantity": "1 kg", "estimatedPriceCents": 249},
			{"name": "Kidneybohnen", "quantity": "3 Dosen", "estimatedPriceCents": 267},
			{"name": "Tomaten", "quantity": "4 Dosen", "estimatedPriceCents": 316},
			{"name": "Wraps und Ergänzungen", "quantity": "1 Woche", "estimatedPriceCents": 1700},
		],
		"warnings": ["Preise vor dem Einkauf kurz mit dem aktuellen Ladenpreis abgleichen."],
	}
