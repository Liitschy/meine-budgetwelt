extends Node

signal shopping_changed(items: Array, summary: Dictionary, booked: bool)
signal active_week_changed(week: int)

const ShoppingCalculator := preload("res://core/shopping_calculator.gd")

var _months: Dictionary = {}
var _active_week := 1


func _ready() -> void:
	reload_from_storage(false)

	MonthManager.active_month_changed.connect(_on_active_month_changed)


func reload_from_storage(emit_change: bool = true) -> void:
	var saved := StorageManager.load_shopping_data()
	_months = saved.get("months", {}) if saved.get("months", {}) is Dictionary else {}
	if emit_change:
		_emit_current()


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


func _save_and_emit() -> bool:
	var saved := StorageManager.save_shopping_data({
		"schema_version": 1,
		"months": _months,
	})
	_emit_current()
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
