extends Node

signal update_check_finished(result: Dictionary)
signal update_download_status(result: Dictionary)

const RELEASE_BASE_URL := "https://github.com/unique1986/meine-budgetwelt/releases/download/"
const INSTALLER_NAME_TEMPLATE := "Meine-Budgetwelt-Setup-%s.exe"
const UPDATE_DIRECTORY := "user://updates"
const AUTOMATIC_UPDATE_SCRIPT := "user://updates/Install-VerifiedUpdate.ps1"
const AUTOMATIC_UPDATE_LOG := "user://updates/client-update.log"
const AUTOMATIC_UPDATE_SCRIPT_CONTENTS := """param(
    [Parameter(Mandatory = $true)][int]$ParentProcessId,
    [Parameter(Mandatory = $true)][string]$InstallerPath,
    [Parameter(Mandatory = $true)][string]$ApplicationPath,
    [Parameter(Mandatory = $true)][string]$LogPath
)

$ErrorActionPreference = 'Stop'

function Write-UpdateLog {
    param([string]$Message)
    $timestamp = [DateTimeOffset]::Now.ToString('o')
    Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value ("{0} {1}" -f $timestamp, $Message)
}

try {
    Write-UpdateLog 'Waiting for the application to close.'
    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        if ($null -eq (Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue)) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($null -ne (Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue)) {
        throw 'The application did not close within 60 seconds.'
    }

    Write-UpdateLog 'Starting the verified installer.'
    $setup = Start-Process -FilePath $InstallerPath -ArgumentList @('/S') -Wait -PassThru -WindowStyle Hidden
    if ($setup.ExitCode -ne 0) {
        throw ("The installer returned exit code {0}." -f $setup.ExitCode)
    }
    if (-not (Test-Path -LiteralPath $ApplicationPath -PathType Leaf)) {
        throw 'The installed application executable is missing.'
    }

    Write-UpdateLog 'Update completed; restarting the application.'
    Start-Process -FilePath $ApplicationPath -WorkingDirectory (Split-Path -Parent $ApplicationPath)
    Start-Sleep -Seconds 2
    Remove-Item -LiteralPath $InstallerPath -Force -ErrorAction SilentlyContinue
    exit 0
}
catch {
    Write-UpdateLog ("Update failed: {0}" -f $_.Exception.Message)
    if (Test-Path -LiteralPath $ApplicationPath -PathType Leaf) {
        Start-Process -FilePath $ApplicationPath -WorkingDirectory (Split-Path -Parent $ApplicationPath)
    }
    exit 1
}
"""

var _manifest_request: HTTPRequest
var _download_request: HTTPRequest
var _checking := false
var _download_stage := ""
var _pending_update: Dictionary = {}
var _expected_sha256 := ""
var _verified_installer_path := ""


func _ready() -> void:
	_manifest_request = HTTPRequest.new()
	_manifest_request.timeout = 6.0
	add_child(_manifest_request)
	_manifest_request.request_completed.connect(_on_manifest_request_completed)

	_download_request = HTTPRequest.new()
	_download_request.timeout = 120.0
	add_child(_download_request)
	_download_request.request_completed.connect(_on_download_request_completed)


func get_current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func is_configured() -> bool:
	return not get_manifest_url().is_empty()


func get_manifest_url() -> String:
	return str(ProjectSettings.get_setting("application_update/manifest_url", "")).strip_edges()


func check_for_updates() -> void:
	if _checking:
		return
	if not is_configured():
		update_check_finished.emit({
			"status": "not_configured",
			"message": "Die Update-Quelle wird vor der ersten Veröffentlichung eingerichtet.",
		})
		return

	var error := _manifest_request.request(get_manifest_url())
	if error != OK:
		update_check_finished.emit({
			"status": "error",
			"message": "Die Update-Prüfung konnte nicht gestartet werden.",
		})
		return
	_checking = true


func download_update(version: String, download_url: String, sha256_url: String) -> void:
	if not _download_stage.is_empty():
		update_download_status.emit({
			"status": "busy",
			"message": "Ein Update-Download läuft bereits.",
		})
		return
	if not OS.has_feature("windows"):
		_fail_download("Der Setup-Download ist nur unter Windows verfügbar.")
		return
	if not is_valid_release_urls(version, download_url, sha256_url):
		_fail_download("Die Update-Adressen sind ungültig oder gehören nicht zu diesem Projekt.")
		return

	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(UPDATE_DIRECTORY)
	)
	if directory_error != OK:
		_fail_download("Der lokale Update-Ordner konnte nicht erstellt werden.")
		return

	var installer_name := INSTALLER_NAME_TEMPLATE % version
	_pending_update = {
		"version": version,
		"download_url": download_url,
		"sha256_url": sha256_url,
		"installer_path": "%s/%s" % [UPDATE_DIRECTORY, installer_name],
		"partial_path": "%s/%s.part" % [UPDATE_DIRECTORY, installer_name],
	}
	_expected_sha256 = ""
	_verified_installer_path = ""
	_remove_file_if_present(str(_pending_update.partial_path))
	_download_stage = "checksum"
	_download_request.download_file = ""
	update_download_status.emit({
		"status": "checking_checksum",
		"message": "Die veröffentlichte SHA-256-Prüfsumme wird geladen …",
	})
	var error := _download_request.request(sha256_url)
	if error != OK:
		_fail_download("Die SHA-256-Prüfsumme konnte nicht geladen werden.")


