extends Node

signal draft_changed(draft: Dictionary)
signal planning_status_changed(status: String, message: String)

var _draft: Dictionary = {}
var _request_in_progress := false


func get_draft() -> Dictionary:
	return _draft.duplicate(true)


func has_draft() -> bool:
	return not _draft.is_empty()


func is_request_in_progress() -> bool:
	return _request_in_progress


func clear_draft() -> void:
	_draft.clear()
	draft_changed.emit({})


func request_draft(planning_data: Dictionary) -> Dictionary:
	if _request_in_progress:
		return _failure("Eine Wochenplanung wird bereits erstellt.")
	var input_error := validate_planning_input(planning_data)
	if not input_error.is_empty():
		return _failure(input_error)

	_request_in_progress = true
	planning_status_changed.emit(
		"planning",
		"Die KI erstellt Rezepte, Speiseplan und Einkaufsliste …"
	)
	var result := await SyncManager.request_weekly_plan(planning_data)
	_request_in_progress = false
	if not bool(result.get("success", false)):
		var message := str(result.get("message", "Die Planung ist fehlgeschlagen."))
		planning_status_changed.emit("error", message)
		return result

	var candidate: Variant = result.get("draft", {})
	if not candidate is Dictionary or not is_valid_draft(candidate):
		var invalid_message := "Der Server hat keinen vollständigen Wochenplan geliefert."
		planning_status_changed.emit("error", invalid_message)
		return _failure(invalid_message)

	_draft = (candidate as Dictionary).duplicate(true)
	draft_changed.emit(get_draft())
	planning_status_changed.emit("ready", "Der geprüfte KI-Entwurf ist bereit.")
	return {
		"success": true,
		"draft": get_draft(),
		"message": "Der geprüfte KI-Entwurf ist bereit.",
	}


func apply_draft() -> Dictionary:
	if not is_valid_draft(_draft):
		return _failure("Es liegt kein vollständiger KI-Entwurf vor.")
	if ShoppingManager.is_booked():
		return _failure(
			"Der Einkauf dieser Woche ist bereits verbucht und kann nicht ersetzt werden."
		)

	planning_status_changed.emit("saving", "Der Wochenplan wird sicher übernommen …")
	var snapshot := StorageManager.export_sync_snapshot()
	var prepared := build_snapshot_with_draft(
		snapshot,
		_draft,
		MonthManager.get_active_month_id(),
		ShoppingManager.get_active_week()
	)
	if not bool(prepared.get("success", false)):
		var prepare_message := str(prepared.get(
			"message",
			"Der KI-Entwurf konnte nicht vorbereitet werden."
		))
		planning_status_changed.emit("error", prepare_message)
		return _failure(prepare_message)

	var imported := StorageManager.import_sync_snapshot(prepared.snapshot)
	if not bool(imported.get("success", false)):
		var import_message := str(imported.get(
			"message",
			"Der Wochenplan konnte nicht gespeichert werden."
		))
		planning_status_changed.emit("error", import_message)
		return _failure(import_message)

	CustomRecipeManager.reload_from_storage(false)
	MealPlanManager.reload_from_storage(false)
	ShoppingManager.reload_from_storage(false)
	CustomRecipeManager.recipes_changed.emit(CustomRecipeManager.get_recipes())
	MealPlanManager.plan_changed.emit(MealPlanManager.get_plan())
	ShoppingManager._emit_current()
	_draft.clear()
	draft_changed.emit({})
	planning_status_changed.emit(
		"applied",
		"Rezepte, Speiseplan und Einkaufsliste wurden übernommen."
	)
	return {
		"success": true,
		"backup_path": str(imported.get("safety_backup_path", "")),
		"message": "Rezepte, Speiseplan und Einkaufsliste wurden übernommen.",
	}


