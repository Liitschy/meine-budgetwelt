extends RefCounted


static func summarize(costs: Array) -> Dictionary:
	var total := 0.0
	var paid := 0.0

	for cost: Variant in costs:
		if not cost is Dictionary:
			continue
		if not bool(cost.get("due_this_month", true)):
			continue
		var amount := maxf(float(cost.get("amount", 0.0)), 0.0)
		total += amount
		var paid_amount := float(cost.get(
			"paid_amount",
			amount if bool(cost.get("paid", false)) else 0.0
		))
		paid += clampf(paid_amount, 0.0, amount)

	return {
		"total": total,
		"paid": paid,
		"open": maxf(total - paid, 0.0),
	}