func can_install_automatically() -> bool:
	return (
		OS.has_feature("windows")
		and not OS.has_feature("editor")
		and is_expected_installed_executable(
			OS.get_executable_path(),
			OS.get_environment("LOCALAPPDATA")
		)
	)


func launch_verified_installer(installer_path: String, automatic: bool = false) -> bool:
	if not OS.has_feature("windows") or installer_path != _verified_installer_path:
		return false
	if not installer_path.begins_with("%s/" % UPDATE_DIRECTORY):
		return false
	var absolute_path := ProjectSettings.globalize_path(installer_path)
	if not FileAccess.file_exists(absolute_path):
		return false
	var process_id := (
		_launch_automatic_installer(absolute_path)
		if automatic and can_install_automatically()
		else OS.create_process(absolute_path, PackedStringArray())
	)
	if process_id <= 0:
		return false
	_verified_installer_path = ""
	return true


func _launch_automatic_installer(installer_path: String) -> int:
	var script_path := ProjectSettings.globalize_path(AUTOMATIC_UPDATE_SCRIPT)
	var script_file := FileAccess.open(script_path, FileAccess.WRITE)
	if script_file == null:
		return -1
	script_file.store_string(AUTOMATIC_UPDATE_SCRIPT_CONTENTS)
	script_file.close()

	var system_root := OS.get_environment("SystemRoot").strip_edges()
	if system_root.is_empty():
		return -1
	var powershell_path := system_root.path_join(
		"System32/WindowsPowerShell/v1.0/powershell.exe"
	)
	if not FileAccess.file_exists(powershell_path):
		return -1

	var application_path := OS.get_executable_path()
	var log_path := ProjectSettings.globalize_path(AUTOMATIC_UPDATE_LOG)
	var arguments := PackedStringArray([
		"-NoProfile",
		"-NonInteractive",
		"-ExecutionPolicy",
		"RemoteSigned",
		"-WindowStyle",
		"Hidden",
		"-File",
		script_path,
		"-ParentProcessId",
		str(OS.get_process_id()),
		"-InstallerPath",
		installer_path,
		"-ApplicationPath",
		application_path,
		"-LogPath",
		log_path,
	])
	return OS.create_process(powershell_path, arguments)


func _on_manifest_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		var offline := result in [
			HTTPRequest.RESULT_CANT_CONNECT,
			HTTPRequest.RESULT_CANT_RESOLVE,
			HTTPRequest.RESULT_CONNECTION_ERROR,
			HTTPRequest.RESULT_TIMEOUT,
		]
		update_check_finished.emit({
			"status": "offline" if offline else "error",
			"message": (
				"Keine Internetverbindung. Die App kann normal verwendet werden."
				if offline
				else "Die Update-Quelle ist momentan nicht erreichbar."
			),
		})
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var manifest := validate_manifest(parsed)
	if not bool(manifest.get("valid", false)):
		update_check_finished.emit({
			"status": "error",
			"message": str(manifest.get("message", "Die Update-Informationen sind ungültig.")),
		})
		return

	var remote_version := str(manifest.version)
	var available := is_newer_version(remote_version, get_current_version())
	update_check_finished.emit({
		"status": "update_available" if available else "up_to_date",
		"version": remote_version,
		"download_url": str(manifest.download_url),
		"sha256_url": str(manifest.sha256_url),
		"message": (
			"Version %s ist verfügbar." % remote_version
			if available
			else "Die Anwendung ist aktuell."
		),
	})


func _on_download_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_fail_download(
			"Der Installer konnte nicht vollständig geladen werden."
			if _download_stage == "installer"
			else "Die SHA-256-Prüfsumme konnte nicht geladen werden."
		)
		return

	if _download_stage == "checksum":
		_expected_sha256 = extract_sha256(body.get_string_from_utf8())
		if _expected_sha256.is_empty():
			_fail_download("Die veröffentlichte SHA-256-Prüfsumme ist ungültig.")
			return
		_start_installer_download()
		return

	if _download_stage == "installer":
		_verify_downloaded_installer()


