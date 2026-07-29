extends RefCounted

const QuantityCalculator := preload("res://core/quantity_calculator.gd")

const PACKS := {
	"reis": [
		{"quantity": "500 g", "price": 1.19},
		{"quantity": "1 kg", "price": 1.99},
	],
	"kartoffeln": [
		{"quantity": "2,5 kg", "price": 3.49},
		{"quantity": "5 kg", "price": 5.99},
	],
	"nudeln": [{"quantity": "500 g", "price": 0.99}],
	"vollkornnudeln": [{"quantity": "500 g", "price": 1.29}],
	"haferflocken": [{"quantity": "500 g", "price": 0.95}],
	"rote linsen": [{"quantity": "500 g", "price": 1.79}],
	"tellerlinsen": [{"quantity": "500 g", "price": 1.79}],
	"möhren": [{"quantity": "1 kg", "price": 1.29}],
	"zwiebeln": [{"quantity": "1 kg", "price": 1.49}],
	"tk-gemüse": [
		{"quantity": "750 g", "price": 2.49},
		{"quantity": "1 kg", "price": 2.99},
	],
	"passierte tomaten": [{"quantity": "500 g", "price": 0.89}],
	"naturjoghurt": [{"quantity": "500 g", "price": 1.19}],
	"magerquark": [{"quantity": "500 g", "price": 1.39}],
	"hähnchenbrust": [{"quantity": "500 g", "price": 5.49}],
	"eier": [{"quantity": "10 Stück", "price": 2.49}],
	"basmatireis": [
		{"quantity": "500 g", "price": 1.39},
		{"quantity": "1 kg", "price": 2.49},
	],
	"spaghetti": [{"quantity": "500 g", "price": 0.99}],
	"tk-gemüsemischung": [
		{"quantity": "750 g", "price": 2.49},
		{"quantity": "1 kg", "price": 2.99},
	],
	"speisequark": [{"quantity": "500 g", "price": 1.39}],
	"milch": [{"quantity": "1 l", "price": 1.15}],
}


static func plan_all(ingredients: Array) -> Array:
	var result: Array = []
	for ingredient: Dictionary in ingredients:
		result.append(plan_ingredient(ingredient))
	return result


static func plan_ingredient(ingredient: Dictionary) -> Dictionary:
	var planned := ingredient.duplicate(true)
	var key := str(ingredient.get("name", "")).strip_edges().to_lower()
	var required := QuantityCalculator.parse(str(ingredient.get("quantity", "")))
	var pack_definitions: Array = PACKS.get(key, [])
	if required.is_empty() or pack_definitions.is_empty():
		return planned

	var options: Array = []
	for definition: Dictionary in pack_definitions:
		var parsed := QuantityCalculator.parse(str(definition.quantity))
		if not parsed.is_empty() and str(parsed.dimension) == str(required.dimension):
			options.append({
				"quantity": str(definition.quantity),
				"amount": float(parsed.base_amount),
				"price": float(definition.price),
			})
	if options.is_empty():
		return planned

	var best := {"found": false, "price": INF, "waste": INF, "counts": []}
	_search_combinations(
		options,
		0,
		float(required.base_amount),
		0.0,
		0.0,
		[],
		best
	)
	if not bool(best.found):
		return planned

	var purchased := float(required.base_amount) + float(best.waste)
	var pack_parts: Array[String] = []
	var pack_count := 0
	for index in options.size():
		var count := int(best.counts[index])
		if count <= 0:
			continue
		pack_count += count
		pack_parts.append("%d × %s" % [count, str(options[index].quantity)])
	planned.estimated_price = float(best.price)
	planned.quantity = QuantityCalculator.format_amount(purchased, str(required.dimension))
	planned.pack_plan = ", ".join(pack_parts)
	planned.required_quantity = str(ingredient.get("quantity", ""))
	planned.surplus_quantity = QuantityCalculator.format_amount(
		float(best.waste),
		str(required.dimension)
	)
	planned.pack_count = pack_count
	return planned


static func _search_combinations(
	options: Array,
	index: int,
	required: float,
	amount: float,
	price: float,
	counts: Array,
	best: Dictionary
) -> void:
	if index >= options.size():
		if amount + 0.0001 < required:
			return
		var waste := amount - required
		if (
			not bool(best.found)
			or price < float(best.price) - 0.0001
			or (is_equal_approx(price, float(best.price)) and waste < float(best.waste))
		):
			best.found = true
			best.price = price
			best.waste = waste
			best.counts = counts.duplicate()
		return
	var option: Dictionary = options[index]
	var max_count := int(ceil(required / float(option.amount))) + 1
	for count in range(max_count + 1):
		var next_counts := counts.duplicate()
		next_counts.append(count)
		_search_combinations(
			options,
			index + 1,
			required,
			amount + count * float(option.amount),
			price + count * float(option.price),
			next_counts,
			best
		)
