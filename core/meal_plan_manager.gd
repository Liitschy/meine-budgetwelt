extends Node

signal plan_changed(plan: Array)

const SuggestionCatalog := preload("res://core/meal_suggestion_catalog.gd")
var _months: Dictionary = {}


func _ready() -> void:
	reload_from_storage(false)

	MonthManager.active_month_changed.connect(_on_context_changed)
	ShoppingManager.active_week_changed.connect(_on_week_changed)


func reload_from_storage(emit_change: bool = true) -> void:
	var saved := StorageManager.load_meal_plans()
	_months = saved.get("months", {}) if saved.get("months", {}) is Dictionary else {}
	if emit_change:
		plan_changed.emit(get_plan())


func get_plan() -> Array:
	var month_id := MonthManager.get_active_month_id()
	var month: Dictionary = _months.get(month_id, {})
	var plan: Array = month.get(str(ShoppingManager.get_active_week()), [])
	return plan.duplicate(true) if plan.size() == 7 else SuggestionCatalog.generate()


func update_day(
	day_index: int,
	mode: String,
	meal: String,
	recipe_id: String = ""
) -> bool:
	if day_index < 0 or day_index > 6:
		return false
	var plan := get_plan()
	plan[day_index] = {
		"day_index": day_index,
		"mode": mode,
		"meal": meal.strip_edges(),
		"recipe_id": recipe_id,
		"chain_note": "",
	}
	_set_plan(plan)
	return _save_and_emit()


func generate_suggestions() -> bool:
	_set_plan(SuggestionCatalog.generate())
	return _save_and_emit()


func set_confirmed(day_index: int, confirmed: bool) -> bool:
	if day_index < 0 or day_index > 6:
		return false
	var plan := get_plan()
	plan[day_index].confirmed = confirmed
	_set_plan(plan)
	return _save_and_emit()


func mix_unconfirmed() -> bool:
	var seed := int(Time.get_ticks_usec()) + ShoppingManager.get_active_week() * 1009
	_set_plan(SuggestionCatalog.mix_unconfirmed(get_plan(), seed))
	return _save_and_emit()


func _set_plan(plan: Array) -> void:
	var month_id := MonthManager.get_active_month_id()
	var month: Dictionary = _months.get(month_id, {})
	month[str(ShoppingManager.get_active_week())] = plan
	_months[month_id] = month


func _save_and_emit() -> bool:
	var saved := StorageManager.save_meal_plans({
		"schema_version": 2,
		"months": _months,
	})
	plan_changed.emit(get_plan())
	return saved


func _on_context_changed(_month_id: String, _display_name: String) -> void:
	plan_changed.emit(get_plan())


func _on_week_changed(_week: int) -> void:
	plan_changed.emit(get_plan())
