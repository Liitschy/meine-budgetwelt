extends RefCounted

const QuantityCalculator := preload("res://core/quantity_calculator.gd")


static func aggregate(ingredients: Array) -> Array:
	var grouped: Dictionary = {}
	var order: Array[String] = []
	for ingredient: Dictionary in ingredients:
		var name := str(ingredient.get("name", "")).strip_edges()
		if name.is_empty():
			continue
		var key := name.to_lower()
		var parsed := QuantityCalculator.parse(str(ingredient.get("quantity", "")))
		var dimension := str(parsed.get("dimension", "unknown"))
		var group_key := "%s|%s" % [key, dimension]
		if not grouped.has(group_key):
			grouped[group_key] = {
				"name": name,
				"dimension": dimension,
				"base_amount": 0.0,
				"quantity_parts": [],
				"estimated_price": 0.0,
			}
			order.append(group_key)
		var group: Dictionary = grouped[group_key]
		group.estimated_price += float(ingredient.get("estimated_price", 0.0))
		if parsed.is_empty():
			group.quantity_parts.append(str(ingredient.get("quantity", "")))
		else:
			group.base_amount += float(parsed.base_amount)
		grouped[group_key] = group

	var result: Array = []
	for group_key: String in order:
		var group: Dictionary = grouped[group_key]
		var quantity := ""
		if str(group.dimension) == "unknown":
			quantity = _format_unknown_parts(group.quantity_parts)
		else:
			quantity = QuantityCalculator.format_amount(
				float(group.base_amount),
				str(group.dimension)
			)
		result.append({
			"name": str(group.name),
			"quantity": quantity,
			"estimated_price": float(group.estimated_price),
		})
	return result


static func _format_unknown_parts(parts: Array) -> String:
	if parts.is_empty():
		return "nach Bedarf"
	var first := str(parts[0])
	var all_equal := true
	for part in parts:
		if str(part) != first:
			all_equal = false
			break
	return ("%d × %s" % [parts.size(), first]) if all_equal and parts.size() > 1 else " + ".join(parts)
