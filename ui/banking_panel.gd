extends Control

signal refresh_requested(connection_id: String)
signal import_requested(import_ids: Array[String])
signal disconnect_requested(connection_id: String)
signal connect_requested()
signal balance_adoption_requested(account_reference: String)
signal manual_view_requested()

const COLORS := {
	"panel": Color("#15111bed"),
	"panel_soft": Color("#211923ee"),
	"card": Color("#19141ef2"),
	"accent": Color("#e4c99a"),
	"gold": Color("#b8734b"),
	"text": Color("#f5eadb"),
	"muted": Color("#b9a9ad"),
	"success": Color("#a9c493"),
	"warning": Color("#d18a65"),
	"danger": Color("#c47878"),
}

var _compact := false
var _data: Dictionary = {}
var _status: Dictionary = {"enabled": false}
var _connections: Array = []
var _active_connection: Dictionary = {}
var _selected: Dictionary = {}
var _busy := false
var _message := ""
var _message_kind := "info"
var _status_received := false
var _display_font := SystemFont.new()
var _content_margin: MarginContainer
var _scroll: ScrollContainer


func _ready() -> void:
	name = "BankingPanel"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_display_font.font_names = PackedStringArray(["Georgia", "Palatino Linotype"])
	_rebuild()


func set_compact(compact: bool) -> void:
	if _compact == compact and is_instance_valid(_content_margin):
		return
	_compact = compact
	_rebuild()


func set_data(data: Dictionary) -> void:
	_data = data.duplicate(true)
	if not _status_received:
		_status.enabled = true
	var connection_id := str(_data.get("connectionId", ""))
	if not connection_id.is_empty():
		if str(_active_connection.get("id", "")) != connection_id:
			_active_connection = {
				"id": connection_id,
				"institutionName": str(_data.get("institutionName", "Bank")),
				"status": "linked",
			}
		else:
			_active_connection["institutionName"] = str(_data.get(
				"institutionName",
				_active_connection.get("institutionName", "Bank")
			))
	_selected.clear()
	for raw_item: Variant in _data.get("transactions", []):
		if raw_item is Dictionary and _is_importable(raw_item):
			_selected[str(raw_item.get("importId", ""))] = true
	_rebuild()


func set_status(status: Dictionary) -> void:
	_status_received = true
	_status = status.duplicate(true)
	_rebuild()


func set_connections(connections: Array) -> void:
	_connections = connections.duplicate(true)
	if _connections.is_empty():
		_active_connection.clear()
		_data.clear()
	else:
		var active_id := str(_active_connection.get("id", ""))
		_active_connection = {}
		for raw_connection: Variant in _connections:
			if raw_connection is Dictionary and (
				active_id.is_empty() or str(raw_connection.get("id", "")) == active_id
			):
				_active_connection = raw_connection.duplicate(true)
				break
		if _active_connection.is_empty() and _connections[0] is Dictionary:
			_active_connection = (_connections[0] as Dictionary).duplicate(true)
		if str(_data.get("connectionId", "")) != str(_active_connection.get("id", "")):
			_data = {
				"connectionId": str(_active_connection.get("id", "")),
				"institutionName": str(_active_connection.get("institutionName", "Bank")),
				"balances": [],
				"transactions": [],
			}
	_rebuild()


func set_busy(busy: bool, message: String = "") -> void:
	_busy = busy
	if not message.is_empty():
		_message = message
		_message_kind = "info"
	_rebuild()


func set_message(message: String, kind: String = "info") -> void:
	_message = message
	_message_kind = kind
	_busy = false
	_rebuild()


