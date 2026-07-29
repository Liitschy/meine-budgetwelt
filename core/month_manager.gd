extends Node

signal active_month_changed(month_id: String, display_name: String)
signal history_changed()

const MonthUtils := preload("res://core/month_utils.gd")
const SCHEMA_VERSION := 1

var _history := {
	"schema_version": SCHEMA_VERSION,
	"active_month": "",
	"months": {},
}
var _applying_month := false


func _ready() -> void:
	var saved := StorageManager.load_month_history()
	if _is_valid_history(saved):
		_history = saved
	else:
		_migrate_current_data()

	BudgetManager.budget_changed.connect(_on_budget_changed)
	FixedCostManager.fixed_costs_changed.connect(_on_fixed_costs_changed)

	var active_id := str(_history.active_month)
	if _history.months.has(active_id):
		_apply_month(active_id)


func get_active_month_id() -> String:
	return str(_history.active_month)


func get_active_month_name() -> String:
	return MonthUtils.display_name(get_active_month_id())


func has_month(month_id: String) -> bool:
	return _history.months.has(month_id)


func get_month_ids() -> Array:
	var ids: Array = _history.months.keys()
	ids.sort()
	return ids


func switch_to_month(month_id: String, opening_balance: float = -1.0) -> bool:
	if month_id == get_active_month_id():
		return true

	_store_current_month()
	if not has_month(month_id):
		_history.months[month_id] = _create_following_month(opening_balance)

	_history.active_month = month_id
	StorageManager.save_month_history(_history)
	_apply_month(month_id)
	active_month_changed.emit(month_id, MonthUtils.display_name(month_id))
	history_changed.emit()
	return true


func _migrate_current_data() -> void:
	var month_id := MonthUtils.current_month_id()
	_history.active_month = month_id
	_history.months = {
		month_id: {
			"budget": BudgetManager.get_data(),
			"fixed_costs": FixedCostManager.get_costs(),
		},
	}
	StorageManager.save_month_history(_history)


func _create_following_month(opening_balance: float) -> Dictionary:
	var budget := BudgetManager.get_data()
	if opening_balance >= 0.0:
		budget.balance = opening_balance

	var costs := FixedCostManager.get_costs()
	for cost: Dictionary in costs:
		cost.paid = false
		cost.paid_amount = 0.0

	return {
		"budget": budget,
		"fixed_costs": costs,
	}


func _apply_month(month_id: String) -> void:
	var month: Dictionary = _history.months[month_id]
	_applying_month = true
	FixedCostManager.replace_costs(month.get("fixed_costs", []))
	BudgetManager.replace_budget(month.get("budget", {}))
	_applying_month = false


func _store_current_month() -> void:
	var active_id := get_active_month_id()
	if active_id.is_empty():
		return
	_history.months[active_id] = {
		"budget": BudgetManager.get_data(),
		"fixed_costs": FixedCostManager.get_costs(),
	}
	StorageManager.save_month_history(_history)


func _on_budget_changed(_snapshot: Dictionary) -> void:
	if not _applying_month:
		_store_current_month()


func _on_fixed_costs_changed(_costs: Array, _summary: Dictionary) -> void:
	if not _applying_month:
		_store_current_month()


func _is_valid_history(value: Dictionary) -> bool:
	return (
		not value.is_empty()
		and value.get("months", null) is Dictionary
		and not str(value.get("active_month", "")).is_empty()
	)
