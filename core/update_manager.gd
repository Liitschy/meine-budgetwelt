extends Node

signal update_check_finished(result: Dictionary)

var _request: HTTPRequest


func _ready() -> void:
	_request = HTTPRequest.new()
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)


func get_current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func is_configured() -> bool:
	return not get_manifest_url().is_empty()


func get_manifest_url() -> String:
	return str(ProjectSettings.get_setting("application_update/manifest_url", "")).strip_edges()


func check_for_updates() -> void:
	if not is_configured():
		update_check_finished.emit({
			"status": "not_configured",
			"message": "Die Update-Quelle wird vor der ersten Veröffentlichung eingerichtet.",
		})
		return

	var error := _request.request(get_manifest_url())
	if error != OK:
		update_check_finished.emit({
			"status": "error",
			"message": "Die Update-Prüfung konnte nicht gestartet werden.",
		})


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_check_finished.emit({
			"status": "error",
			"message": "Die Update-Quelle ist momentan nicht erreichbar.",
		})
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary or not parsed.has("version"):
		update_check_finished.emit({
			"status": "error",
			"message": "Die Update-Informationen sind ungültig.",
		})
		return

	var remote_version := str(parsed.version)
	var available := _is_newer_version(remote_version, get_current_version())
	update_check_finished.emit({
		"status": "update_available" if available else "up_to_date",
		"version": remote_version,
		"download_url": str(parsed.get("download_url", "")),
		"message": (
			"Version %s ist verfügbar." % remote_version
			if available
			else "Die Anwendung ist aktuell."
		),
	})


func _is_newer_version(candidate: String, current: String) -> bool:
	var candidate_parts := candidate.split(".")
	var current_parts := current.split(".")
	var length := maxi(candidate_parts.size(), current_parts.size())

	for index in length:
		var candidate_part := int(candidate_parts[index]) if index < candidate_parts.size() else 0
		var current_part := int(current_parts[index]) if index < current_parts.size() else 0
		if candidate_part != current_part:
			return candidate_part > current_part

	return false

