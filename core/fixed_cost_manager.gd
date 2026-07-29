extends Node

signal fixed_costs_changed(costs: Array, summary: Dictionary)

const FixedCostCalculator := preload("res://core/fixed_cost_calculator.gd")

const DEFAULT_COSTS := [
	{
		"id": "rent",
		"name": "Miete",
		"category": "Wohnen",
		"amount": 700.0,
		"due_day": 1,
		"paid": true,
		"paid_amount": 700.0,
	},
	{
		"id": "electricity",
		"name": "Strom",
		"category": "Energie",
		"amount": 120.0,
		"due_day": 5,
		"paid": false,
		"paid_amount": 0.0,
	},
	{
		"id": "internet",
		"name": "Internet",
		"category": "Kommunikation",
		"amount": 40.0,
		"due_day": 10,
		"paid": false,
		"paid_amount": 0.0,
	},
	{
		"id": "insurance",
		"name": "Versicherungen",
		"category": "Versicherung",
		"amount": 340.0,
		"due_day": 15,
		"paid": false,
		"paid_amount": 0.0,
	},
]

var _costs: Array = []


func _ready() -> void:
	var saved := StorageManager.load_fixed_costs()
	_costs = _sanitize_costs(saved if not saved.is_empty() else DEFAULT_COSTS)
	if saved.is_empty():
		StorageManager.save_fixed_costs(_costs)


func get_costs() -> Array:
	return _costs.duplicate(true)


func get_summary() -> Dictionary:
	return FixedCostCalculator.summarize(_costs)


func add_cost(name: String, category: String, amount: float, due_day: int) -> bool:
	var clean_name := name.strip_edges()
	if clean_name.is_empty() or amount <= 0.0:
		return false

	_costs.append({
		"id": "fixed_%d_%d" % [Time.get_unix_time_from_system(), _costs.size()],
		"name": clean_name,
		"category": category.strip_edges() if not category.strip_edges().is_empty() else "Sonstiges",
		"amount": amount,
		"due_day": clampi(due_day, 1, 31),
		"paid": false,
		"paid_amount": 0.0,
	})
	return _save_and_emit()


func set_paid(cost_id: String, paid: bool) -> bool:
	for cost: Dictionary in _costs:
		if str(cost.id) == cost_id:
			cost.paid = paid
			cost.paid_amount = float(cost.amount) if paid else 0.0
			return _save_and_emit()
	return false


func add_payment(cost_id: String, payment: float) -> bool:
	if payment <= 0.0:
		return false
	for cost: Dictionary in _costs:
		if str(cost.id) == cost_id:
			var amount := float(cost.amount)
			var current := float(cost.get("paid_amount", 0.0))
			cost.paid_amount = minf(current + payment, amount)
			cost.paid = float(cost.paid_amount) >= amount
			return _save_and_emit()
	return false


func update_cost(
	cost_id: String,
	name: String,
	category: String,
	amount: float,
	due_day: int
) -> bool:
	var clean_name := name.strip_edges()
	if clean_name.is_empty() or amount <= 0.0:
		return false
	for cost: Dictionary in _costs:
		if str(cost.id) == cost_id:
			cost.name = clean_name
			cost.category = category.strip_edges() if not category.strip_edges().is_empty() else "Sonstiges"
			cost.amount = amount
			cost.paid_amount = minf(float(cost.get("paid_amount", 0.0)), amount)
			cost.paid = float(cost.paid_amount) >= amount
			cost.due_day = clampi(due_day, 1, 31)
			return _save_and_emit()
	return false


func remove_cost(cost_id: String) -> bool:
	for index in _costs.size():
		if str(_costs[index].id) == cost_id:
			_costs.remove_at(index)
			return _save_and_emit()
	return false


func replace_costs(costs: Array) -> bool:
	_costs = _sanitize_costs(costs)
	return _save_and_emit()


func _save_and_emit() -> bool:
	var saved := StorageManager.save_fixed_costs(_costs)
	fixed_costs_changed.emit(get_costs(), get_summary())
	return saved


func _sanitize_costs(source: Array) -> Array:
	var clean: Array = []
	for index in source.size():
		var item: Variant = source[index]
		if not item is Dictionary:
			continue
		var name := str(item.get("name", "")).strip_edges()
		var amount := maxf(float(item.get("amount", 0.0)), 0.0)
		if name.is_empty() or amount <= 0.0:
			continue
		clean.append({
			"id": str(item.get("id", "fixed_imported_%d" % index)),
			"name": name,
			"category": str(item.get("category", "Sonstiges")),
			"amount": amount,
			"due_day": clampi(int(item.get("due_day", 1)), 1, 31),
			"paid": bool(item.get("paid", false)),
			"paid_amount": clampf(
				float(item.get(
					"paid_amount",
					amount if bool(item.get("paid", false)) else 0.0
				)),
				0.0,
				amount
			),
		})
	return clean
