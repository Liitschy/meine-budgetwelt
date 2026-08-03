extends Control

const MAIN_SCENE_PATH := "res://app/Main.tscn"
const WORLD_IMAGE := preload("res://assets/space/cosmic-star-atlas-background.png")
const STAGE_TITLES := ["Daten", "Konto", "Updates", "Oberfläche", "Startbereit"]

var progress_bar: ProgressBar
var percent_label: Label
var status_label: Label
var detail_label: Label
var stage_markers: Array[Label] = []
var stage_labels: Array[Label] = []
var glass_panel: PanelContainer
var panel_center: CenterContainer
var continue_button: Button
var _update_result: Dictionary = {}
var _download_result: Dictionary = {}
var _waiting_for_update_check := false
var _waiting_for_download := false
var _update_handoff_started := false


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_min_size(Vector2i(960, 640))
	_build_interface()
	resized.connect(_apply_layout)
	_apply_layout()
	UpdateManager.update_check_finished.connect(_on_boot_update_check_finished)
	UpdateManager.update_download_status.connect(_on_boot_update_download_status)
	UpdateManager.update_download_progress.connect(_on_boot_update_download_progress)
	if OS.get_environment("BUDGETWELT_BOOT_PREVIEW") == "1":
		call_deferred("_show_visual_preview")
	else:
		call_deferred("_run_startup")


func _build_interface() -> void:
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = WORLD_IMAGE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#090b13d1")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var screen_scroll := ScrollContainer.new()
	screen_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_scroll.follow_focus = true
	add_child(screen_scroll)

	panel_center = CenterContainer.new()
	panel_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	screen_scroll.add_child(panel_center)

	glass_panel = PanelContainer.new()
	glass_panel.add_theme_stylebox_override("panel", _panel_style())
	panel_center.add_child(glass_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	glass_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	margin.add_child(column)

	var wordmark := Label.new()
	wordmark.text = "✦  MEINE BUDGETWELT"
	wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wordmark.add_theme_color_override("font_color", Color("#e7c982"))
	wordmark.add_theme_font_size_override("font_size", 16)
	column.add_child(wordmark)

	var title := Label.new()
	title.name = "Title"
	title.text = "Deine Budgetwelt wird vorbereitet"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#fff4d9"))
	title.add_theme_font_override("font", _serif_font())
	title.add_theme_font_size_override("font_size", 31)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)

	var version := Label.new()
	version.text = "Version %s" % UpdateManager.get_current_version()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", Color("#b9a9ad"))
	version.add_theme_font_size_override("font_size", 14)
	column.add_child(version)

	status_label = Label.new()
	status_label.text = "Start wird vorbereitet …"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color("#e8eee7"))
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	column.add_child(progress_row)

	progress_bar = ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size.y = 16
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _bar_style(Color("#211923d9")))
	progress_bar.add_theme_stylebox_override("fill", _bar_style(Color("#e4c99a")))
	progress_row.add_child(progress_bar)

	percent_label = Label.new()
	percent_label.custom_minimum_size.x = 52
	percent_label.text = "0 %"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent_label.add_theme_color_override("font_color", Color("#e7c982"))
	percent_label.add_theme_font_size_override("font_size", 15)
	progress_row.add_child(percent_label)

	var stages := GridContainer.new()
	stages.columns = 5
	stages.add_theme_constant_override("h_separation", 6)
	column.add_child(stages)
	for stage_title: String in STAGE_TITLES:
		var stage := VBoxContainer.new()
		stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stage.add_theme_constant_override("separation", 3)
		stages.add_child(stage)
		var marker := Label.new()
		marker.text = "○"
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_theme_color_override("font_color", Color("#9c858a"))
		marker.add_theme_font_size_override("font_size", 19)
		stage.add_child(marker)
		stage_markers.append(marker)
		var label := Label.new()
		label.text = stage_title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#aa949a"))
		label.add_theme_font_size_override("font_size", 12)
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		stage.add_child(label)
		stage_labels.append(label)

	detail_label = Label.new()
	detail_label.text = "Lokale Daten bleiben bei Updates erhalten."
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_color_override("font_color", Color("#a48e94"))
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail_label)

	continue_button = Button.new()
	continue_button.text = "Trotzdem zur App"
	continue_button.custom_minimum_size.y = 44
	continue_button.visible = false
	continue_button.add_theme_color_override("font_color", Color("#1a1117"))
	continue_button.add_theme_stylebox_override("normal", _button_style(Color("#e4c99a")))
	continue_button.add_theme_stylebox_override("hover", _button_style(Color("#f0d8ad")))
	continue_button.pressed.connect(_load_main_scene)
	column.add_child(continue_button)


