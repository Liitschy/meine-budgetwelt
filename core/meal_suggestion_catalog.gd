extends RefCounted

const SUGGESTIONS := [
	{
		"id": "linseneintopf_kette",
		"mode": "Vorkochen",
		"meal": "Deftiger Linseneintopf",
		"chain_note": "Kartoffeln und Möhren für morgen zusätzlich vorbereiten.",
	},
	{
		"id": "kartoffel_moehren_kette",
		"mode": "Reste",
		"meal": "Kartoffel-Möhren-Pfanne mit Spiegelei",
		"chain_note": "Verwendet die vorbereiteten Zutaten von Tag 1.",
	},
	{
		"id": "kichererbsen_curry_kette",
		"mode": "Vorkochen",
		"meal": "Cremiges Kichererbsen-Curry mit Reis",
		"chain_note": "Doppelte Reismenge kochen und die Hälfte für morgen kühlen.",
	},
	{
		"id": "fried_rice_kette",
		"mode": "Reste",
		"meal": "Gebratener Reis mit Gemüse",
		"chain_note": "Verwendet den gekühlten Reis von Tag 3.",
	},
	{
		"id": "spaghetti_pomodoro_kette",
		"mode": "Normal kochen",
		"meal": "Klassische Spaghetti al Pomodoro",
		"chain_note": "Günstiges Vorratsgericht mit mehrfach verwendbaren Zutaten.",
	},
	{
		"id": "ofenkartoffeln_kette",
		"mode": "Normal kochen",
		"meal": "Ofenkartoffeln mit Kräuterquark",
		"chain_note": "Verwendet die Kartoffeln aus dem gemeinsamen Wochensack.",
	},
	{
		"id": "restepfanne_kette",
		"mode": "Reste",
		"meal": "Restepfanne „All-in-One“ mit Toast",
		"chain_note": "Verbraucht geeignete Gemüse- und Eierreserven der Woche.",
	},
]

const ALTERNATIVES := [
	{"id": "overnight_reisbox", "mode": "Meal-Prep", "meal": "Overnight Oats und Gemüse-Reisbox"},
	{"id": "kartoffel_ei", "mode": "Normal kochen", "meal": "Kartoffel-Ei-Pfanne mit Salat"},
	{"id": "nudel_gemuese", "mode": "Schnell", "meal": "Nudel-Gemüse-Pfanne"},
	{"id": "linsen_bolognese", "mode": "Normal kochen", "meal": "Linsen-Bolognese"},
	{"id": "reisbox_joghurt", "mode": "Meal-Prep", "meal": "Gemüse-Reisbox mit Joghurtsnack"},
	{"id": "haehnchen_reis", "mode": "Normal kochen", "meal": "Hähnchen-Gemüse-Pfanne mit Reis"},
	{"id": "kartoffelsuppe", "mode": "Vorkochen", "meal": "Einfache Kartoffelsuppe"},
	{"id": "ofengemuese", "mode": "Normal kochen", "meal": "Ofengemüse mit Kräuterquark"},
	{"id": "fertiggericht_salat", "mode": "Schnell", "meal": "Günstiges Fertiggericht mit Salat"},
]


static func suggestion_for(day_index: int) -> Dictionary:
	return SUGGESTIONS[day_index % SUGGESTIONS.size()].duplicate(true)


static func generate() -> Array:
	var result: Array = []
	for day_index in range(7):
		var suggestion := suggestion_for(day_index)
		result.append({
			"day_index": day_index,
			"mode": str(suggestion.mode),
			"meal": str(suggestion.meal),
			"recipe_id": str(suggestion.id),
			"chain_note": str(suggestion.chain_note),
			"confirmed": false,
		})
	return result


static func mix_unconfirmed(current_plan: Array, seed: int) -> Array:
	var result := current_plan.duplicate(true)
	var candidates := ALTERNATIVES.duplicate(true)
	var random := RandomNumberGenerator.new()
	random.seed = seed
	for index in range(candidates.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var temporary: Variant = candidates[index]
		candidates[index] = candidates[swap_index]
		candidates[swap_index] = temporary
	var used: Dictionary = {}
	for day: Dictionary in result:
		if bool(day.get("confirmed", false)):
			used[str(day.get("recipe_id", ""))] = true
	var candidate_index := 0
	for day_index in result.size():
		var day: Dictionary = result[day_index]
		if bool(day.get("confirmed", false)):
			continue
		while candidate_index < candidates.size() and used.has(str(candidates[candidate_index].id)):
			candidate_index += 1
		if candidate_index >= candidates.size():
			candidate_index = 0
		var candidate: Dictionary = candidates[candidate_index]
		candidate_index += 1
		used[str(candidate.id)] = true
		result[day_index] = {
			"day_index": day_index,
			"mode": str(candidate.mode),
			"meal": str(candidate.meal),
			"recipe_id": str(candidate.id),
			"chain_note": "Neuer günstiger Vorschlag für zwei Personen.",
			"confirmed": false,
		}
	return result