func get_selected_import_ids() -> Array[String]:
	var result: Array[String] = []
	for import_id: String in _selected:
		if bool(_selected[import_id]):
			result.append(import_id)
	return result


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var background := TextureRect.new()
	background.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color("#090b1399")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scroll)
	_content_margin = MarginContainer.new()
	_content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_margin.add_theme_constant_override("margin_left", 14 if _compact else 42)
	_content_margin.add_theme_constant_override("margin_right", 14 if _compact else 42)
	_content_margin.add_theme_constant_override("margin_top", 16 if _compact else 28)
	_content_margin.add_theme_constant_override("margin_bottom", 104 if _compact else 34)
	_scroll.add_child(_content_margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	_content_margin.add_child(content)
	content.add_child(_build_header())
	content.add_child(_build_section_tabs())
	content.add_child(_build_security_card())
	if not _message.is_empty():
		content.add_child(_build_message_card())
	if not bool(_status.get("enabled", false)):
		content.add_child(_build_unavailable_card())
	elif _active_connection.is_empty():
		content.add_child(_build_empty_connection_card())
	else:
		content.add_child(_build_connection_card())
		content.add_child(_build_metrics())
		content.add_child(_build_transactions_card())
	content.add_child(_build_new_connection_card())


func _build_header() -> Control:
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 10)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Bankimport"
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 32 if _compact else 42)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Kontostände und Buchungen sicher prüfen und bewusst übernehmen"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(subtitle)
	row.add_child(titles)
	var provider := Label.new()
	provider.text = str(_status.get("provider", "Enable Banking"))
	provider.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	provider.add_theme_color_override("font_color", COLORS.gold)
	row.add_child(provider)
	return row


func _build_section_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#15111bdd"), 15, Color("#6d5835")))
	var row := BoxContainer.new()
	row.vertical = false
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for definition in [["Manuell", false], ["Bankimport", true]]:
		var button := Button.new()
		button.text = str(definition[0])
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		if bool(definition[1]):
			button.add_theme_color_override("font_color", Color("#1a1117"))
			button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
		else:
			button.pressed.connect(manual_view_requested.emit)
		row.add_child(button)
	return panel


func _build_message_card() -> Control:
	var color: Color = (
		COLORS.success if _message_kind == "success"
		else COLORS.danger if _message_kind == "error"
		else COLORS.gold
	)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(color, 0.12), 13, Color(color, 0.65)))
	var label := Label.new()
	label.text = ("Bitte warten …  " if _busy else "") + _message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	return panel


func _build_unavailable_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#8a6a36")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Bankanbindung noch nicht auf dem Server aktiviert"
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var detail := Label.new()
	detail.text = "Die manuellen Buchungen funktionieren unverändert. Für den Bankimport werden ausschließlich auf dem Budgetwelt-Server die Enable-Banking-App-ID und der geschützte private Schlüssel eingerichtet."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(detail)
	return panel


func _build_empty_connection_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#8a6a36")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Noch keine Bank verbunden"
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var detail := Label.new()
	detail.text = "Wähle deine Bank aus. Die Anmeldung und Freigabe erfolgen anschließend direkt bei deiner Bank im Browser."
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(detail)
	var button := Button.new()
	button.text = "+  Erste Bank auswählen"
	button.custom_minimum_size.y = 48
	button.disabled = _busy
	button.add_theme_color_override("font_color", Color("#1a1117"))
	button.add_theme_stylebox_override("normal", _style(COLORS.accent, 13, COLORS.gold))
	button.pressed.connect(connect_requested.emit)
	column.add_child(button)
	return panel


func _build_security_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#211923e8"), 16, Color("#b8734baa")))
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var shield := Label.new()
	shield.text = "✓"
	shield.custom_minimum_size = Vector2(48, 48)
	shield.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shield.add_theme_font_size_override("font_size", 28)
	shield.add_theme_color_override("font_color", COLORS.accent)
	row.add_child(shield)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Ausschließlich lesend"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", COLORS.text)
	copy.add_child(title)
	var text_label := Label.new()
	text_label.text = "Kein PIN- oder TAN-Speichern · keine Überweisungen · Aktualisierung nur auf Knopfdruck"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", COLORS.muted)
	copy.add_child(text_label)
	row.add_child(copy)
	var badge := _badge("KEINE ZAHLUNGEN", COLORS.success)
	row.add_child(badge)
	return panel