func _start_installer_download() -> void:
	_download_stage = "installer"
	var partial_path := str(_pending_update.partial_path)
	_download_request.download_file = ProjectSettings.globalize_path(partial_path)
	update_download_status.emit({
		"status": "downloading",
		"message": "Der geprüfte Setup-Installer wird heruntergeladen …",
	})
	var error := _download_request.request(str(_pending_update.download_url))
	if error != OK:
		_fail_download("Der Installer-Download konnte nicht gestartet werden.")


func _verify_downloaded_installer() -> void:
	var partial_path := str(_pending_update.partial_path)
	var actual_sha256 := FileAccess.get_sha256(partial_path).to_lower()
	if actual_sha256.is_empty() or actual_sha256 != _expected_sha256:
		_fail_download("Die SHA-256-Prüfung ist fehlgeschlagen. Der Download wurde verworfen.")
		return

	var installer_path := str(_pending_update.installer_path)
	_remove_file_if_present(installer_path)
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(partial_path),
		ProjectSettings.globalize_path(installer_path)
	)
	if rename_error != OK:
		_fail_download("Der geprüfte Installer konnte nicht bereitgestellt werden.")
		return

	_verified_installer_path = installer_path
	_download_stage = ""
	_download_request.download_file = ""
	var version := str(_pending_update.version)
	_pending_update = {}
	_expected_sha256 = ""
	update_download_status.emit({
		"status": "ready",
		"version": version,
		"installer_path": installer_path,
		"sha256": actual_sha256,
		"message": "Download und SHA-256-Prüfung waren erfolgreich.",
	})


func _fail_download(message: String) -> void:
	if _pending_update.has("partial_path"):
		_remove_file_if_present(str(_pending_update.partial_path))
	_download_stage = ""
	if is_instance_valid(_download_request):
		_download_request.download_file = ""
	_pending_update = {}
	_expected_sha256 = ""
	_verified_installer_path = ""
	update_download_status.emit({
		"status": "error",
		"message": message,
	})


func _remove_file_if_present(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


static func validate_manifest(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "message": "Die Update-Informationen sind ungültig."}
	var version := str(value.get("version", "")).strip_edges()
	var download_url := str(value.get("download_url", "")).strip_edges()
	var sha256_url := str(value.get("sha256_url", "")).strip_edges()
	if not is_valid_version(version):
		return {"valid": false, "message": "Die veröffentlichte Versionsnummer ist ungültig."}
	if not is_valid_release_urls(version, download_url, sha256_url):
		return {
			"valid": false,
			"message": "Die Update-Adressen sind ungültig oder gehören nicht zu diesem Projekt.",
		}
	return {
		"valid": true,
		"version": version,
		"download_url": download_url,
		"sha256_url": sha256_url,
	}


static func is_valid_release_urls(
	version: String,
	download_url: String,
	sha256_url: String
) -> bool:
	if not is_valid_version(version):
		return false
	var installer_name := INSTALLER_NAME_TEMPLATE % version
	var expected_download_url := "%sv%s/%s" % [RELEASE_BASE_URL, version, installer_name]
	return (
		download_url == expected_download_url
		and sha256_url == "%s.sha256" % expected_download_url.trim_suffix(".exe")
	)


static func extract_sha256(contents: String) -> String:
	var normalized := contents.strip_edges().replace("\t", " ")
	var parts := normalized.split(" ", false)
	if parts.is_empty():
		return ""
	var candidate := str(parts[0]).to_lower()
	return candidate if is_valid_sha256(candidate) else ""


static func file_matches_sha256(path: String, expected_sha256: String) -> bool:
	if not FileAccess.file_exists(path) or not is_valid_sha256(expected_sha256):
		return false
	return FileAccess.get_sha256(path).to_lower() == expected_sha256.to_lower()


static func is_expected_installed_executable(
	executable_path: String,
	local_app_data: String
) -> bool:
	if executable_path.strip_edges().is_empty() or local_app_data.strip_edges().is_empty():
		return false
	var actual := executable_path.replace("\\", "/").simplify_path()
	var expected := local_app_data.path_join(
		"Programs/Meine Budgetwelt/Meine-Budgetwelt.exe"
	).replace("\\", "/").simplify_path()
	return actual.nocasecmp_to(expected) == 0


static func is_valid_sha256(value: String) -> bool:
	if value.length() != 64:
		return false
	for character in value.to_lower():
		if not "0123456789abcdef".contains(character):
			return false
	return true


static func is_valid_version(version: String) -> bool:
	var parts := version.split(".")
	if parts.size() != 3:
		return false
	for part in parts:
		if part.is_empty() or not part.is_valid_int() or int(part) < 0:
			return false
	return true


static func is_newer_version(candidate: String, current: String) -> bool:
	if not is_valid_version(candidate) or not is_valid_version(current):
		return false
	var candidate_parts := candidate.split(".")
	var current_parts := current.split(".")
	for index in 3:
		var candidate_part := int(candidate_parts[index])
		var current_part := int(current_parts[index])
		if candidate_part != current_part:
			return candidate_part > current_part
	return false
