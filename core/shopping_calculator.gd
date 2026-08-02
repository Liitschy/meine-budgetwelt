extends RefCounted


static func summarize(items: Array, weekly_budget: float) -> Dictionary:
	var planned := 0.0
	var checked := 0.0
	var checked_estimated := 0.0
	var checked_count := 0
	var actual_price_count := 0

	for item: Variant in items:
		if not item is Dictionary:
			continue
		var price := maxf(float(item.get("estimated_price", 0.0)), 0.0)
		planned += price
		if bool(item.get("checked", false)):
			checked_estimated += price
			var actual_price := float(item.get("actual_price", -1.0))
			if actual_price >= 0.0:
				checked += actual_price
				actual_price_count += 1
			else:
				checked += price
			checked_count += 1

	return {
		"planned": planned,
		"checked": checked,
		"checked_estimated": checked_estimated,
		"remaining": weekly_budget - planned,
		"item_count": items.size(),
		"checked_count": checked_count,
		"actual_price_count": actual_price_count,
		"over_budget": planned > weekly_budget,
	}