func _build_connection_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#8a6a36")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bank := Label.new()
	bank.text = str(_active_connection.get(
		"institutionName",
		_data.get("institutionName", "Bank")
	))
	bank.add_theme_font_override("font", _display_font)
	bank.add_theme_font_size_override("font_size", 24)
	bank.add_theme_color_override("font_color", COLORS.text)
	identity.add_child(bank)
	var meta := Label.new()
	var account_reference := ""
	var balances: Array = _data.get("balances", [])
	if not balances.is_empty() and balances[0] is Dictionary:
		account_reference = str(balances[0].get("accountReference", ""))
	var last_refresh := str(_active_connection.get("lastRefreshUtc", "")).strip_edges()
	meta.text = (
		("Konto %s" % account_reference if not account_reference.is_empty() else "Bankfreigabe vorhanden")
		+ (" · noch nicht abgerufen" if last_refresh.is_empty() else " · zuletzt manuell aktualisiert")
	)
	meta.add_theme_color_override("font_color", COLORS.muted)
	identity.add_child(meta)
	row.add_child(identity)
	var connection_status := str(_active_connection.get("status", "linked")).to_lower()
	row.add_child(_badge(
		"VERBUNDEN" if connection_status in ["linked", "ln"] else connection_status.to_upper(),
		COLORS.success if connection_status in ["linked", "ln"] else COLORS.warning
	))
	var refresh := Button.new()
	refresh.text = (
		"↻  Bank aktualisieren"
		if connection_status in ["linked", "ln"]
		else "↻  Freigabe prüfen"
	)
	refresh.custom_minimum_size.y = 44
	refresh.disabled = _busy or connection_status in ["expired", "rejected"]
	refresh.add_theme_color_override("font_color", Color("#1a1117"))
	refresh.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
	refresh.pressed.connect(refresh_requested.emit.bind(str(_active_connection.get("id", ""))))
	row.add_child(refresh)
	var disconnect_button := Button.new()
	disconnect_button.text = "Trennen"
	disconnect_button.custom_minimum_size.y = 44
	disconnect_button.disabled = _busy
	disconnect_button.pressed.connect(disconnect_requested.emit.bind(str(_active_connection.get("id", ""))))
	row.add_child(disconnect_button)
	var hint := Label.new()
	hint.text = "Der Abruf startet nie automatisch. Vor der Übernahme siehst du jede Buchung in dieser Vorschau."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)
	return panel


func _build_metrics() -> Control:
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 10)
	var balances: Array = _data.get("balances", [])
	var balance := float(balances[0].get("amount", 0.0)) if not balances.is_empty() and balances[0] is Dictionary else 0.0
	var new_count := 0
	var duplicate_count := 0
	for raw_item: Variant in _data.get("transactions", []):
		if not raw_item is Dictionary:
			continue
		if bool(raw_item.get("alreadyImported", false)):
			duplicate_count += 1
		elif _is_importable(raw_item):
			new_count += 1
	row.add_child(_metric_card("Gemeldeter Kontostand", _money(balance), COLORS.accent))
	row.add_child(_metric_card("Neue Buchungen", str(new_count), COLORS.success))
	row.add_child(_metric_card("Bereits vorhanden", str(duplicate_count), COLORS.warning))
	return row


func _build_transactions_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#705a35")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	var title_row := BoxContainer.new()
	title_row.vertical = _compact
	var title := Label.new()
	title.text = "Buchungen zur Übernahme"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLORS.text)
	title_row.add_child(title)
	var state := Label.new()
	state.text = "Noch nichts importiert"
	state.add_theme_color_override("font_color", COLORS.gold)
	title_row.add_child(state)
	column.add_child(title_row)
	var transactions: Array = _data.get("transactions", [])
	if transactions.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Bankdaten abgerufen. Starte die Aktualisierung bewusst über ‚Bank aktualisieren‘."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		column.add_child(empty)
	for raw_item: Variant in transactions:
		if raw_item is Dictionary:
			column.add_child(_transaction_row(raw_item))
	var footer := BoxContainer.new()
	footer.vertical = _compact
	footer.add_theme_constant_override("separation", 10)
	var note := Label.new()
	note.text = "Vorgemerkte und bereits importierte Buchungen sind nicht auswählbar."
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", COLORS.muted)
	footer.add_child(note)
	var import_button := Button.new()
	import_button.text = "Ausgewählte Buchungen übernehmen"
	import_button.custom_minimum_size.y = 48
	import_button.disabled = _busy or get_selected_import_ids().is_empty()
	import_button.add_theme_color_override("font_color", Color("#1a1117"))
	import_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 13, COLORS.gold))
	import_button.pressed.connect(func() -> void:
		import_requested.emit(get_selected_import_ids())
	)
	footer.add_child(import_button)
	column.add_child(footer)
	return panel


