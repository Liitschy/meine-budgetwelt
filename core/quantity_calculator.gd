extends RefCounted

const UNIT_DATA := {
	"g": {"dimension": "mass", "factor": 1.0},
	"gramm": {"dimension": "mass", "factor": 1.0},
	"kg": {"dimension": "mass", "factor": 1000.0},
	"ml": {"dimension": "volume", "factor": 1.0},
	"milliliter": {"dimension": "volume", "factor": 1.0},
	"l": {"dimension": "volume", "factor": 1000.0},
	"liter": {"dimension": "volume", "factor": 1000.0},
	"stück": {"dimension": "count", "factor": 1.0},
	"stueck": {"dimension": "count", "factor": 1.0},
	"stk": {"dimension": "count", "factor": 1.0},
}


static func parse(text: String) -> Dictionary:
	var normalized := text.strip_edges().to_lower().replace(",", ".")
	normalized = normalized.replace("×", "x")
	var multiplied := RegEx.new()
	multiplied.compile("^([0-9]+(?:\\.[0-9]+)?)\\s*x\\s*([0-9]+(?:\\.[0-9]+)?)\\s*([a-zäöü]+)$")
	var multiplied_match := multiplied.search(normalized)
	if multiplied_match:
		return _from_parts(
			multiplied_match.get_string(1).to_float()
				* multiplied_match.get_string(2).to_float(),
			multiplied_match.get_string(3)
		)
	var simple := RegEx.new()
	simple.compile("^([0-9]+(?:\\.[0-9]+)?)\\s*([a-zäöü]+)$")
	var simple_match := simple.search(normalized)
	if not simple_match:
		return {}
	return _from_parts(
		simple_match.get_string(1).to_float(),
		simple_match.get_string(2)
	)


static func subtract(required_text: String, available_text: String) -> Dictionary:
	var required := parse(required_text)
	var available := parse(available_text)
	if required.is_empty() or available.is_empty():
		return {"convertible": false}
	if str(required.dimension) != str(available.dimension):
		return {"convertible": false}
	var missing_base := maxf(float(required.base_amount) - float(available.base_amount), 0.0)
	return {
		"convertible": true,
		"covered": missing_base <= 0.0001,
		"missing_base": missing_base,
		"missing_text": format_amount(missing_base, str(required.dimension)),
	}


static func format_amount(base_amount: float, dimension: String) -> String:
	var unit := "g"
	var amount := base_amount
	if dimension == "mass" and base_amount >= 1000.0:
		unit = "kg"
		amount = base_amount / 1000.0
	elif dimension == "volume" and base_amount >= 1000.0:
		unit = "l"
		amount = base_amount / 1000.0
	elif dimension == "volume":
		unit = "ml"
	elif dimension == "count":
		unit = "Stück"
	var number := (
		str(int(round(amount)))
		if is_equal_approx(amount, round(amount))
		else ("%.2f" % amount).trim_suffix("0").trim_suffix("0").trim_suffix(".")
	)
	return "%s %s" % [number.replace(".", ","), unit]


static func _from_parts(amount: float, unit: String) -> Dictionary:
	var data: Dictionary = UNIT_DATA.get(unit, {})
	if data.is_empty() or amount < 0.0:
		return {}
	return {
		"dimension": str(data.dimension),
		"base_amount": amount * float(data.factor),
	}