func _apply_layout() -> void:
	if not is_instance_valid(glass_panel):
		return
	var viewport_size := size
	panel_center.custom_minimum_size = viewport_size
	var panel_width := minf(760.0, maxf(viewport_size.x - 24.0, 260.0))
	var panel_height := minf(450.0, maxf(viewport_size.y - 36.0, 400.0))
	glass_panel.custom_minimum_size = Vector2(panel_width, panel_height)
	var title := glass_panel.find_child("Title", true, false) as Label
	if is_instance_valid(title):
		title.add_theme_font_size_override("font_size", 25 if panel_width < 520.0 else 31)
	for index in stage_labels.size():
		var label := stage_labels[index]
		label.text = (
			["Daten", "Konto", "Updates", "Ansicht", "Bereit"][index]
			if panel_width < 520.0
			else STAGE_TITLES[index]
		)
		label.add_theme_font_size_override("font_size", 10 if panel_width < 520.0 else 12)


func _run_startup() -> void:
	_set_stage(0, "active")
	_set_progress(5.0, "Lokale Budgetdaten werden geprüft …")
	await get_tree().process_frame
	var snapshot := StorageManager.export_sync_snapshot()
	if not StorageManager.is_valid_sync_snapshot(snapshot):
		_show_recoverable_error("Die lokalen Budgetdaten konnten nicht validiert werden.")
		return
	_set_progress(18.0, "Lokale Budgetdaten sind bereit.")
	_set_stage(0, "done")

	_set_stage(1, "active")
	_set_progress(22.0, "Konto und Synchronisation werden geprüft …")
	var session_result := await SyncManager.restore_session()
	if bool(session_result.get("success", false)):
		_set_progress(35.0, "Konto ist angemeldet und synchronisiert.")
		_set_stage(1, "done")
	else:
		_set_progress(35.0, "Keine aktive Anmeldung – Anmeldung folgt in der App.")
		_set_stage(1, "skipped")

	_set_stage(2, "active")
	if OS.has_feature("web"):
		UpdateManager.startup_check_completed = true
		_set_progress(63.0, "PWA-Updates werden sicher über den Server bereitgestellt.")
		_set_stage(2, "done")
	else:
		await _run_update_check()
		if _update_handoff_started:
			return

	await _load_main_scene()


func _run_update_check() -> void:
	_set_progress(40.0, "Der sichere Updatekanal wird geprüft …")
	_update_result = {}
	_waiting_for_update_check = true
	UpdateManager.check_for_updates()
	while _waiting_for_update_check:
		await get_tree().process_frame
	UpdateManager.startup_check_completed = true
	var status := str(_update_result.get("status", "error"))
	if status != "update_available":
		_set_progress(63.0, str(_update_result.get("message", "Updateprüfung beendet. Die App kann normal verwendet werden.")))
		_set_stage(2, "done" if status == "up_to_date" else "skipped")
		return

	var version := str(_update_result.get("version", ""))
	var download_url := str(_update_result.get("download_url", ""))
	var sha256_url := str(_update_result.get("sha256_url", ""))
	if not UpdateManager.can_install_automatically():
		_set_progress(63.0, "Version %s ist verfügbar und kann in der App installiert werden." % version)
		_set_stage(2, "skipped")
		return

	_waiting_for_download = true
	_download_result = {}
	detail_label.text = "Download, SHA-256-Prüfung und Datensicherung laufen automatisch."
	UpdateManager.download_update(version, download_url, sha256_url)
	while _waiting_for_download:
		await get_tree().process_frame
	var download_status := str(_download_result.get("status", "error"))
	if download_status != "ready":
		_set_progress(63.0, str(_download_result.get("message", "Das Update konnte nicht vorbereitet werden.")))
		_set_stage(2, "skipped")
		return

	_set_progress(78.0, "Der Installer wurde sicher geprüft. Daten werden gesichert …")
	var backup := StorageManager.create_backup()
	var backup_ready := bool(backup.get("success", false)) or bool(backup.get("nothing_to_backup", false))
	if not backup_ready:
		_set_progress(63.0, "Das Update wurde wegen einer fehlgeschlagenen Datensicherung nicht gestartet.")
		_set_stage(2, "skipped")
		return

	_set_progress(84.0, "Update wird installiert. Die App startet danach automatisch neu …")
	_set_stage(2, "done")
	var installer_path := str(_download_result.get("installer_path", ""))
	if UpdateManager.launch_verified_installer(installer_path, true):
		_update_handoff_started = true
		get_tree().quit()
		return
	_set_progress(63.0, "Der geprüfte Installer konnte nicht gestartet werden.")
	_set_stage(2, "skipped")


