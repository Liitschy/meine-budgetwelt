extends Node

signal active_transactions_changed(transactions: Array, summary: Dictionary)

const TransactionCalculator := preload("res://core/transaction_calculator.gd")

var _months: Dictionary = {}


func _ready() -> void:
	reload_from_storage(false)

	MonthManager.active_month_changed.connect(_on_active_month_changed)


func reload_from_storage(emit_change: bool = true) -> void:
	var saved := StorageManager.load_transactions()
	_months = saved.get("months", {}) if saved.get("months", {}) is Dictionary else {}
	if emit_change:
		active_transactions_changed.emit(
			get_active_transactions(),
			get_active_summary()
		)


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


func get_bank_import_ids() -> Array[String]:
	var result: Array[String] = []
	for transactions: Variant in _months.values():
		if not transactions is Array:
			continue
		for transaction: Variant in transactions:
			if not transaction is Dictionary:
				continue
			var import_id := str(transaction.get("bank_import_id", "")).strip_edges()
			if not import_id.is_empty():
				result.append(import_id)
	return result


func import_bank_transactions(items: Array) -> Dictionary:
	var known: Dictionary = {}
	for import_id: String in get_bank_import_ids():
		known[import_id] = true
	var imported := 0
	var duplicates := 0
	var rejected := 0
	for raw_item: Variant in items:
		if not raw_item is Dictionary:
			rejected += 1
			continue
		var item: Dictionary = raw_item
		var import_id := str(item.get("importId", item.get("import_id", ""))).strip_edges()
		var status := str(item.get("status", "")).to_lower()
		var currency := str(item.get("currency", "")).to_upper()
		var kind := str(item.get("kind", "")).to_lower()
		var date_text := str(item.get("bookingDate", item.get("booking_date", "")))
		var amount := float(item.get("amount", 0.0))
		var description := str(item.get("description", "")).strip_edges()
		if known.has(import_id):
			duplicates += 1
			continue
		if (
			import_id.is_empty()
			or status != "booked"
			or currency != "EUR"
			or kind not in ["income", "expense"]
			or amount <= 0.0
			or description.is_empty()
			or not _is_iso_date(date_text)
		):
			rejected += 1
			continue
		var month_id := date_text.left(7)
		var transactions: Array = _months.get(month_id, [])
		transactions.append({
			"id": "bank_%s" % import_id.right(20),
			"kind": kind,
			"category": "Bankimport",
			"description": description,
			"amount": amount,
			"day": clampi(date_text.right(2).to_int(), 1, 31),
			"bank_import_id": import_id,
			"bank_provider": "gocardless-bad",
			"bank_account_reference": str(item.get(
				"accountReference",
				item.get("account_reference", "")
			)),
			"booking_date": date_text,
		})
		_months[month_id] = transactions
		known[import_id] = true
		imported += 1
	var saved := true
	if imported > 0:
		saved = _save_and_emit()
	return {
		"success": saved,
		"imported": imported,
		"duplicates": duplicates,
		"rejected": rejected,
	}


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


static func _is_iso_date(value: String) -> bool:
	if value.length() != 10 or value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
		return false
	var date := Time.get_datetime_dict_from_datetime_string(value, false)
	return not date.is_empty()