func _transaction_row(item: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.card, 13, Color("#8a6a5c66")))
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var import_id := str(item.get("importId", ""))
	var selectable := _is_importable(item)
	var check := CheckBox.new()
	check.button_pressed = selectable and bool(_selected.get(import_id, false))
	check.disabled = not selectable
	check.custom_minimum_size = Vector2(42, 42)
	check.toggled.connect(func(enabled: bool) -> void:
		_selected[import_id] = enabled
	)
	row.add_child(check)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var description := Label.new()
	description.text = str(item.get("description", "Buchung"))
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", COLORS.text)
	copy.add_child(description)
	var meta := Label.new()
	meta.text = "%s · Konto %s" % [str(item.get("bookingDate", "")), str(item.get("accountReference", "••••"))]
	meta.add_theme_color_override("font_color", COLORS.muted)
	copy.add_child(meta)
	row.add_child(copy)
	if bool(item.get("alreadyImported", false)):
		row.add_child(_badge("BEREITS VORHANDEN", COLORS.warning))
	elif str(item.get("status", "")).to_lower() != "booked":
		row.add_child(_badge("VORGEMERKT", COLORS.muted))
	var amount := Label.new()
	amount.text = ("+" if str(item.get("kind", "")) == "income" else "−") + _money(float(item.get("amount", 0.0)))
	amount.custom_minimum_size.x = 110 if not _compact else 0
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.add_theme_font_size_override("font_size", 18)
	amount.add_theme_color_override("font_color", COLORS.success if str(item.get("kind", "")) == "income" else COLORS.danger)
	row.add_child(amount)
	return panel


func _build_new_connection_card() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#15111bdd"), 16, Color("#5e5948")))
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Weitere Bank verbinden"
	title.add_theme_color_override("font_color", COLORS.text)
	copy.add_child(title)
	var note := Label.new()
	note.text = "Die Freigabe erfolgt direkt bei deiner Bank im Browser."
	note.add_theme_color_override("font_color", COLORS.muted)
	copy.add_child(note)
	row.add_child(copy)
	var connect_button := Button.new()
	connect_button.text = "+  Bank auswählen"
	connect_button.custom_minimum_size.y = 44
	connect_button.disabled = _busy or not bool(_status.get("enabled", false))
	connect_button.pressed.connect(connect_requested.emit)
	row.add_child(connect_button)
	return panel


func _metric_card(title_text: String, value_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("#19141ee8"), 15, Color(color, 0.55)))
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(title)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_override("font", _display_font)
	value.add_theme_font_size_override("font_size", 24)
	value.add_theme_color_override("font_color", color)
	column.add_child(value)
	return panel


func _badge(text_value: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _style(Color(color, 0.12), 12, Color(color, 0.65)))
	var label := Label.new()
	label.text = "  %s  " % text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	return panel


static func _is_importable(item: Dictionary) -> bool:
	return (
		not bool(item.get("alreadyImported", false))
		and str(item.get("status", "")).to_lower() == "booked"
		and str(item.get("currency", "")).to_upper() == "EUR"
		and str(item.get("kind", "")).to_lower() in ["income", "expense"]
	)


static func _money(value: float) -> String:
	return ("%.2f €" % value).replace(".", ",")


static func _style(fill: Color, radius: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	if fill.a > 0.15 and radius >= 12:
		style.shadow_color = Color("#00000066")
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 3)
	return style
