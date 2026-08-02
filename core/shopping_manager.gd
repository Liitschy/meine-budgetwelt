extends Node

signal shopping_changed(items: Array, summary: Dictionary, booked: bool)
signal active_week_changed(week: int)
signal personal_prices_changed(prices: Array)
signal planning_profile_changed(profile: Dictionary)

const ShoppingCalculator := preload("res://core/shopping_calculator.gd")

var _months: Dictionary = {}
var _personal_prices: Array = []
var _planning_profile: Dictionary = {}
var _active_week := 1


func _ready() -> void:
	reload_from_storage(false)

	MonthManager.active_month_changed.connect(_on_active_month_changed)


func reload_from_storage(emit_change: bool = true) -> void:
	var saved := StorageManager.load_shopping_data()
	_months = saved.get("months", {}) if saved.get("months", {}) is Dictionary else {}
	_personal_prices = (
		saved.get("personal_prices", []).duplicate(true)
		if saved.get("personal_prices", []) is Array
		else []
	)
	_planning_profile = (
		saved.get("planning_profile", {}).duplicate(true)
		if saved.get("planning_profile", {}) is Dictionary
		else {}
	)
	if emit_change:
		_emit_current()
		personal_prices_changed.emit(get_personal_prices())
		planning_profile_changed.emit(get_planning_profile())


func get_personal_prices() -> Array:
	return _personal_prices.duplicate(true)


func get_planning_profile() -> Dictionary:
	return _planning_profile.duplicate(true)


func save_planning_profile(profile: Dictionary) -> bool:
	var allowed_keys := [
		"people",
		"servingsPerMeal",
		"safetyBufferCents",
		"maxActiveMinutes",
		"dietaryStyle",
		"planningStyle",
		"allergies",
		"excludedIngredients",
		"preferredIngredients",
		"pantry",
	]
	var clean: Dictionary = {}
	for key: String in allowed_keys:
		if profile.has(key):
			clean[key] = profile[key]
	_planning_profile = clean.duplicate(true)
	var saved := _save_and_emit()
	planning_profile_changed.emit(get_planning_profile())
	return saved


func get_personal_price(price_id: String) -> Dictionary:
	for price: Variant in _personal_prices:
		if price is Dictionary and str(price.get("id", "")) == price_id:
			return (price as Dictionary).duplicate(true)
	return {}


func save_personal_price(
	price_id: String,
	name: String,
	package_quantity: String,
	package_price: float,
	checkout_price: float = -1.0,
	store: String = ""
) -> String:
	var clean_name := name.strip_edges()
	var clean_quantity := package_quantity.strip_edges()
	if clean_name.is_empty() or clean_quantity.is_empty() or package_price < 0.0:
		return ""
	if checkout_price < -0.0001:
		checkout_price = -1.0
	var clean_id := price_id.strip_edges()
	if clean_id.is_empty():
		clean_id = "personal_price_%d" % Time.get_ticks_usec()
	var data := {
		"id": clean_id,
		"name": clean_name,
		"package_quantity": clean_quantity,
		"package_price": package_price,
		"checkout_price": checkout_price,
		"store": store.strip_edges(),
		"updated_unix": int(Time.get_unix_time_from_system()),
	}
	var replaced := false
	for index in _personal_prices.size():
		var current: Variant = _personal_prices[index]
		if current is Dictionary and str(current.get("id", "")) == clean_id:
			_personal_prices[index] = data
			replaced = true
			break
	if not replaced:
		_personal_prices.append(data)
	_save_and_emit(true)
	return clean_id


func remove_personal_price(price_id: String) -> bool:
	for index in _personal_prices.size():
		var current: Variant = _personal_prices[index]
		if current is Dictionary and str(current.get("id", "")) == price_id:
			_personal_prices.remove_at(index)
			return _save_and_emit(true)
	return false


func get_ai_personal_prices(limit: int = 40) -> Array:
	var result: Array = []
	if limit <= 0:
		return result
	for raw_price: Variant in _personal_prices:
		if not raw_price is Dictionary:
			continue
		var price: Dictionary = raw_price
		var selected_price := float(price.get("checkout_price", -1.0))
		if selected_price < 0.0:
			selected_price = float(price.get("package_price", 0.0))
		var name := str(price.get("name", "")).strip_edges()
		var quantity := str(price.get("package_quantity", "")).strip_edges()
		if name.is_empty() or quantity.is_empty() or selected_price < 0.0:
			continue
		result.append({
			"name": name,
			"quantity": quantity,
			"priceCents": roundi(selected_price * 100.0),
		})
		if result.size() >= limit:
			break
	return result


func set_actual_price(item_id: String, actual_price: float) -> bool:
	if is_booked() or actual_price < 0.0:
		return false
	var week_data := _get_week_data()
	var items: Array = week_data.items
	for item: Dictionary in items:
		if str(item.get("id", "")) == item_id:
			item.actual_price = actual_price
			week_data.items = items
			_set_week_data(week_data)
			return _save_and_emit()
	return false


func get_active_week() -> int:
	return _active_week


func set_active_week(week: int) -> void:
	var normalized := clampi(week, 1, 5)
	if normalized == _active_week:
		return
	_active_week = normalized
	active_week_changed.emit(_active_week)
	_emit_current()


func get_items() -> Array:
	return _get_week_data().items.duplicate(true)


func get_summary(weekly_budget: float) -> Dictionary:
	return ShoppingCalculator.summarize(get_items(), weekly_budget)