func _load_main_scene() -> void:
	continue_button.visible = false
	_set_stage(3, "active")
	_set_progress(86.0, "Die Oberfläche wird geladen …")
	var request_error := ResourceLoader.load_threaded_request(MAIN_SCENE_PATH)
	if request_error != OK:
		_show_recoverable_error("Die Hauptoberfläche konnte nicht vorbereitet werden.")
		return
	var threaded_progress: Array = []
	while true:
		var load_status := ResourceLoader.load_threaded_get_status(MAIN_SCENE_PATH, threaded_progress)
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_show_recoverable_error("Die Hauptoberfläche konnte nicht geladen werden.")
			return
		var resource_progress := float(threaded_progress[0]) if not threaded_progress.is_empty() else 0.0
		_set_progress(86.0 + resource_progress * 12.0, "Die Oberfläche wird geladen …")
		await get_tree().process_frame

	var packed := ResourceLoader.load_threaded_get(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		_show_recoverable_error("Die Hauptoberfläche ist nicht verfügbar.")
		return
	_set_stage(3, "done")
	_set_stage(4, "active")
	_set_progress(100.0, "Alles bereit – willkommen in deiner Budgetwelt.")
	_set_stage(4, "done")
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_packed(packed)


func _on_boot_update_check_finished(result: Dictionary) -> void:
	if not _waiting_for_update_check:
		return
	_update_result = result.duplicate(true)
	_waiting_for_update_check = false


func _on_boot_update_download_status(result: Dictionary) -> void:
	if not _waiting_for_download:
		return
	var status := str(result.get("status", ""))
	status_label.text = str(result.get("message", "Update wird vorbereitet …"))
	if status in ["ready", "error", "busy"]:
		_download_result = result.duplicate(true)
		_waiting_for_download = false


func _on_boot_update_download_progress(value: float) -> void:
	if _waiting_for_download and value >= 0.0:
		_set_progress(48.0 + clampf(value, 0.0, 1.0) * 27.0, "Der sichere Installer wird heruntergeladen …")


func _show_recoverable_error(message: String) -> void:
	status_label.text = message
	detail_label.text = "Deine vorhandenen Daten wurden nicht verändert."
	continue_button.visible = true


func _show_visual_preview() -> void:
	_set_stage(0, "done")
	_set_stage(1, "done")
	_set_stage(2, "active")
	_set_progress(49.0, "Updates werden sicher geprüft …")
	detail_label.text = "Release-Kanal, Prüfsumme und Installer werden kontrolliert."


func _set_progress(value: float, message: String) -> void:
	progress_bar.value = clampf(value, 0.0, 100.0)
	percent_label.text = "%d %%" % roundi(progress_bar.value)
	status_label.text = message


func _set_stage(index: int, state: String) -> void:
	if index < 0 or index >= stage_markers.size():
		return
	var marker := stage_markers[index]
	var label := stage_labels[index]
	match state:
		"active":
			marker.text = "◉"
			marker.add_theme_color_override("font_color", Color("#e4c99a"))
			label.add_theme_color_override("font_color", Color("#f4e6bf"))
		"done":
			marker.text = "✓"
			marker.add_theme_color_override("font_color", Color("#e4c99a"))
			label.add_theme_color_override("font_color", Color("#e8d7c8"))
		"skipped":
			marker.text = "—"
			marker.add_theme_color_override("font_color", Color("#d9aa5d"))
			label.add_theme_color_override("font_color", Color("#d9c28e"))


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#17131ff0")
	style.border_color = Color("#b8734b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(25)
	style.shadow_color = Color("#00000099")
	style.shadow_size = 22
	return style


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := _bar_style(color)
	style.set_corner_radius_all(12)
	return style


func _serif_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "serif"])
	return font