static func validate_planning_input(data: Dictionary) -> String:
	var budget := int(data.get("weeklyBudgetCents", 0))
	var buffer := int(data.get("safetyBufferCents", -1))
	if budget < 100:
		return "Das Wochenbudget muss mindestens 1,00 € betragen."
	if buffer < 0 or buffer >= budget:
		return "Der Sicherheitspuffer muss kleiner als das Wochenbudget sein."
	if int(data.get("people", 0)) < 1:
		return "Bitte mindestens eine Person angeben."
	if int(data.get("servingsPerMeal", 0)) < 1:
		return "Bitte mindestens eine Portion pro Gericht angeben."
	if int(data.get("maxActiveMinutes", 0)) < 5:
		return "Die aktive Kochzeit muss mindestens fünf Minuten betragen."
	if str(data.get("dietaryStyle", "")).strip_edges().is_empty():
		return "Bitte eine Ernährungsweise auswählen."
	if str(data.get("planningStyle", "")).strip_edges().is_empty():
		return "Bitte eine Planungsart auswählen."
	return ""


static func is_valid_draft(draft: Variant) -> bool:
	if not draft is Dictionary:
		return false
	if str(draft.get("currency", "")) != "EUR":
		return false
	var weekly_budget := int(draft.get("weeklyBudgetCents", 0))
	var safety_buffer := int(draft.get("safetyBufferCents", -1))
	var planning_target := int(draft.get("planningTargetCents", -1))
	var estimated_cost := int(draft.get("estimatedCostCents", -1))
	var remaining := int(draft.get("remainingCents", -1))
	if (
		weekly_budget < 100
		or safety_buffer < 0
		or safety_buffer >= weekly_budget
		or planning_target != weekly_budget - safety_buffer
		or estimated_cost < 0
		or estimated_cost > planning_target
		or remaining != planning_target - estimated_cost
	):
		return false
	var days: Variant = draft.get("days", null)
	var recipes: Variant = draft.get("recipes", null)
	var shopping_items: Variant = draft.get("shoppingItems", null)
	var warnings: Variant = draft.get("warnings", null)
	if not days is Array or days.size() != 7:
		return false
	if not recipes is Array or recipes.is_empty() or recipes.size() > 14:
		return false
	if not shopping_items is Array or shopping_items.is_empty():
		return false
	if not warnings is Array:
		return false
	var recipe_ids: Dictionary = {}
	for recipe: Variant in recipes:
		if not recipe is Dictionary:
			return false
		var recipe_id := str(recipe.get("id", "")).strip_edges()
		var ingredients: Variant = recipe.get("ingredients", null)
		if (
			recipe_id.is_empty()
			or recipe_ids.has(recipe_id)
			or str(recipe.get("title", "")).strip_edges().is_empty()
			or str(recipe.get("preparation", "")).strip_edges().is_empty()
			or not ingredients is Array
			or ingredients.is_empty()
		):
			return false
		recipe_ids[recipe_id] = true
		for ingredient: Variant in ingredients:
			if (
				not ingredient is Dictionary
				or str(ingredient.get("name", "")).strip_edges().is_empty()
				or str(ingredient.get("quantity", "")).strip_edges().is_empty()
				or not ingredient.get("allergens", null) is Array
			):
				return false
	var seen_days: Dictionary = {}
	var day_total := 0
	for day: Variant in days:
		if not day is Dictionary:
			return false
		var day_index := int(day.get("dayIndex", -1))
		var recipe_id := str(day.get("recipeId", ""))
		if (
			day_index < 0
			or day_index > 6
			or seen_days.has(day_index)
			or not recipe_ids.has(recipe_id)
			or str(day.get("meal", "")).strip_edges().is_empty()
		):
			return false
		seen_days[day_index] = true
		day_total += int(day.get("estimatedCostCents", -1))
	if day_total != estimated_cost:
		return false
	var shopping_total := 0
	for item: Variant in shopping_items:
		if (
			not item is Dictionary
			or str(item.get("name", "")).strip_edges().is_empty()
			or str(item.get("quantity", "")).strip_edges().is_empty()
			or not item.get("recipeIds", null) is Array
			or not item.get("allergens", null) is Array
			or int(item.get("estimatedPriceCents", -1)) < 0
		):
			return false
		for recipe_id: Variant in item.get("recipeIds", []):
			if not recipe_ids.has(str(recipe_id)):
				return false
		shopping_total += int(item.get("estimatedPriceCents", 0))
	if shopping_total != estimated_cost:
		return false
	return true


