extends RefCounted


static func summarize(items: Array, weekly_budget: float) -> Dictionary:
	var planned := 0.0
	var checked := 0.0
	var checked_count := 0

	for item: Variant in items:
		if not item is Dictionary:
			continue
		var price := maxf(float(item.get("estimated_price", 0.0)), 0.0)
		planned += price
		if bool(item.get("checked", false)):
			checked += price
			checked_count += 1

	return {
		"planned": planned,
		"checked": checked,
		"remaining": weekly_budget - planned,
		"item_count": items.size(),
		"checked_count": checked_count,
		"over_budget": planned > weekly_budget,
	}

