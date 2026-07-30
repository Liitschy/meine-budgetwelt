extends RefCounted


static func summarize(transactions: Array, active_week: int = -1) -> Dictionary:
	var income := 0.0
	var expenses := 0.0
	var savings := 0.0
	var weekly_expenses := 0.0
	var weekly_credit := 0.0
	var weekly_credit_total := 0.0

	for transaction: Variant in transactions:
		if not transaction is Dictionary:
			continue
		var amount := maxf(float(transaction.get("amount", 0.0)), 0.0)
		match str(transaction.get("kind", "expense")):
			"income":
				income += amount
			"saving":
				savings += amount
			"weekly_credit":
				weekly_credit_total += amount
				var credit_week := mini(
					floori(float(clampi(int(transaction.get("day", 1)), 1, 31) - 1) / 7.0),
					3
				)
				if active_week < 0 or credit_week == active_week:
					weekly_credit += amount
			_:
				expenses += amount
				var transaction_week := mini(
					floori(float(clampi(int(transaction.get("day", 1)), 1, 31) - 1) / 7.0),
					3
				)
				if str(transaction.get("category", "")) == "Wochenbudget":
					if active_week < 0 or transaction_week == active_week:
						weekly_expenses += amount

	return {
		"income": income,
		"expenses": expenses,
		"savings": savings,
		"weekly_expenses": weekly_expenses,
		"weekly_credit": weekly_credit,
		"weekly_credit_total": weekly_credit_total,
		"outflow": expenses + savings,
	}
