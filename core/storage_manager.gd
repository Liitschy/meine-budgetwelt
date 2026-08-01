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

const SYNC_SCHEMA_VERSION := 1
const SYNC_FILE_DEFAULTS := {
	"budget_data.json": {},
	"fixed_costs.json": [],
	"month_history.json": {},
	"savings_goals.json": [],
	"transactions.json": {},
	"shopping.json": {},
	"meal_plans.json": {},
	"custom_recipes.json": [],
}


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


func has_fixed_costs_data() -> bool:
	return FileAccess.file_exists(FIXED_COSTS_FILE)


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


func has_savings_goals_data() -> bool:
	return FileAccess.file_exists(SAVINGS_GOALS_FILE)


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


func export_sync_snapshot() -> Dictionary:
	var files := {}
	for path: String in DATA_FILES:
		var file_name := path.get_file()
		var parsed: Variant = _load_json(path)
		if not is_valid_backup_root(file_name, parsed):
			parsed = SYNC_FILE_DEFAULTS[file_name].duplicate(true)
		files[file_name] = parsed
	return {
		"schemaVersion": SYNC_SCHEMA_VERSION,
		"files": files,
	}


func import_sync_snapshot(snapshot: Variant) -> Dictionary:
	if not is_valid_sync_snapshot(snapshot):
		return {
			"success": false,
			"message": "Der Server-Datenstand ist unvollständig oder ungültig.",
		}

	var safety_backup := create_backup()
	if not bool(safety_backup.get("success", false)) and _has_current_data():
		return {
			"success": false,
			"message": "Vor der Synchronisation konnte keine Sicherung erstellt werden.",
		}

	var staging_directory := "user://sync-staging/%d" % Time.get_ticks_usec()
	if DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(staging_directory)
	) != OK:
		return {
			"success": false,
			"message": "Der Server-Datenstand konnte nicht vorbereitet werden.",
		}

	var files: Dictionary = snapshot.files
	for target_path: String in DATA_FILES:
		var file_name := target_path.get_file()
		var staging_path := "%s/%s" % [staging_directory, file_name]
		if not _save_json(staging_path, files[file_name]):
			_cleanup_sync_staging(staging_directory)
			return {
				"success": false,
				"message": "Der Server-Datenstand konnte nicht vorbereitet werden.",
			}

	var written_files: Array[String] = []
	for target_path: String in DATA_FILES:
		var source_path := "%s/%s" % [
			staging_directory,
			target_path.get_file(),
		]
		if DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source_path),
			ProjectSettings.globalize_path(target_path)
		) != OK:
			_rollback_sync_import(written_files, safety_backup)
			_cleanup_sync_staging(staging_directory)
			return {
				"success": false,
				"message": "Der Server-Datenstand konnte nicht vollständig übernommen werden.",
			}
		written_files.append(target_path)

	_cleanup_sync_staging(staging_directory)
	return {
		"success": true,
		"safety_backup_path": str(safety_backup.get("path", "")),
		"message": "Der Server-Datenstand wurde sicher übernommen.",
	}


static func is_valid_sync_snapshot(snapshot: Variant) -> bool:
	if not snapshot is Dictionary:
		return false
	if int(snapshot.get("schemaVersion", 0)) != SYNC_SCHEMA_VERSION:
		return false
	var files: Variant = snapshot.get("files", null)
	if not files is Dictionary or files.size() != SYNC_FILE_DEFAULTS.size():
		return false
	for file_name: String in SYNC_FILE_DEFAULTS:
		if not files.has(file_name):
			return false
		if not is_valid_backup_root(file_name, files[file_name]):
			return false
	return true