func is_booked() -> bool:
	return bool(_get_week_data().booked)


func add_item(name: String, quantity: String, estimated_price: float) -> bool:
	if is_booked():
		return false
	var clean_name := name.strip_edges()
	if clean_name.is_empty() or estimated_price < 0.0:
		return false

	var week_data := _get_week_data()
	var items: Array = week_data.items
	items.append({
		"id": "shopping_%d_%d" % [
			int(Time.get_unix_time_from_system()),
			items.size(),
		],
		"name": clean_name,
		"quantity": quantity.strip_edges() if not quantity.strip_edges().is_empty() else "1 Stück",
		"estimated_price": estimated_price,
		"checked": false,
	})
	week_data.items = items
	_set_week_data(week_data)
	return _save_and_emit()


func add_recipe_ingredients(ingredients: Array) -> int:
	if is_booked():
		return 0
	var week_data := _get_week_data()
	var items: Array = week_data.items
	var added := 0
	for ingredient: Dictionary in ingredients:
		var clean_name := str(ingredient.get("name", "")).strip_edges()
		if clean_name.is_empty():
			continue
		var already_present := false
		for item: Dictionary in items:
			if str(item.get("name", "")).to_lower() == clean_name.to_lower():
				already_present = true
				break
		if already_present:
			continue
		items.append({
			"id": "recipe_%d_%d" % [int(Time.get_ticks_usec()), items.size()],
			"name": clean_name,
			"quantity": str(ingredient.get("quantity", "1 Stück")),
			"estimated_price": maxf(float(ingredient.get("estimated_price", 0.0)), 0.0),
			"checked": false,
			"pack_plan": str(ingredient.get("pack_plan", "")),
			"required_quantity": str(ingredient.get("required_quantity", "")),
			"surplus_quantity": str(ingredient.get("surplus_quantity", "")),
		})
		added += 1
	if added > 0:
		week_data.items = items
		_set_week_data(week_data)
		_save_and_emit()
	return added


func replace_weekly_recipe_ingredients(ingredients: Array) -> int:
	if is_booked():
		return 0
	var week_data := _get_week_data()
	var existing: Array = week_data.items
	var kept: Array = []
	var added := 0
	for item: Dictionary in existing:
		var item_id := str(item.get("id", ""))
		if not item_id.begins_with("weekly_recipe_") and not item_id.begins_with("recipe_"):
			kept.append(item)
	for ingredient: Dictionary in ingredients:
		var clean_name := str(ingredient.get("name", "")).strip_edges()
		if clean_name.is_empty():
			continue
		var conflicts_with_manual := false
		for item: Dictionary in kept:
			if str(item.get("name", "")).to_lower() == clean_name.to_lower():
				conflicts_with_manual = true
				break
		if conflicts_with_manual:
			continue
		kept.append({
			"id": "weekly_recipe_%d_%d" % [int(Time.get_ticks_usec()), kept.size()],
			"name": clean_name,
			"quantity": str(ingredient.get("quantity", "nach Bedarf")),
			"estimated_price": maxf(float(ingredient.get("estimated_price", 0.0)), 0.0),
			"checked": false,
			"pack_plan": str(ingredient.get("pack_plan", "")),
			"required_quantity": str(ingredient.get("required_quantity", "")),
			"surplus_quantity": str(ingredient.get("surplus_quantity", "")),
		})
		added += 1
	week_data.items = kept
	_set_week_data(week_data)
	_save_and_emit()
	return added


func set_checked(item_id: String, checked: bool) -> bool:
	if is_booked():
		return false
	var week_data := _get_week_data()
	var items: Array = week_data.items
	for item: Dictionary in items:
		if str(item.id) == item_id:
			item.checked = checked
			week_data.items = items
			_set_week_data(week_data)
			return _save_and_emit()
	return false


func remove_item(item_id: String) -> bool:
	if is_booked():
		return false
	var week_data := _get_week_data()
	var items: Array = week_data.items
	for index in items.size():
		if str(items[index].id) == item_id:
			items.remove_at(index)
			week_data.items = items
			_set_week_data(week_data)
			return _save_and_emit()
	return false


func mark_booked() -> bool:
	var week_data := _get_week_data()
	week_data.booked = true
	_set_week_data(week_data)
	return _save_and_emit()


func _get_week_data() -> Dictionary:
	var month_id := MonthManager.get_active_month_id()
	var month: Dictionary = _months.get(month_id, {})
	var week_key := str(_active_week)
	var data: Dictionary = month.get(week_key, {
		"items": [],
		"booked": false,
	})
	if not data.get("items", null) is Array:
		data.items = []
	return data


func _set_week_data(data: Dictionary) -> void:
	var month_id := MonthManager.get_active_month_id()
	var month: Dictionary = _months.get(month_id, {})
	month[str(_active_week)] = data
	_months[month_id] = month


func _save_and_emit(emit_personal_prices: bool = false) -> bool:
	var saved := StorageManager.save_shopping_data({
		"schema_version": 2,
		"months": _months,
		"personal_prices": _personal_prices,
		"planning_profile": _planning_profile,
	})
	_emit_current()
	if emit_personal_prices:
		personal_prices_changed.emit(get_personal_prices())
	return saved


func _emit_current() -> void:
	var weekly_budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	shopping_changed.emit(
		get_items(),
		get_summary(weekly_budget),
		is_booked()
	)


func _on_active_month_changed(_month_id: String, _display_name: String) -> void:
	_active_week = 1
	active_week_changed.emit(_active_week)
	_emit_current()
