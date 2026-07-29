extends RefCounted

const RECIPES := {
	"linseneintopf_kette": {
		"title": "Deftiger Linseneintopf",
		"ingredients": [
			{"name": "Tellerlinsen", "quantity": "250 g", "estimated_price": 1.79},
			{"name": "Suppengrün", "quantity": "1 Bund", "estimated_price": 1.99},
			{"name": "Kartoffeln", "quantity": "2 kg", "estimated_price": 3.49},
			{"name": "Gemüsebrühe", "quantity": "1 Packung", "estimated_price": 0.89},
		],
		"preparation": "Linsen nach Packungsangabe garen. Suppengrün und einen Teil der Kartoffeln würfeln, mit Brühe zugeben und weich kochen. Einen Teil der Kartoffeln und Möhren bewusst separat für Tag 2 aufbewahren.",
	},
	"kartoffel_moehren_kette": {
		"title": "Kartoffel-Möhren-Pfanne mit Spiegelei",
		"ingredients": [
			{"name": "Kartoffeln", "quantity": "700 g vorbereitet", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "Möhren", "quantity": "300 g vorbereitet", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "Eier", "quantity": "6 Stück", "estimated_price": 2.49},
		],
		"preparation": "Die an Tag 1 zurückgelegten Kartoffeln und Möhren in Scheiben schneiden und knusprig anbraten. Zwei Spiegeleier daraufgeben. Die übrigen Eier werden an Tag 4 und für die Restepfanne verwendet.",
	},
	"kichererbsen_curry_kette": {
		"title": "Cremiges Kichererbsen-Curry mit Reis",
		"ingredients": [
			{"name": "Kichererbsen", "quantity": "1 Dose", "estimated_price": 0.89},
			{"name": "Gehackte Tomaten", "quantity": "1 Dose", "estimated_price": 0.89},
			{"name": "Kokosmilch", "quantity": "1 Dose", "estimated_price": 1.29},
			{"name": "Basmatireis", "quantity": "400 g", "estimated_price": 2.49},
		],
		"preparation": "Kichererbsen, Tomaten und Kokosmilch mit Currypulver etwa 15 Minuten köcheln. Bewusst die doppelte benötigte Reismenge kochen und den übrigen Reis rasch abkühlen lassen und für Tag 4 kalt stellen.",
	},
	"fried_rice_kette": {
		"title": "Gebratener Reis mit Gemüse",
		"ingredients": [
			{"name": "Basmatireis", "quantity": "500 g gekocht", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "TK-Gemüsemischung", "quantity": "500 g", "estimated_price": 2.99},
			{"name": "Eier", "quantity": "2 Stück", "estimated_price": 0.0, "include_in_shopping": false},
		],
		"preparation": "Den kalten Reis von Tag 3 mit TK-Gemüse scharf anbraten. Zwei Eier verquirlen, unterrühren und vollständig stocken lassen.",
	},
	"spaghetti_pomodoro_kette": {
		"title": "Klassische Spaghetti al Pomodoro",
		"ingredients": [
			{"name": "Spaghetti", "quantity": "400 g", "estimated_price": 0.99},
			{"name": "Gehackte Tomaten", "quantity": "1 Dose", "estimated_price": 0.89},
			{"name": "Tomatenmark", "quantity": "1 Tube", "estimated_price": 0.99},
			{"name": "Zwiebeln", "quantity": "1 kg", "estimated_price": 1.49},
			{"name": "Knoblauch", "quantity": "1 Knolle", "estimated_price": 0.79},
		],
		"preparation": "Zwiebel und Knoblauch anbraten, Tomatenmark kurz mitrösten und gehackte Tomaten zugeben. Würzen, köcheln lassen und mit den Spaghetti servieren.",
	},
	"ofenkartoffeln_kette": {
		"title": "Ofenkartoffeln mit Kräuterquark",
		"ingredients": [
			{"name": "Kartoffeln", "quantity": "1 kg aus dem Wochensack", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "Speisequark", "quantity": "500 g", "estimated_price": 1.39},
			{"name": "Milch", "quantity": "100 ml", "estimated_price": 1.15},
			{"name": "Schnittlauch", "quantity": "1 Bund", "estimated_price": 0.99},
		],
		"preparation": "Große Kartoffeln bei 200 °C weich backen. Quark mit etwas Milch glattrühren, würzen und Schnittlauch unterheben.",
	},
	"restepfanne_kette": {
		"title": "Restepfanne „All-in-One“ mit Toast",
		"ingredients": [
			{"name": "Gemüsereste", "quantity": "alle Reste", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "Eier", "quantity": "übrige Eier", "estimated_price": 0.0, "include_in_shopping": false},
			{"name": "Toastbrot", "quantity": "1 Packung", "estimated_price": 1.29},
		],
		"preparation": "Alle geeigneten Gemüsereste klein schneiden und vollständig durcherhitzen. Übrige Eier dazugeben und stocken lassen. Toast rösten und dazu servieren.",
	},
	"overnight_reisbox": {
		"title": "Overnight Oats und Gemüse-Reisbox",
		"ingredients": [
			{"name": "Haferflocken", "quantity": "500 g", "estimated_price": 0.95},
			{"name": "Naturjoghurt", "quantity": "500 g", "estimated_price": 1.19},
			{"name": "Reis", "quantity": "1 kg", "estimated_price": 1.99},
			{"name": "TK-Gemüse", "quantity": "750 g", "estimated_price": 2.49},
		],
		"preparation": "Haferflocken am Vorabend mit Joghurt verrühren. Reis kochen, TK-Gemüse anbraten und beides auf Vorratsdosen verteilen.",
	},
	"kartoffel_ei": {
		"title": "Kartoffel-Ei-Pfanne mit frischem Salat",
		"ingredients": [
			{"name": "Kartoffeln", "quantity": "2,5 kg", "estimated_price": 3.49},
			{"name": "Eier", "quantity": "10 Stück", "estimated_price": 2.49},
			{"name": "Kopfsalat", "quantity": "1 Stück", "estimated_price": 1.29},
			{"name": "Zwiebeln", "quantity": "1 kg", "estimated_price": 1.49},
		],
		"preparation": "Kartoffeln würfeln und in wenig Öl gar braten. Zwiebeln und Eier dazugeben. Salat waschen und als frische Beilage servieren.",
	},
	"nudel_gemuese": {
		"title": "Nudel-Gemüse-Pfanne in 15 Minuten",
		"ingredients": [
			{"name": "Nudeln", "quantity": "500 g", "estimated_price": 0.99},
			{"name": "TK-Gemüse", "quantity": "750 g", "estimated_price": 2.49},
			{"name": "Passierte Tomaten", "quantity": "500 g", "estimated_price": 0.89},
		],
		"preparation": "Nudeln kochen. TK-Gemüse in einer Pfanne erhitzen, passierte Tomaten einrühren, würzen und mit den Nudeln mischen.",
	},
	"linsen_bolognese": {
		"title": "Linsen-Bolognese mit Vollkornnudeln",
		"ingredients": [
			{"name": "Vollkornnudeln", "quantity": "500 g", "estimated_price": 1.29},
			{"name": "Rote Linsen", "quantity": "500 g", "estimated_price": 1.79},
			{"name": "Passierte Tomaten", "quantity": "2 × 500 g", "estimated_price": 1.78},
			{"name": "Möhren", "quantity": "1 kg", "estimated_price": 1.29},
		],
		"preparation": "Möhren klein schneiden und anschwitzen. Linsen und Tomaten zugeben, etwa 15 Minuten köcheln lassen und zu den Nudeln servieren.",
	},
	"reisbox_joghurt": {
		"title": "Sättigende Reisbox und leichter Joghurtsnack",
		"ingredients": [
			{"name": "Reis", "quantity": "1 kg", "estimated_price": 1.99},
			{"name": "TK-Gemüse", "quantity": "750 g", "estimated_price": 2.49},
			{"name": "Kidneybohnen", "quantity": "1 Dose", "estimated_price": 0.89},
			{"name": "Naturjoghurt", "quantity": "500 g", "estimated_price": 1.19},
		],
		"preparation": "Reis vorkochen, mit Gemüse und abgespülten Bohnen mischen und portionsweise abfüllen. Joghurt getrennt als Snack mitnehmen.",
	},
	"haehnchen_reis": {
		"title": "Hähnchen-Gemüse-Pfanne mit Reis",
		"ingredients": [
			{"name": "Hähnchenbrust", "quantity": "500 g", "estimated_price": 5.49},
			{"name": "Reis", "quantity": "1 kg", "estimated_price": 1.99},
			{"name": "TK-Gemüse", "quantity": "750 g", "estimated_price": 2.49},
		],
		"preparation": "Reis kochen. Hähnchen vollständig durchbraten, Gemüse dazugeben, würzen und mit dem Reis servieren.",
	},
	"kartoffelsuppe": {
		"title": "Kartoffelsuppe für mehrere Portionen",
		"ingredients": [
			{"name": "Kartoffeln", "quantity": "2,5 kg", "estimated_price": 3.49},
			{"name": "Suppengemüse", "quantity": "1 Bund", "estimated_price": 1.99},
			{"name": "Gemüsebrühe", "quantity": "1 Packung", "estimated_price": 0.89},
		],
		"preparation": "Kartoffeln und Suppengemüse würfeln, mit Brühe bedecken und weich kochen. Grob pürieren, abschmecken und portionsweise kalt stellen.",
	},
	"ofengemuese": {
		"title": "Ofengemüse mit Kräuterquark",
		"ingredients": [
			{"name": "Kartoffeln", "quantity": "2,5 kg", "estimated_price": 3.49},
			{"name": "Möhren", "quantity": "1 kg", "estimated_price": 1.29},
			{"name": "Zucchini", "quantity": "2 Stück", "estimated_price": 1.79},
			{"name": "Magerquark", "quantity": "500 g", "estimated_price": 1.39},
		],
		"preparation": "Gemüse schneiden, würzen und bei 200 °C etwa 30 Minuten backen. Quark mit Kräutern, Salz und etwas Wasser cremig rühren.",
	},
	"fertiggericht_salat": {
		"title": "Günstiges Fertiggericht mit zusätzlichem Salat",
		"ingredients": [
			{"name": "Fertiggericht (Eigenmarke)", "quantity": "1 Packung", "estimated_price": 2.79},
			{"name": "Kopfsalat", "quantity": "1 Stück", "estimated_price": 1.29},
		],
		"preparation": "Fertiggericht nach Packungsangabe erhitzen. Salat waschen und als frische Ergänzung dazu essen.",
	},
	"reste_gemuese": {
		"title": "Reste vom Vortag mit frischem Gemüse ergänzen",
		"ingredients": [
			{"name": "Saisonales Gemüse", "quantity": "500 g", "estimated_price": 1.99},
		],
		"preparation": "Vorhandene Reste vollständig durcherhitzen. Gemüse frisch schneiden oder kurz anbraten und dazugeben.",
	},
}

const RECIPE_TIMES := {
	"linseneintopf_kette": 15,
	"kartoffel_moehren_kette": 15,
	"kichererbsen_curry_kette": 15,
	"fried_rice_kette": 10,
	"spaghetti_pomodoro_kette": 15,
	"ofenkartoffeln_kette": 10,
	"restepfanne_kette": 10,
}


static func get_recipe(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = RECIPES.get(recipe_id, {}).duplicate(true)
	if recipe.is_empty():
		return recipe
	recipe.servings = 2
	recipe.active_minutes = int(RECIPE_TIMES.get(recipe_id, 15))
	return recipe


static func ingredients_for(recipe_id: String) -> Array:
	var recipe := get_recipe(recipe_id)
	var result: Array = []
	for ingredient: Dictionary in recipe.get("ingredients", []):
		if bool(ingredient.get("include_in_shopping", true)):
			result.append(ingredient.duplicate(true))
	return result
