extends Node

signal budget_changed(snapshot: Dictionary)

const BudgetCalculator := preload("res://core/budget_calculator.gd")

const DEFAULT_DATA := {
	"balance": 2000.0,
	"fixed_costs_total": 1200.0,
	"fixed_costs_paid": 700.0,
	"savings_goal": 150.0,
	"weekly_grocery_budget": 70.0,
	"additional_income": 0.0,
	"variable_expenses": 0.0,
	"weekly_expenses": 0.0,
	"savings_payments": 0.0,
}

var _data: Dictionary = DEFAULT_DATA.duplicate(true)


func _ready() -> void:
	var saved := StorageManager.load_budget_data()
	for key: String in DEFAULT_DATA:
		if saved.has(key):
			_data[key] = maxf(float(saved[key]), 0.0)


func update_budget(values: Dictionary) -> bool:
	for key: String in DEFAULT_DATA:
		if values.has(key):
			_data[key] = maxf(float(values[key]), 0.0)

	var saved := StorageManager.save_budget_data(_data)
	budget_changed.emit(get_snapshot())
	return saved


func replace_budget(values: Dictionary) -> bool:
	_data = DEFAULT_DATA.duplicate(true)
	return update_budget(values)


func get_data() -> Dictionary:
	return _data.duplicate(true)


func get_snapshot() -> Dictionary:
	return BudgetCalculator.calculate(_data)