func create_backup() -> Dictionary:
	var timestamp := Time.get_datetime_string_from_system(false, true)
	timestamp = timestamp.replace(":", "-").replace(" ", "_")
	var relative_directory := _unique_backup_directory("user://backups/%s" % timestamp)
	var absolute_directory := ProjectSettings.globalize_path(relative_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return {
			"success": false,
			"message": "Der Sicherungsordner konnte nicht erstellt werden.",
		}

	var copied := 0
	var copy_failed := false
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
		else:
			copy_failed = true

	if copy_failed:
		return {
			"success": false,
			"path": absolute_directory,
			"message": "Die Datensicherung konnte nicht vollständig erstellt werden.",
		}

	if copied == 0:
		return {
			"success": false,
			"nothing_to_backup": true,
			"message": "Es wurden noch keine Daten zum Sichern gefunden.",
		}

	return {
		"success": true,
		"path": absolute_directory,
		"message": "%d Datendateien wurden gesichert." % copied,
	}


func restore_backup(directory_path: String) -> Dictionary:
	var backup_directory := _normalize_backup_directory(directory_path)
	if backup_directory.is_empty():
		return {
			"success": false,
			"message": "Bitte wähle eine Sicherung aus dem Backup-Ordner.",
		}

	var valid_files: Array[String] = []
	for target_path: String in DATA_FILES:
		var source_path := "%s/%s" % [backup_directory, target_path.get_file()]
		if not FileAccess.file_exists(source_path):
			continue
		var source_file := FileAccess.open(source_path, FileAccess.READ)
		var parser := JSON.new()
		if (
			source_file == null
			or parser.parse(source_file.get_as_text()) != OK
			or not is_valid_backup_root(target_path.get_file(), parser.data)
		):
			return {
				"success": false,
				"message": "Die ausgewählte Sicherung enthält eine ungültige Datendatei.",
			}
		valid_files.append(target_path)

	if valid_files.is_empty():
		return {
			"success": false,
			"message": "Im ausgewählten Ordner wurden keine Sicherungsdaten gefunden.",
		}

	var safety_backup := create_backup()
	if not bool(safety_backup.get("success", false)) and _has_current_data():
		return {
			"success": false,
			"message": "Vor der Wiederherstellung konnte keine Sicherheitssicherung erstellt werden.",
		}

	for target_path: String in valid_files:
		var source_path := "%s/%s" % [backup_directory, target_path.get_file()]
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source_path),
			ProjectSettings.globalize_path(target_path)
		)
		if copy_error != OK:
			return {
				"success": false,
				"message": "Die Sicherung konnte nicht vollständig wiederhergestellt werden.",
			}

	return {
		"success": true,
		"safety_backup_path": str(safety_backup.get("path", "")),
		"message": "%d Datendateien wurden wiederhergestellt." % valid_files.size(),
	}


func _has_current_data() -> bool:
	for path: String in DATA_FILES:
		if FileAccess.file_exists(path):
			return true
	return false


func _rollback_sync_import(
	written_files: Array[String],
	safety_backup: Dictionary
) -> void:
	var backup_directory := str(safety_backup.get("path", ""))
	for target_path: String in written_files:
		var backup_path := "%s/%s" % [backup_directory, target_path.get_file()]
		if not backup_directory.is_empty() and FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(
				ProjectSettings.globalize_path(backup_path),
				ProjectSettings.globalize_path(target_path)
			)
		elif FileAccess.file_exists(target_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(target_path))


func _cleanup_sync_staging(staging_directory: String) -> void:
	for target_path: String in DATA_FILES:
		var staging_path := "%s/%s" % [
			staging_directory,
			target_path.get_file(),
		]
		if FileAccess.file_exists(staging_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(staging_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(staging_directory))


func _unique_backup_directory(base_path: String) -> String:
	var candidate := base_path
	var suffix := 2
	while DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(candidate)):
		candidate = "%s-%d" % [base_path, suffix]
		suffix += 1
	return candidate


func _normalize_backup_directory(directory_path: String) -> String:
	var clean_input := directory_path.strip_edges()
	if clean_input.is_empty():
		return ""

	var absolute_input := (
		ProjectSettings.globalize_path(clean_input)
		if clean_input.begins_with("user://")
		else clean_input
	)
	absolute_input = absolute_input.replace("\\", "/").simplify_path().trim_suffix("/")
	var absolute_backup_root := ProjectSettings.globalize_path("user://backups")
	absolute_backup_root = absolute_backup_root.replace("\\", "/").simplify_path().trim_suffix("/")
	var required_prefix := "%s/" % absolute_backup_root
	if not absolute_input.to_lower().begins_with(required_prefix.to_lower()):
		return ""

	var relative_name := absolute_input.substr(required_prefix.length())
	if relative_name.is_empty() or relative_name.contains("/"):
		return ""
	return "user://backups/%s" % relative_name


static func is_valid_backup_root(file_name: String, data: Variant) -> bool:
	match file_name:
		"budget_data.json", "month_history.json", "transactions.json", \
		"shopping.json", "meal_plans.json":
			return data is Dictionary
		"fixed_costs.json", "savings_goals.json", "custom_recipes.json":
			return data is Array
		_:
			return false


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
