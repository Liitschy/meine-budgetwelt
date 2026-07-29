extends Node

const BUDGET_FILE := "user://budget_data.json"
const FIXED_COSTS_FILE := "user://fixed_costs.json"
const MONTH_HISTORY_FILE := "user://month_history.json"
const SAVINGS_GOALS_FILE := "user://savings_goals.json"
const TRANSACTIONS_FILE := "user://transactions.json"
const SHOPPING_FILE := "user://shopping.json"
const MEAL_PLANS_FILE := "user://meal_plans.json"
const CUSTOM_RECIPES_FILE := "user://custom_recipes.json"

const DATA_FILES := [
	BUDGET_FILE,
	FIXED_COSTS_FILE,
	MONTH_HISTORY_FILE,
	SAVINGS_GOALS_FILE,
	TRANSACTIONS_FILE,
	SHOPPING_FILE,
	MEAL_PLANS_FILE,
	CUSTOM_RECIPES_FILE,
]


func load_budget_data() -> Dictionary:
	var parsed: Variant = _load_json(BUDGET_FILE)
	if parsed is Dictionary:
		return parsed

	return {}


func save_budget_data(data: Dictionary) -> bool:
	return _save_json(BUDGET_FILE, data)


func load_fixed_costs() -> Array:
	var parsed: Variant = _load_json(FIXED_COSTS_FILE)
	if parsed is Array:
		return parsed
	return []


func save_fixed_costs(costs: Array) -> bool:
	return _save_json(FIXED_COSTS_FILE, costs)


func load_month_history() -> Dictionary:
	var parsed: Variant = _load_json(MONTH_HISTORY_FILE)
	if parsed is Dictionary:
		return parsed
	return {}


func save_month_history(history: Dictionary) -> bool:
	return _save_json(MONTH_HISTORY_FILE, history)


func load_savings_goals() -> Array:
	var parsed: Variant = _load_json(SAVINGS_GOALS_FILE)
	if parsed is Array:
		return parsed
	return []


func save_savings_goals(goals: Array) -> bool:
	return _save_json(SAVINGS_GOALS_FILE, goals)


func load_transactions() -> Dictionary:
	var parsed: Variant = _load_json(TRANSACTIONS_FILE)
	if parsed is Dictionary:
		return parsed
	return {}


func save_transactions(data: Dictionary) -> bool:
	return _save_json(TRANSACTIONS_FILE, data)


func load_shopping_data() -> Dictionary:
	var parsed: Variant = _load_json(SHOPPING_FILE)
	if parsed is Dictionary:
		return parsed
	return {}


func save_shopping_data(data: Dictionary) -> bool:
	return _save_json(SHOPPING_FILE, data)


func load_meal_plans() -> Dictionary:
	var parsed: Variant = _load_json(MEAL_PLANS_FILE)
	if parsed is Dictionary:
		return parsed
	return {}


func save_meal_plans(data: Dictionary) -> bool:
	return _save_json(MEAL_PLANS_FILE, data)


func load_custom_recipes() -> Array:
	var parsed: Variant = _load_json(CUSTOM_RECIPES_FILE)
	return parsed if parsed is Array else []


func save_custom_recipes(recipes: Array) -> bool:
	return _save_json(CUSTOM_RECIPES_FILE, recipes)




func create_backup() -> Dictionary:
	var timestamp := Time.get_datetime_string_from_system(false, true)
	timestamp = timestamp.replace(":", "-").replace(" ", "_")
	var relative_directory := "user://backups/%s" % timestamp
	var absolute_directory := ProjectSettings.globalize_path(relative_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return {
			"success": false,
			"message": "Der Sicherungsordner konnte nicht erstellt werden.",
		}

	var copied := 0
	for source_path: String in DATA_FILES:
		if not FileAccess.file_exists(source_path):
			continue
		var target_path := "%s/%s" % [
			relative_directory,
			source_path.get_file(),
		]
		if DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source_path),
			ProjectSettings.globalize_path(target_path)
		) == OK:
			copied += 1

	if copied == 0:
		return {
			"success": false,
			"message": "Es wurden noch keine Daten zum Sichern gefunden.",
		}

	return {
		"success": true,
		"path": absolute_directory,
		"message": "%d Datendateien wurden gesichert." % copied,
	}


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Lokale Daten konnten nicht geöffnet werden: %s" % path)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_warning("Lokale Daten sind ungültig und werden ignoriert: %s" % path)
	return parsed


func _save_json(path: String, data: Variant) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Lokale Daten konnten nicht gespeichert werden: %s" % path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true
