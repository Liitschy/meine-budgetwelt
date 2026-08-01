extends Node

signal savings_goals_changed(goals: Array, summary: Dictionary)

const SavingsCalculator := preload("res://core/savings_calculator.gd")

const DEFAULT_GOALS := [
	{
		"id": "vacation",
		"name": "Urlaub",
		"target_amount": 3000.0,
		"saved_amount": 2010.0,
		"monthly_contribution": 150.0,
	},
]

var _goals: Array = []


func _ready() -> void:
	reload_from_storage(false)


func reload_from_storage(emit_change: bool = true) -> void:
	var has_saved_goals := StorageManager.has_savings_goals_data()
	var saved := StorageManager.load_savings_goals()
	_goals = _sanitize_goals(_initial_goals_source(saved, has_saved_goals))
	if not has_saved_goals:
		StorageManager.save_savings_goals(_goals)
	if emit_change:
		savings_goals_changed.emit(get_goals(), get_summary())


func get_goals() -> Array:
	return _goals.duplicate(true)


func get_summary() -> Dictionary:
	return SavingsCalculator.summarize(_goals)


func add_goal(
	name: String,
	target_amount: float,
	saved_amount: float,
	monthly_contribution: float
) -> bool:
	var clean_name := name.strip_edges()
	if clean_name.is_empty() or target_amount <= 0.0:
		return false

	_goals.append({
		"id": "goal_%d_%d" % [int(Time.get_unix_time_from_system()), _goals.size()],
		"name": clean_name,
		"target_amount": target_amount,
		"saved_amount": clampf(saved_amount, 0.0, target_amount),
		"monthly_contribution": maxf(monthly_contribution, 0.0),
	})
	return _save_and_emit()


func add_deposit(goal_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return false
	for goal: Dictionary in _goals:
		if str(goal.id) == goal_id:
			goal.saved_amount = minf(
				float(goal.saved_amount) + amount,
				float(goal.target_amount)
			)
			return _save_and_emit()
	return false


func remove_goal(goal_id: String) -> bool:
	for index in _goals.size():
		if str(_goals[index].id) == goal_id:
			_goals.remove_at(index)
			return _save_and_emit()
	return false


func _save_and_emit() -> bool:
	var saved := StorageManager.save_savings_goals(_goals)
	savings_goals_changed.emit(get_goals(), get_summary())
	return saved


static func _initial_goals_source(saved: Array, has_saved_goals: bool) -> Array:
	return saved if has_saved_goals else DEFAULT_GOALS


func _sanitize_goals(source: Array) -> Array:
	var clean: Array = []
	for index in source.size():
		var item: Variant = source[index]
		if not item is Dictionary:
			continue
		var name := str(item.get("name", "")).strip_edges()
		var target := maxf(float(item.get("target_amount", 0.0)), 0.0)
		if name.is_empty() or target <= 0.0:
			continue
		clean.append({
			"id": str(item.get("id", "goal_imported_%d" % index)),
			"name": name,
			"target_amount": target,
			"saved_amount": clampf(float(item.get("saved_amount", 0.0)), 0.0, target),
			"monthly_contribution": maxf(
				float(item.get("monthly_contribution", 0.0)),
				0.0
			),
		})
	return clean