static func build_snapshot_with_draft(
	snapshot: Dictionary,
	draft: Dictionary,
	month_id: String,
	week: int
) -> Dictionary:
	if not StorageManager.is_valid_sync_snapshot(snapshot):
		return _failure_static("Der aktuelle Datenstand ist unvollständig.")
	if not is_valid_draft(draft):
		return _failure_static("Der KI-Entwurf ist unvollständig.")
	if month_id.strip_edges().is_empty() or week < 1 or week > 5:
		return _failure_static("Der ausgewählte Planungszeitraum ist ungültig.")

	var result := snapshot.duplicate(true)
	var files: Dictionary = result.files
	var recipes: Array = files["custom_recipes.json"]
	var id_map: Dictionary = {}
	var generated_recipes: Array = []
	var manual_recipe_ids: Dictionary = {}
	var new_recipe_ids: Dictionary = {}
	for existing_recipe: Variant in recipes:
		if existing_recipe is Dictionary and not bool(existing_recipe.get(
			"generated_by_ai",
			false
		)):
			manual_recipe_ids[str(existing_recipe.get("id", ""))] = true
	for raw_recipe: Variant in draft.recipes:
		if not raw_recipe is Dictionary:
			return _failure_static("Ein KI-Rezept ist ungültig.")
		var source_id := str(raw_recipe.get("id", "")).strip_edges()
		var base_recipe_id := _ai_recipe_id(source_id)
		if source_id.is_empty() or base_recipe_id == "ai_recipe":
			return _failure_static("Eine KI-Rezept-ID fehlt.")
		var recipe_id := base_recipe_id
		var suffix := 2
		while manual_recipe_ids.has(recipe_id) or new_recipe_ids.has(recipe_id):
			recipe_id = "%s_%d" % [base_recipe_id, suffix]
			suffix += 1
		new_recipe_ids[recipe_id] = true
		id_map[source_id] = recipe_id
		var converted_ingredients: Array = []
		for raw_ingredient: Variant in raw_recipe.get("ingredients", []):
			if not raw_ingredient is Dictionary:
				return _failure_static("Eine KI-Zutat ist ungültig.")
			converted_ingredients.append({
				"name": str(raw_ingredient.get("name", "")).strip_edges(),
				"quantity": str(raw_ingredient.get("quantity", "")).strip_edges(),
				"estimated_price": _cents_to_euros(
					int(raw_ingredient.get("estimatedPriceCents", 0))
				),
				"include_in_shopping": bool(raw_ingredient.get(
					"includeInShopping",
					true
				)),
				"uses_pantry": bool(raw_ingredient.get("usesPantry", false)),
				"allergens": (raw_ingredient.get("allergens", []) as Array).duplicate(true),
			})
		generated_recipes.append({
			"id": recipe_id,
			"title": str(raw_recipe.get("title", "")).strip_edges(),
			"mode": str(raw_recipe.get("mode", "Normal kochen")),
			"servings": int(raw_recipe.get("servings", 1)),
			"active_minutes": int(raw_recipe.get("activeMinutes", 20)),
			"estimated_cost": _cents_to_euros(
				int(raw_recipe.get("estimatedCostCents", 0))
			),
			"ingredients": converted_ingredients,
			"preparation": str(raw_recipe.get("preparation", "")).strip_edges(),
			"custom": true,
			"generated_by_ai": true,
			"ai_source_id": source_id,
		})

	var preserved_recipes: Array = []
	var generated_ids: Dictionary = {}
	for generated: Dictionary in generated_recipes:
		generated_ids[str(generated.id)] = true
	for existing: Variant in recipes:
		if not existing is Dictionary:
			continue
		var existing_id := str(existing.get("id", ""))
		if generated_ids.has(existing_id) and bool(existing.get("generated_by_ai", false)):
			continue
		preserved_recipes.append(existing)
	preserved_recipes.append_array(generated_recipes)
	files["custom_recipes.json"] = preserved_recipes

	var converted_days: Array = []
	for day_index in range(7):
		var raw_day := _find_day(draft.days, day_index)
		if raw_day.is_empty():
			return _failure_static("Ein Wochentag fehlt im KI-Entwurf.")
		var source_recipe_id := str(raw_day.get("recipeId", ""))
		if not id_map.has(source_recipe_id):
			return _failure_static("Ein Wochentag verweist auf ein unbekanntes Rezept.")
		var notes: Array[String] = []
		for note_key in ["mealPrepNote", "leftoverNote"]:
			var note := str(raw_day.get(note_key, "")).strip_edges()
			if not note.is_empty():
				notes.append(note)
		converted_days.append({
			"day_index": day_index,
			"mode": str(raw_day.get("mode", "Normal kochen")),
			"meal": str(raw_day.get("meal", "")).strip_edges(),
			"recipe_id": str(id_map[source_recipe_id]),
			"chain_note": " · ".join(notes),
			"confirmed": true,
			"estimated_cost": _cents_to_euros(
				int(raw_day.get("estimatedCostCents", 0))
			),
		})

	var meal_data: Dictionary = files["meal_plans.json"]
	var meal_months: Dictionary = meal_data.get("months", {})
	var meal_month: Dictionary = meal_months.get(month_id, {})
	meal_month[str(week)] = converted_days
	meal_months[month_id] = meal_month
	meal_data["schema_version"] = maxi(int(meal_data.get("schema_version", 0)), 2)
	meal_data["months"] = meal_months
	files["meal_plans.json"] = meal_data

	var shopping_data: Dictionary = files["shopping.json"]
	var shopping_months: Dictionary = shopping_data.get("months", {})
	var shopping_month: Dictionary = shopping_months.get(month_id, {})
	var shopping_week: Dictionary = shopping_month.get(str(week), {
		"items": [],
		"booked": false,
	})
	if bool(shopping_week.get("booked", false)):
		return _failure_static("Der Einkauf dieser Woche ist bereits verbucht.")
	var shopping_items: Array = []
	for existing_item: Variant in shopping_week.get("items", []):
		if not existing_item is Dictionary:
			continue
		var existing_id := str(existing_item.get("id", ""))
		if (
			not existing_id.begins_with("ai_weekly_")
			and not existing_id.begins_with("weekly_recipe_")
			and not existing_id.begins_with("recipe_")
		):
			shopping_items.append(existing_item)
	var item_index := 0
	for raw_item: Variant in draft.shoppingItems:
		if not raw_item is Dictionary:
			return _failure_static("Ein KI-Einkaufsartikel ist ungültig.")
		var mapped_recipe_ids: Array[String] = []
		for source_recipe_id: Variant in raw_item.get("recipeIds", []):
			var source_key := str(source_recipe_id)
			if id_map.has(source_key):
				mapped_recipe_ids.append(str(id_map[source_key]))
		shopping_items.append({
			"id": "ai_weekly_%s_%d_%d" % [_safe_id(month_id), week, item_index],
			"name": str(raw_item.get("name", "")).strip_edges(),
			"quantity": str(raw_item.get("quantity", "")).strip_edges(),
			"estimated_price": _cents_to_euros(
				int(raw_item.get("estimatedPriceCents", 0))
			),
			"checked": false,
			"recipe_ids": mapped_recipe_ids,
			"allergens": (raw_item.get("allergens", []) as Array).duplicate(true),
			"ai_generated": true,
		})
		item_index += 1
	shopping_week["items"] = shopping_items
	shopping_week["booked"] = false
	shopping_month[str(week)] = shopping_week
	shopping_months[month_id] = shopping_month
	shopping_data["schema_version"] = maxi(int(shopping_data.get("schema_version", 0)), 1)
	shopping_data["months"] = shopping_months
	files["shopping.json"] = shopping_data

	result.files = files
	return {"success": true, "snapshot": result, "id_map": id_map}


static func _find_day(days: Array, day_index: int) -> Dictionary:
	for raw_day: Variant in days:
		if raw_day is Dictionary and int(raw_day.get("dayIndex", -1)) == day_index:
			return raw_day
	return {}


static func _ai_recipe_id(source_id: String) -> String:
	var clean := _safe_id(source_id)
	return "ai_%s" % (clean if not clean.is_empty() else "recipe")


static func _safe_id(value: String) -> String:
	var result := ""
	for character in value.to_lower():
		if character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
			result += character
		elif not result.ends_with("_"):
			result += "_"
	return result.trim_prefix("_").trim_suffix("_")


static func _cents_to_euros(cents: int) -> float:
	return maxf(float(cents) / 100.0, 0.0)


static func _failure_static(message: String) -> Dictionary:
	return {"success": false, "message": message}


func _failure(message: String) -> Dictionary:
	return _failure_static(message)
