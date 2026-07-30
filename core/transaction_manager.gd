extends Node

signal active_transactions_changed(transactions: Array, summary: Dictionary)

const TransactionCalculator := preload("res://core/transaction_calculator.gd")

var _months: Dictionary = {}


func _ready() -> void:
	var saved := StorageManager.load_transactions()
	_months = saved.get("months", {}) if saved.get("months", {}) is Dictionary else {}
	MonthManager.active_month_changed.connect(_on_active_month_changed)


func get_active_transactions() -> Array:
	var month_id := MonthManager.get_active_month_id()
	var transactions: Array = _months.get(month_id, [])
	return transactions.duplicate(true)


func get_active_summary() -> Dictionary:
	return TransactionCalculator.summarize(
		get_active_transactions(),
		get_active_week_index()
	)


func get_active_week_index() -> int:
	var today := Time.get_date_dict_from_system()
	var current_month := "%04d-%02d" % [int(today.year), int(today.month)]
	if MonthManager.get_active_month_id() != current_month:
		return 0
	return clampi(floori(float(int(today.day) - 1) / 7.0), 0, 3)


func add_transaction(
	kind: String,
	category: String,
	description: String,
	amount: float,
	day: int
) -> bool:
	if amount <= 0.0 or description.strip_edges().is_empty():
		return false

	var normalized_kind := (
		kind
		if kind in ["income", "expense", "saving", "weekly_credit"]
		else "expense"
	)
	var month_id := MonthManager.get_active_month_id()
	var transactions: Array = _months.get(month_id, [])
	transactions.append({
		"id": "booking_%d_%d" % [
			int(Time.get_unix_time_from_system()),
			transactions.size(),
		],
		"kind": normalized_kind,
		"category": category.strip_edges() if not category.strip_edges().is_empty() else "Sonstiges",
		"description": description.strip_edges(),
		"amount": amount,
		"day": clampi(day, 1, 31),
	})
	_months[month_id] = transactions
	return _save_and_emit()


func remove_transaction(transaction_id: String) -> bool:
	var month_id := MonthManager.get_active_month_id()
	var transactions: Array = _months.get(month_id, [])
	for index in transactions.size():
		if str(transactions[index].id) == transaction_id:
			transactions.remove_at(index)
			_months[month_id] = transactions
			return _save_and_emit()
	return false


func _save_and_emit() -> bool:
	var saved := StorageManager.save_transactions({
		"schema_version": 1,
		"months": _months,
	})
	active_transactions_changed.emit(
		get_active_transactions(),
		get_active_summary()
	)
	return saved


func _on_active_month_changed(_month_id: String, _display_name: String) -> void:
	active_transactions_changed.emit(
		get_active_transactions(),
		get_active_summary()
	)
