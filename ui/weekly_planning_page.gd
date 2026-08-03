extends MarginContainer

signal status_message(message: String)
signal request_remove_shopping_item(item_id: String)
signal request_book_shopping()
signal request_remove_recipe(recipe_id: String)
signal request_remove_personal_price(price_id: String)

const RecipeCatalog := preload("res://core/recipe_catalog.gd")
const PackPlanner := preload("res://core/pack_planner.gd")

const COLORS := {
	"panel": Color("#15111be8"),
	"panel_soft": Color("#211923ed"),
	"card": Color("#19141ee8"),
	"accent": Color("#e4c99a"),
	"gold": Color("#b8734b"),
	"text": Color("#f5eadb"),
	"muted": Color("#b9a9ad"),
	"success": Color("#a9c493"),
	"warning": Color("#d18a65"),
}

var _compact := false
var _host_compact := false
var _phone_compact := false
var _step := 1
var _active_section := "planning"
var _recipe_search := ""
var _recipe_filter := "all"
var _restore_recipe_search_focus := false
var _recipe_editor_visible := false
var _editing_recipe_id := ""
var _planning_recipe_id := ""
var _price_editor_visible := true
var _editing_price_id := ""
var _display_font := SystemFont.new()
var _interface_font := SystemFont.new()

var _scroll: ScrollContainer
var _content: VBoxContainer
var _header: BoxContainer
var _step_row: BoxContainer
var _step_buttons: Array[Button] = []
var _body: BoxContainer
var _day_cards: BoxContainer
var _summary_panel: Control
var _status_label: Label
var _generate_button: Button
var _apply_button: Button
var _recipe_dialog: AcceptDialog

var _people_input: SpinBox
var _servings_input: SpinBox
var _buffer_input: SpinBox
var _minutes_input: SpinBox
var _diet_input: OptionButton
var _planning_style_input: OptionButton
var _allergies_input: LineEdit
var _excluded_input: LineEdit
var _preferred_input: LineEdit
var _pantry_input: TextEdit
var _shopping_name_input: LineEdit
var _shopping_quantity_input: LineEdit
var _shopping_price_input: SpinBox
var _recipe_search_input: LineEdit
var _recipe_title_input: LineEdit
var _recipe_mode_input: OptionButton
var _recipe_servings_input: SpinBox
var _recipe_minutes_input: SpinBox
var _recipe_ingredients_input: TextEdit
var _recipe_preparation_input: TextEdit
var _recipe_favorite_input: CheckButton
var _price_name_input: LineEdit
var _price_package_input: LineEdit
var _price_estimate_input: SpinBox
var _price_checkout_input: SpinBox
var _price_store_input: LineEdit
var _field_rows: Array[BoxContainer] = []
var _form_state: Dictionary = {}
var _rebuild_queued := false
var _planning_message := ""


func _ready() -> void:
	name = "WeeklyPlanningPage"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right"]:
		add_theme_constant_override(side, 22)
	add_theme_constant_override("margin_top", 18)
	add_theme_constant_override("margin_bottom", 18)
	_display_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	_interface_font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_form_state = ShoppingManager.get_planning_profile()
	_build_shell()
	AiPlanningManager.draft_changed.connect(_on_draft_changed)
	AiPlanningManager.planning_status_changed.connect(_on_planning_status_changed)
	MealPlanManager.plan_changed.connect(_on_plan_changed)
	ShoppingManager.active_week_changed.connect(_on_week_changed)
	ShoppingManager.shopping_changed.connect(_on_shopping_changed)
	ShoppingManager.personal_prices_changed.connect(_on_personal_prices_changed)
	CustomRecipeManager.recipes_changed.connect(_on_recipes_changed)
	BudgetManager.budget_changed.connect(_on_budget_changed)
	resized.connect(_on_resized)
	_rebuild_content()


func set_compact_mode(compact: bool) -> void:
	_host_compact = compact
	_refresh_responsive_mode()


func show_input_step() -> void:
	_active_section = "planning"
	_step = 1
	_rebuild_content()


func show_recipe_price_preview(section: String) -> void:
	_active_section = section if section in ["recipes", "prices"] else "recipes"
	_rebuild_content()


func refresh_view() -> void:
	_rebuild_content()


func _build_shell() -> void:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 16)
	_scroll.add_child(_content)


func _rebuild_content() -> void:
	if not is_instance_valid(_content):
		return
	for child in _content.get_children():
		child.queue_free()
	_step_buttons.clear()
	_field_rows.clear()
	_header = _build_header()
	_content.add_child(_header)
	_content.add_child(_build_preview_section_tabs())
	if _active_section != "planning":
		_content.add_child(
			_build_recipe_library_preview()
			if _active_section == "recipes"
			else _build_price_library_preview()
		)
		_apply_layout()
		return
	_content.add_child(_build_step_panel())

	if _step == 1 or not AiPlanningManager.has_draft():
		_step = 1
		_content.add_child(_build_input_step())
		_content.add_child(_build_week_selector())
		_content.add_child(_build_current_plan_panel())
		_content.add_child(_build_current_shopping_panel())
	elif _step == 2:
		_content.add_child(_build_draft_step(AiPlanningManager.get_draft()))
	else:
		_content.add_child(_build_review_step(AiPlanningManager.get_draft()))
	_apply_layout()


func _build_header() -> BoxContainer:
	var header := BoxContainer.new()
	header.vertical = false
	header.add_theme_constant_override("separation", 16)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Wochenplanung"
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "KI-Plan · Rezepte · Einkauf"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(subtitle)
	header.add_child(titles)

	var context := Label.new()
	context.text = "%s · Woche %d" % [
		MonthManager.get_active_month_name(),
		ShoppingManager.get_active_week(),
	]
	context.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	context.add_theme_font_size_override("font_size", 16)
	context.add_theme_color_override("font_color", COLORS.gold)
	header.add_child(context)
	return header


func _build_step_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#15111bdf"), 18, Color("#a97c35"))
	)
	_step_row = BoxContainer.new()
	_step_row.vertical = false
	_step_row.add_theme_constant_override("separation", 8)
	panel.add_child(_step_row)
	for step_data in [[1, "Angaben"], [2, "KI-Entwurf"], [3, "Übernehmen"]]:
		var step_number := int(step_data[0])
		var button := Button.new()
		button.text = "%d  %s" % [step_number, str(step_data[1])]
		button.custom_minimum_size.y = 48
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = step_number > 1 and not AiPlanningManager.has_draft()
		var active := step_number == _step
		button.add_theme_color_override(
			"font_color",
			Color("#1a1117") if active else COLORS.text
		)
		button.add_theme_stylebox_override(
			"normal",
			_style(COLORS.accent, 14, COLORS.gold) if active
			else _style(Color("#211923aa"), 14, Color("#6a5838"))
		)
		button.pressed.connect(_set_step.bind(step_number))
		_step_buttons.append(button)
		_step_row.add_child(button)
	return panel


func _build_preview_section_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#15111bdf"), 18, Color("#a97c35")))
	var row := BoxContainer.new()
	row.vertical = false
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for data in [["planning", "Planung"], ["recipes", "Rezepte"], ["prices", "Preise"]]:
		var key := str(data[0])
		var button := Button.new()
		button.text = str(data[1])
		button.custom_minimum_size.y = 48
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var active := key == _active_section
		button.add_theme_color_override("font_color", Color("#1a1117") if active else COLORS.text)
		button.add_theme_stylebox_override(
			"normal",
			_style(COLORS.accent, 14, COLORS.gold)
			if active else _style(Color("#211923aa"), 14, Color("#6a5838"))
		)
		button.pressed.connect(_set_active_section.bind(key))
		row.add_child(button)
	return panel


func _set_active_section(section: String) -> void:
	if section not in ["planning", "recipes", "prices"]:
		return
	_active_section = section
	_recipe_editor_visible = false
	_price_editor_visible = section == "prices"
	_planning_recipe_id = ""
	_rebuild_content()


func _build_recipe_library_preview() -> Control:
	if _recipe_editor_visible:
		return _build_recipe_editor()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(_preview_title_row(
		"Meine Rezepte",
		"Eigene und von der KI übernommene Gerichte dauerhaft verwalten.",
		"＋  Neues Rezept",
		Callable(self, "_start_new_recipe")
	))
	var search_row := BoxContainer.new()
	search_row.vertical = _compact
	search_row.add_theme_constant_override("separation", 10)
	_recipe_search_input = LineEdit.new()
	_recipe_search_input.placeholder_text = "Rezepte oder Zutaten suchen"
	_recipe_search_input.text = _recipe_search
	_recipe_search_input.custom_minimum_size.y = 44
	_recipe_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recipe_search_input.text_changed.connect(_on_recipe_search_changed)
	search_row.add_child(_recipe_search_input)
	for filter_data in [["all", "Alle"], ["favorites", "Favoriten"], ["ai", "KI-Rezepte"]]:
		var filter_key := str(filter_data[0])
		var filter := Button.new()
		filter.text = str(filter_data[1])
		filter.custom_minimum_size.y = 44
		if filter_key == _recipe_filter:
			filter.add_theme_color_override("font_color", Color("#1a1117"))
			filter.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
		filter.pressed.connect(_set_recipe_filter.bind(filter_key))
		search_row.add_child(filter)
	_field_rows.append(search_row)
	column.add_child(search_row)
	var recipes := CustomRecipeManager.get_recipes()
	var filtered := _filtered_recipes(recipes)
	var planned_ids: Dictionary = {}
	for day: Variant in MealPlanManager.get_plan():
		if day is Dictionary:
			planned_ids[str(day.get("recipe_id", ""))] = true
	var planned_count := 0
	var favorite_count := 0
	for raw_recipe: Variant in recipes:
		if not raw_recipe is Dictionary:
			continue
		if planned_ids.has(str(raw_recipe.get("id", ""))):
			planned_count += 1
		if bool(raw_recipe.get("favorite", false)):
			favorite_count += 1
	var metrics := BoxContainer.new()
	metrics.vertical = _compact
	metrics.add_theme_constant_override("separation", 10)
	metrics.add_child(_metric_card("Gespeicherte Rezepte", str(recipes.size()), COLORS.accent))
	metrics.add_child(_metric_card("Für diese Woche", str(planned_count), COLORS.gold))
	metrics.add_child(_metric_card("Eigene Favoriten", str(favorite_count), COLORS.success))
	_field_rows.append(metrics)
	column.add_child(metrics)
	if not _planning_recipe_id.is_empty():
		column.add_child(_build_recipe_day_picker())
	if filtered.is_empty():
		var empty := Label.new()
		empty.text = (
			"Keine passenden Rezepte gefunden."
			if not recipes.is_empty()
			else "Noch keine Rezepte gespeichert. Lege dein erstes Gericht an."
		)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		column.add_child(empty)
		return panel
	var cards := GridContainer.new()
	cards.columns = 1 if _compact else 3
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 12)
	for raw_recipe: Variant in filtered:
		if raw_recipe is Dictionary:
			cards.add_child(_recipe_preview_card(raw_recipe))
	column.add_child(cards)
	if _restore_recipe_search_focus:
		_restore_recipe_search_focus = false
		call_deferred("_focus_recipe_search")
	return panel


func _recipe_preview_card(recipe: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(COLORS.card, 16, Color("#806638")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var recipe_id := str(recipe.get("id", ""))
	var favorite := bool(recipe.get("favorite", false))
	var title := Label.new()
	title.text = ("★  " if favorite else "") + str(recipe.get("title", "Rezept"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var source := Label.new()
	source.text = (
		"KI-Rezept" if bool(recipe.get("generated_by_ai", false))
		else str(recipe.get("mode", "Eigenes Rezept"))
	)
	source.add_theme_color_override(
		"font_color",
		COLORS.accent if bool(recipe.get("generated_by_ai", false)) else COLORS.gold
	)
	column.add_child(source)
	var total := _recipe_cost(recipe)
	var facts := Label.new()
	facts.text = "%d Min.  ·  %d Personen\nGeschätzte Kosten  %s" % [
		int(recipe.get("active_minutes", 30)),
		int(recipe.get("servings", 2)),
		_money(total),
	]
	facts.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(facts)
	var primary := BoxContainer.new()
	primary.vertical = _phone_compact
	primary.add_theme_constant_override("separation", 6)
	for action_data in [
		["Öffnen", Callable(self, "_show_stored_recipe").bind(recipe_id)],
		["Einplanen", Callable(self, "_start_recipe_planning").bind(recipe_id)],
		["Einkauf", Callable(self, "_add_recipe_to_shopping").bind(recipe_id)],
	]:
		var action := Button.new()
		action.text = str(action_data[0])
		action.custom_minimum_size.y = 42
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.pressed.connect(action_data[1])
		primary.add_child(action)
	_field_rows.append(primary)
	column.add_child(primary)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 6)
	for action_data in [
		["★" if not favorite else "☆", Callable(CustomRecipeManager, "set_favorite").bind(recipe_id, not favorite)],
		["Bearbeiten", Callable(self, "_edit_recipe").bind(recipe_id)],
		["Löschen", Callable(self, "_request_recipe_delete").bind(recipe_id)],
	]:
		var action := Button.new()
		action.text = str(action_data[0])
		action.custom_minimum_size.y = 38
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.pressed.connect(action_data[1])
		secondary.add_child(action)
	column.add_child(secondary)
	return card


func _build_recipe_editor() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var editing := CustomRecipeManager.get_recipe(_editing_recipe_id)
	var heading := Label.new()
	heading.text = "Rezept bearbeiten" if not editing.is_empty() else "Neues Rezept"
	heading.add_theme_font_override("font", _display_font)
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", COLORS.text)
	column.add_child(heading)
	var hint := Label.new()
	hint.text = "Alle Angaben werden lokal gespeichert und mit deiner Budgetgruppe synchronisiert."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)
	_recipe_title_input = _line_input("Name des Gerichts")
	_recipe_title_input.text = str(editing.get("title", ""))
	_recipe_mode_input = OptionButton.new()
	for mode in ["Normal kochen", "Meal-Prep", "Reste", "Schnellgericht"]:
		_recipe_mode_input.add_item(mode)
	_select_option(_recipe_mode_input, str(editing.get("mode", "Normal kochen")))
	_recipe_mode_input.custom_minimum_size.y = 44
	column.add_child(_two_field_row(
		_field_box("Gericht", _recipe_title_input),
		_field_box("Planungsart", _recipe_mode_input)
	))
	_recipe_servings_input = _number_input(1, 24, float(editing.get("servings", 2)), 1)
	_recipe_minutes_input = _number_input(1, 240, float(editing.get("active_minutes", 30)), 5)
	column.add_child(_two_field_row(
		_field_box("Portionen", _recipe_servings_input),
		_field_box("Aktive Kochzeit in Minuten", _recipe_minutes_input)
	))
	_recipe_ingredients_input = TextEdit.new()
	_recipe_ingredients_input.custom_minimum_size.y = 150
	_recipe_ingredients_input.placeholder_text = "Eine Zutat pro Zeile: Name | Menge | Preis\nBeispiel: Kartoffeln | 1 kg | 2,49"
	_recipe_ingredients_input.text = CustomRecipeManager.ingredients_to_text(
		editing.get("ingredients", [])
	)
	column.add_child(_field_box("Zutaten, Menge und Schätzpreis", _recipe_ingredients_input))
	_recipe_preparation_input = TextEdit.new()
	_recipe_preparation_input.custom_minimum_size.y = 150
	_recipe_preparation_input.placeholder_text = "Zubereitung Schritt für Schritt beschreiben"
	_recipe_preparation_input.text = str(editing.get("preparation", ""))
	column.add_child(_field_box("Zubereitung", _recipe_preparation_input))
	_recipe_favorite_input = CheckButton.new()
	_recipe_favorite_input.text = "Als Favorit markieren"
	_recipe_favorite_input.button_pressed = bool(editing.get("favorite", false))
	column.add_child(_recipe_favorite_input)
	var buttons := BoxContainer.new()
	buttons.vertical = _compact
	buttons.add_theme_constant_override("separation", 8)
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.custom_minimum_size.y = 46
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_close_recipe_editor)
	buttons.add_child(cancel)
	var save := Button.new()
	save.text = "Rezept speichern"
	save.custom_minimum_size.y = 46
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.add_theme_color_override("font_color", Color("#1a1117"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 13, COLORS.gold))
	save.pressed.connect(_save_recipe_editor)
	buttons.add_child(save)
	_field_rows.append(buttons)
	column.add_child(buttons)
	return panel


func _build_recipe_day_picker() -> Control:
	var recipe := CustomRecipeManager.get_recipe(_planning_recipe_id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 16, COLORS.accent))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "„%s“ für welchen Tag einplanen?" % str(recipe.get("title", "Rezept"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var days := GridContainer.new()
	days.columns = 2 if _compact else 7
	for index in range(7):
		var button := Button.new()
		button.text = _day_names()[index]
		button.custom_minimum_size.y = 42
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_plan_recipe_for_day.bind(index))
		days.add_child(button)
	column.add_child(days)
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.pressed.connect(_cancel_recipe_planning)
	column.add_child(cancel)
	return panel


func _start_new_recipe() -> void:
	_editing_recipe_id = ""
	_recipe_editor_visible = true
	_rebuild_content()


func _edit_recipe(recipe_id: String) -> void:
	if CustomRecipeManager.get_recipe(recipe_id).is_empty():
		return
	_editing_recipe_id = recipe_id
	_recipe_editor_visible = true
	_rebuild_content()


func _close_recipe_editor() -> void:
	_recipe_editor_visible = false
	_editing_recipe_id = ""
	_rebuild_content()


func _save_recipe_editor() -> void:
	var ingredients := CustomRecipeManager.parse_ingredients(_recipe_ingredients_input.text)
	var recipe_id := CustomRecipeManager.save_recipe(
		_editing_recipe_id,
		_recipe_title_input.text,
		_recipe_mode_input.get_item_text(_recipe_mode_input.selected),
		ingredients,
		_recipe_preparation_input.text,
		{
			"servings": roundi(_recipe_servings_input.value),
			"active_minutes": roundi(_recipe_minutes_input.value),
			"favorite": _recipe_favorite_input.button_pressed,
		}
	)
	if recipe_id.is_empty():
		status_message.emit("Bitte Gericht, mindestens eine vollständige Zutatenzeile und Zubereitung angeben.")
		return
	_recipe_editor_visible = false
	_editing_recipe_id = ""
	status_message.emit("Rezept wurde gespeichert und wird synchronisiert.")
	_rebuild_content()


func _request_recipe_delete(recipe_id: String) -> void:
	request_remove_recipe.emit(recipe_id)


func remove_recipe_confirmed(recipe_id: String) -> void:
	if CustomRecipeManager.remove_recipe(recipe_id):
		status_message.emit("Rezept wurde gelöscht.")


func _start_recipe_planning(recipe_id: String) -> void:
	_planning_recipe_id = recipe_id
	_rebuild_content()


func _cancel_recipe_planning() -> void:
	_planning_recipe_id = ""
	_rebuild_content()


func _plan_recipe_for_day(day_index: int) -> void:
	var recipe := CustomRecipeManager.get_recipe(_planning_recipe_id)
	if recipe.is_empty():
		return
	if MealPlanManager.update_day(
		day_index,
		str(recipe.get("mode", "Normal kochen")),
		str(recipe.get("title", "")),
		_planning_recipe_id
	):
		status_message.emit("Rezept wurde für %s eingeplant." % _day_names()[day_index])
	_planning_recipe_id = ""
	_rebuild_content()


func _add_recipe_to_shopping(recipe_id: String) -> void:
	var recipe := CustomRecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
	var plan := PackPlanner.plan_all(
		recipe.get("ingredients", []),
		ShoppingManager.get_personal_prices()
	)
	var added := ShoppingManager.add_recipe_ingredients(plan)
	status_message.emit(
		"%d Zutaten wurden zum Wocheneinkauf ergänzt." % added
		if added > 0 else "Keine neue Zutat: bereits vorhanden oder Einkauf abgeschlossen."
	)


func _on_recipe_search_changed(text: String) -> void:
	_recipe_search = text
	_restore_recipe_search_focus = true
	_queue_visible_rebuild()


func _focus_recipe_search() -> void:
	if is_instance_valid(_recipe_search_input):
		_recipe_search_input.grab_focus()
		_recipe_search_input.caret_column = _recipe_search_input.text.length()


func _set_recipe_filter(filter_key: String) -> void:
	_recipe_filter = filter_key
	_rebuild_content()


func _filtered_recipes(recipes: Array) -> Array:
	var result: Array = []
	var needle := _recipe_search.strip_edges().to_lower()
	for raw_recipe: Variant in recipes:
		if not raw_recipe is Dictionary:
			continue
		var recipe: Dictionary = raw_recipe
		if _recipe_filter == "favorites" and not bool(recipe.get("favorite", false)):
			continue
		if _recipe_filter == "ai" and not bool(recipe.get("generated_by_ai", false)):
			continue
		if not needle.is_empty():
			var searchable := str(recipe.get("title", "")).to_lower()
			for ingredient: Variant in recipe.get("ingredients", []):
				if ingredient is Dictionary:
					searchable += " " + str(ingredient.get("name", "")).to_lower()
			if not searchable.contains(needle):
				continue
		result.append(recipe)
	return result


func _recipe_cost(recipe: Dictionary) -> float:
	var total := 0.0
	for ingredient: Variant in recipe.get("ingredients", []):
		if ingredient is Dictionary:
			total += maxf(float(ingredient.get("estimated_price", 0.0)), 0.0)
	return total


func _build_price_library_preview() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	column.add_child(_preview_title_row(
		"Persönliche Preise",
		"Bestätigte Packungs- und Kassenpreise verbessern Einkauf und KI-Schätzung.",
		"＋  Preis hinzufügen",
		Callable(self, "_start_new_personal_price")
	))
	var privacy := Label.new()
	privacy.text = "✦ Verwendet werden nur Produkt, Packung und Preis – keine Buchungen oder Bankdaten."
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy.add_theme_color_override("font_color", COLORS.accent)
	column.add_child(privacy)
	var prices := ShoppingManager.get_personal_prices()
	var checkout_count := 0
	for raw_price: Variant in prices:
		if raw_price is Dictionary and float(raw_price.get("checkout_price", -1.0)) >= 0.0:
			checkout_count += 1
	var metrics := BoxContainer.new()
	metrics.vertical = _compact
	metrics.add_theme_constant_override("separation", 10)
	metrics.add_child(_metric_card("Persönliche Preisbasis", "%d Artikel" % prices.size(), COLORS.accent))
	metrics.add_child(_metric_card("Mit Kassenpreis", str(checkout_count), COLORS.success))
	metrics.add_child(_metric_card("Nur Schätzpreis", str(prices.size() - checkout_count), COLORS.warning))
	_field_rows.append(metrics)
	column.add_child(metrics)
	if _price_editor_visible:
		column.add_child(_build_personal_price_editor())
	var price_list := VBoxContainer.new()
	price_list.add_theme_constant_override("separation", 9)
	if prices.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine persönliche Preisbasis. Trage häufig gekaufte Produkte ein."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		price_list.add_child(empty)
	else:
		for raw_price: Variant in prices:
			if raw_price is Dictionary:
				price_list.add_child(_price_preview_row(raw_price))
	column.add_child(price_list)
	return panel


func _price_preview_row(price: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.card, 14, Color("#6f5b39")))
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var price_id := str(price.get("id", ""))
	var checkout := float(price.get("checkout_price", -1.0))
	var confirmed := checkout >= 0.0
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = str(price.get("name", "Produkt"))
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", COLORS.text)
	identity.add_child(name_label)
	var package_label := Label.new()
	var store := str(price.get("store", "")).strip_edges()
	package_label.text = str(price.get("package_quantity", ""))
	if not store.is_empty():
		package_label.text += " · " + store
	package_label.add_theme_color_override("font_color", COLORS.muted)
	identity.add_child(package_label)
	row.add_child(identity)
	row.add_child(_preview_value(
		"Planungswert",
		_money(float(price.get("package_price", 0.0))),
		COLORS.warning
	))
	row.add_child(_preview_value(
		"Letzter Kassenpreis" if confirmed else "Kassenpreis fehlt",
		_money(checkout) if confirmed else "–",
		COLORS.success if confirmed else COLORS.muted
	))
	var badge := Label.new()
	badge.text = "✓ Persönlich" if confirmed else "Schätzung"
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_color_override("font_color", COLORS.accent if confirmed else COLORS.warning)
	row.add_child(badge)
	var actions := BoxContainer.new()
	actions.vertical = false
	for action_data in [
		["Bearbeiten", Callable(self, "_edit_personal_price").bind(price_id)],
		["Löschen", Callable(self, "_request_personal_price_delete").bind(price_id)],
	]:
		var button := Button.new()
		button.text = str(action_data[0])
		button.custom_minimum_size.y = 40
		button.pressed.connect(action_data[1])
		actions.add_child(button)
	row.add_child(actions)
	_field_rows.append(row)
	return panel


func _build_personal_price_editor() -> Control:
	var editing := ShoppingManager.get_personal_price(_editing_price_id)
	var form := PanelContainer.new()
	form.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 15, Color("#6f5b39")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	form.add_child(column)
	var title := Label.new()
	title.text = "Preis bearbeiten" if not editing.is_empty() else "Neuen persönlichen Preis speichern"
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var form_row := BoxContainer.new()
	form_row.vertical = _compact
	form_row.add_theme_constant_override("separation", 8)
	_price_name_input = _line_input("Produkt")
	_price_name_input.text = str(editing.get("name", ""))
	form_row.add_child(_field_box("Produkt", _price_name_input))
	_price_package_input = _line_input("z. B. 500 g")
	_price_package_input.text = str(editing.get("package_quantity", ""))
	form_row.add_child(_field_box("Packung", _price_package_input))
	_price_estimate_input = _number_input(0, 10000, float(editing.get("package_price", 0.0)), 0.01)
	_price_estimate_input.suffix = " €"
	form_row.add_child(_field_box("Packungspreis", _price_estimate_input))
	_price_checkout_input = _number_input(
		0,
		10000,
		maxf(float(editing.get("checkout_price", 0.0)), 0.0),
		0.01
	)
	_price_checkout_input.suffix = " €"
	form_row.add_child(_field_box("Letzter Kassenpreis", _price_checkout_input))
	_price_store_input = _line_input("optional")
	_price_store_input.text = str(editing.get("store", ""))
	form_row.add_child(_field_box("Geschäft", _price_store_input))
	_field_rows.append(form_row)
	column.add_child(form_row)
	var hint := Label.new()
	hint.text = "Kassenpreis 0,00 € bedeutet: noch kein bestätigter Kassenpreis vorhanden."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)
	var buttons := BoxContainer.new()
	buttons.vertical = _compact
	buttons.add_theme_constant_override("separation", 8)
	var cancel := Button.new()
	cancel.text = "Eingabe leeren"
	cancel.custom_minimum_size.y = 44
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_start_new_personal_price)
	buttons.add_child(cancel)
	var save := Button.new()
	save.text = "Preis speichern"
	save.custom_minimum_size.y = 44
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.add_theme_color_override("font_color", Color("#1a1117"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
	save.pressed.connect(_save_personal_price)
	buttons.add_child(save)
	_field_rows.append(buttons)
	column.add_child(buttons)
	return form


func _start_new_personal_price() -> void:
	_editing_price_id = ""
	_price_editor_visible = true
	_rebuild_content()


func _edit_personal_price(price_id: String) -> void:
	if ShoppingManager.get_personal_price(price_id).is_empty():
		return
	_editing_price_id = price_id
	_price_editor_visible = true
	_rebuild_content()


func _save_personal_price() -> void:
	var checkout_price := _price_checkout_input.value
	if checkout_price <= 0.0:
		checkout_price = -1.0
	var price_id := ShoppingManager.save_personal_price(
		_editing_price_id,
		_price_name_input.text,
		_price_package_input.text,
		_price_estimate_input.value,
		checkout_price,
		_price_store_input.text
	)
	if price_id.is_empty():
		status_message.emit("Bitte Produkt, Packungsgröße und einen gültigen Packungspreis angeben.")
		return
	_editing_price_id = ""
	status_message.emit("Persönlicher Preis wurde gespeichert und wird synchronisiert.")
	_rebuild_content()


func _request_personal_price_delete(price_id: String) -> void:
	request_remove_personal_price.emit(price_id)


func remove_personal_price_confirmed(price_id: String) -> void:
	if ShoppingManager.remove_personal_price(price_id):
		status_message.emit("Persönlicher Preis wurde gelöscht.")


func _preview_title_row(
	title_text: String,
	subtitle_text: String,
	action_text: String,
	action_callable: Callable = Callable()
) -> Control:
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 12)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(subtitle)
	row.add_child(titles)
	var action := Button.new()
	action.text = action_text
	action.custom_minimum_size.y = 46
	action.add_theme_color_override("font_color", Color("#1a1117"))
	action.add_theme_stylebox_override("normal", _style(COLORS.accent, 13, COLORS.gold))
	if action_callable.is_valid():
		action.pressed.connect(action_callable)
	row.add_child(action)
	_field_rows.append(row)
	return row


func _preview_value(label_text: String, value_text: String, color: Color) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 132 if not _compact else 0
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", color)
	column.add_child(value)
	return column


func _build_input_step() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Was soll diese Woche auf den Tisch?"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var info := Label.new()
	info.text = (
		"Die KI erhält nur diese bestätigten Planungsangaben und das abgeleitete "
		+ "Wochenbudget – keine Bankdaten oder Buchungen."
	)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(info)

	var budget_row := HBoxContainer.new()
	budget_row.add_theme_constant_override("separation", 12)
	var weekly_budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	budget_row.add_child(_metric_card("Wochenbudget", _money(weekly_budget), COLORS.accent))
	budget_row.add_child(_metric_card(
		"Planungsziel",
		_money(maxf(weekly_budget - maxf(weekly_budget * 0.1, 5.0), 0.0)),
		COLORS.success
	))
	column.add_child(budget_row)

	_people_input = _number_input(1, 12, float(_form_state.get("people", 2)), 1)
	_servings_input = _number_input(
		1, 24, float(_form_state.get("servingsPerMeal", 2)), 1
	)
	_buffer_input = _number_input(
		0,
		10000,
		float(_form_state.get("safetyBufferCents", roundi(
			maxf(weekly_budget * 0.1, 5.0) * 100.0
		))) / 100.0,
		1
	)
	_minutes_input = _number_input(
		5, 240, float(_form_state.get("maxActiveMinutes", 30)), 5
	)
	var people_row := _two_field_row(
		_field_box("Personen", _people_input),
		_field_box("Portionen pro Gericht", _servings_input)
	)
	column.add_child(people_row)
	var limits_row := _two_field_row(
		_field_box("Sicherheitspuffer in €", _buffer_input),
		_field_box("Maximal aktive Kochzeit", _minutes_input)
	)
	column.add_child(limits_row)

	_diet_input = OptionButton.new()
	for label in ["Alles", "Vegetarisch", "Vegan", "Pescetarisch"]:
		_diet_input.add_item(label)
	_select_option(_diet_input, str(_form_state.get("dietaryStyle", "Alles")))
	_diet_input.custom_minimum_size.y = 44
	_planning_style_input = OptionButton.new()
	for label in [
		"Meal-Prep und Resteverwertung",
		"Günstig und einfach",
		"Schnell im Alltag",
		"Ausgewogen und abwechslungsreich",
	]:
		_planning_style_input.add_item(label)
	_select_option(
		_planning_style_input,
		str(_form_state.get("planningStyle", "Meal-Prep und Resteverwertung"))
	)
	_planning_style_input.custom_minimum_size.y = 44
	var style_row := _two_field_row(
		_field_box("Ernährungsweise", _diet_input),
		_field_box("Planungsart", _planning_style_input)
	)
	column.add_child(style_row)

	_allergies_input = _line_input("Zum Beispiel Erdnüsse, Ei, Milch")
	_excluded_input = _line_input("Zutaten, die keinesfalls verwendet werden dürfen")
	_preferred_input = _line_input("Lieblingszutaten, mit Komma getrennt")
	_allergies_input.text = _list_to_text(_form_state.get("allergies", []))
	_excluded_input.text = _list_to_text(_form_state.get("excludedIngredients", []))
	_preferred_input.text = _list_to_text(_form_state.get("preferredIngredients", []))
	column.add_child(_field_box("Allergien und Unverträglichkeiten", _allergies_input))
	column.add_child(_field_box("Ausgeschlossene Zutaten", _excluded_input))
	column.add_child(_field_box("Bevorzugte Zutaten", _preferred_input))

	_pantry_input = TextEdit.new()
	_pantry_input.placeholder_text = "Ein Vorrat pro Zeile, zum Beispiel: Reis | 500 g"
	_pantry_input.custom_minimum_size.y = 90
	_pantry_input.text = _pantry_to_text(_form_state.get("pantry", []))
	column.add_child(_field_box("Vorhandene Vorräte", _pantry_input))

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", COLORS.muted)
	_status_label.text = _planning_message
	column.add_child(_status_label)

	_generate_button = Button.new()
	var planning_busy := AiPlanningManager.is_request_in_progress()
	_generate_button.text = (
		"✦  KI erstellt den Wochenplan …"
		if planning_busy
		else "✦  KI-Wochenplan erstellen"
	)
	_generate_button.disabled = planning_busy
	_generate_button.custom_minimum_size.y = 54
	_generate_button.add_theme_font_size_override("font_size", 18)
	_generate_button.add_theme_color_override("font_color", Color("#1a1117"))
	_generate_button.add_theme_stylebox_override(
		"normal",
		_style(COLORS.accent, 16, COLORS.gold)
	)
	_generate_button.pressed.connect(_request_ai_plan)
	column.add_child(_generate_button)
	return panel


func _build_current_plan_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#705a35")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Aktueller Sieben-Tage-Plan"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var plan := MealPlanManager.get_plan()
	var names := _day_names()
	for index in range(7):
		var day: Dictionary = plan[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var day_label := Label.new()
		day_label.text = names[index]
		day_label.custom_minimum_size.x = 100
		day_label.add_theme_color_override("font_color", COLORS.gold)
		row.add_child(day_label)
		var meal := Label.new()
		meal.text = str(day.get("meal", "Noch nicht geplant"))
		meal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meal.add_theme_color_override("font_color", COLORS.text)
		row.add_child(meal)
		var recipe_id := str(day.get("recipe_id", ""))
		var recipe_button := Button.new()
		recipe_button.text = "Rezept"
		recipe_button.disabled = recipe_id.is_empty()
		recipe_button.pressed.connect(_show_stored_recipe.bind(recipe_id))
		row.add_child(recipe_button)
		column.add_child(row)
	return panel


func _build_week_selector() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 16, Color("#705a35")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for week in range(1, 6):
		var button := Button.new()
		button.text = str(week) if _host_compact else "Woche %d" % week
		button.toggle_mode = true
		button.button_pressed = week == ShoppingManager.get_active_week()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		if button.button_pressed:
			button.add_theme_color_override("font_color", Color("#1a1117"))
			button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
		button.pressed.connect(ShoppingManager.set_active_week.bind(week))
		row.add_child(button)
	return panel


func _build_current_shopping_panel() -> Control:
	var weekly_budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	var summary := ShoppingManager.get_summary(weekly_budget)
	var booked := ShoppingManager.is_booked()
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#705a35")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = "Aktueller Wocheneinkauf"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLORS.text)
	title_row.add_child(title)
	var state := Label.new()
	state.text = "Verbucht" if booked else "Woche %d" % ShoppingManager.get_active_week()
	state.add_theme_color_override("font_color", COLORS.success if booked else COLORS.gold)
	title_row.add_child(state)
	column.add_child(title_row)

	var metrics := BoxContainer.new()
	metrics.vertical = _compact
	metrics.add_theme_constant_override("separation", 10)
	metrics.add_child(_metric_card("Wochenbudget", _money(weekly_budget), COLORS.accent))
	metrics.add_child(_metric_card("Geplant", _money(float(summary.planned)), COLORS.warning))
	metrics.add_child(_metric_card("Gekauft", _money(float(summary.checked)), COLORS.gold))
	metrics.add_child(_metric_card(
		"Noch verfügbar",
		_money(float(summary.remaining)),
		COLORS.warning if bool(summary.over_budget) else COLORS.success
	))
	_field_rows.append(metrics)
	column.add_child(metrics)

	if not booked:
		var add_row := BoxContainer.new()
		add_row.vertical = _compact
		add_row.add_theme_constant_override("separation", 8)
		_shopping_name_input = _line_input("Artikel")
		_shopping_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_row.add_child(_shopping_name_input)
		_shopping_quantity_input = _line_input("Menge, z. B. 2 kg")
		_shopping_quantity_input.custom_minimum_size.x = 175 if not _compact else 0
		add_row.add_child(_shopping_quantity_input)
		_shopping_price_input = _number_input(0, 10000, 0, 0.01)
		_shopping_price_input.suffix = " €"
		_shopping_price_input.custom_minimum_size.x = 130 if not _compact else 0
		add_row.add_child(_shopping_price_input)
		var add_button := Button.new()
		add_button.text = "+  Artikel"
		add_button.custom_minimum_size.y = 44
		add_button.add_theme_color_override("font_color", Color("#1a1117"))
		add_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
		add_button.pressed.connect(_add_shopping_item)
		add_row.add_child(add_button)
		_field_rows.append(add_row)
		column.add_child(add_row)

	var items := ShoppingManager.get_items()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Artikel für diese Woche eingetragen."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		column.add_child(empty)
	else:
		for item: Dictionary in items:
			column.add_child(_build_current_shopping_row(item, booked))

	var book_button := Button.new()
	book_button.text = (
		"✓  Einkauf wurde als Monatsausgabe verbucht"
		if booked
		else "Abgehakte Artikel als Einkauf verbuchen"
	)
	book_button.disabled = booked or float(summary.checked) <= 0.0
	book_button.custom_minimum_size.y = 48
	book_button.add_theme_color_override("font_color", Color("#1a1117"))
	book_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12, COLORS.gold))
	book_button.pressed.connect(func() -> void: request_book_shopping.emit())
	column.add_child(book_button)
	return panel


func _build_current_shopping_row(item: Dictionary, booked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.card, 12, Color("#684853")))
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var checked := CheckBox.new()
	checked.button_pressed = bool(item.get("checked", false))
	checked.text = "Gekauft" if checked.button_pressed else "Noch offen"
	checked.disabled = booked
	checked.toggled.connect(_toggle_current_shopping_item.bind(str(item.get("id", ""))))
	row.add_child(checked)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := Label.new()
	name.text = str(item.get("name", ""))
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_color_override("font_color", COLORS.text)
	labels.add_child(name)
	var quantity := Label.new()
	quantity.text = str(item.get("quantity", ""))
	quantity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quantity.add_theme_color_override("font_color", COLORS.muted)
	labels.add_child(quantity)
	row.add_child(labels)
	var prices := VBoxContainer.new()
	prices.add_theme_constant_override("separation", 3)
	var estimate := Label.new()
	estimate.text = "Schätzung  %s" % _money(float(item.get("estimated_price", 0.0)))
	estimate.add_theme_color_override("font_color", COLORS.warning)
	prices.add_child(estimate)
	if not booked:
		var actual_row := HBoxContainer.new()
		actual_row.add_theme_constant_override("separation", 4)
		var actual := _number_input(
			0,
			10000,
			maxf(float(item.get("actual_price", 0.0)), 0.0),
			0.01
		)
		actual.suffix = " €"
		actual.custom_minimum_size.x = 110
		actual.tooltip_text = "Tatsächlich an der Kasse bezahlter Preis"
		actual_row.add_child(actual)
		var save_actual := Button.new()
		save_actual.text = "Kassenpreis"
		save_actual.custom_minimum_size.y = 40
		save_actual.pressed.connect(
			_save_actual_shopping_price.bind(str(item.get("id", "")), actual)
		)
		actual_row.add_child(save_actual)
		prices.add_child(actual_row)
	else:
		var actual_label := Label.new()
		actual_label.text = "Kassenpreis  %s" % _money(float(item.get(
			"actual_price",
			item.get("estimated_price", 0.0)
		)))
		actual_label.add_theme_color_override("font_color", COLORS.success)
		prices.add_child(actual_label)
	row.add_child(prices)
	var remove := Button.new()
	remove.text = "Artikel löschen" if _compact else "×"
	remove.tooltip_text = "Artikel löschen"
	remove.disabled = booked
	remove.custom_minimum_size = Vector2(42, 42)
	remove.pressed.connect(func() -> void:
		request_remove_shopping_item.emit(str(item.get("id", "")))
	)
	row.add_child(remove)
	_field_rows.append(row)
	return panel


func _add_shopping_item() -> void:
	var clean_name := _shopping_name_input.text.strip_edges()
	for item: Dictionary in ShoppingManager.get_items():
		if str(item.get("name", "")).strip_edges().to_lower() == clean_name.to_lower():
			status_message.emit("Dieser Artikel steht bereits auf der Einkaufsliste.")
			return
	var selected_price := _shopping_price_input.value
	if selected_price <= 0.0:
		for personal_price: Variant in ShoppingManager.get_personal_prices():
			if (
				personal_price is Dictionary
				and str(personal_price.get("name", "")).strip_edges().to_lower()
				== clean_name.to_lower()
			):
				selected_price = float(personal_price.get("checkout_price", -1.0))
				if selected_price < 0.0:
					selected_price = float(personal_price.get("package_price", 0.0))
				break
	if ShoppingManager.add_item(
		clean_name,
		_shopping_quantity_input.text,
		selected_price
	):
		status_message.emit("✓ Artikel wurde zur Einkaufsliste hinzugefügt.")
	else:
		status_message.emit("Bitte einen gültigen Artikelnamen und Preis eingeben.")


func _save_actual_shopping_price(item_id: String, input: SpinBox) -> void:
	if ShoppingManager.set_actual_price(item_id, input.value):
		status_message.emit("Kassenpreis wurde gespeichert und wird für die Buchung verwendet.")


func _toggle_current_shopping_item(checked: bool, item_id: String) -> void:
	ShoppingManager.set_checked(item_id, checked)


func _build_draft_step(draft: Dictionary) -> Control:
	_body = BoxContainer.new()
	_body.vertical = false
	_body.add_theme_constant_override("separation", 16)
	var plan_panel := PanelContainer.new()
	plan_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plan_panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, COLORS.gold))
	var plan_column := VBoxContainer.new()
	plan_column.add_theme_constant_override("separation", 12)
	plan_panel.add_child(plan_column)
	var title := Label.new()
	title.text = "Dein KI-Wochenplan"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	plan_column.add_child(title)
	var estimate := Label.new()
	estimate.text = "ⓘ Gerichte und Preise sind geprüfte Schätzwerte"
	estimate.add_theme_color_override("font_color", COLORS.muted)
	plan_column.add_child(estimate)
	_day_cards = BoxContainer.new()
	_day_cards.vertical = false
	_day_cards.add_theme_constant_override("separation", 8)
	for index in range(7):
		var day := _find_draft_day(draft, index)
		_day_cards.add_child(_build_day_card(day, _day_names()[index]))
	plan_column.add_child(_day_cards)
	_body.add_child(plan_panel)
	_summary_panel = _build_draft_summary(draft)
	_body.add_child(_summary_panel)
	return _body


func _build_day_card(day: Dictionary, day_name: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := _style(COLORS.card, 14, Color("#a9803e"))
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	panel.add_theme_stylebox_override("panel", card_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var name := Label.new()
	name.text = day_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_override("font", _display_font)
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", COLORS.gold)
	column.add_child(name)
	var meal := Label.new()
	meal.text = str(day.get("meal", ""))
	meal.custom_minimum_size.y = 64
	meal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meal.add_theme_color_override("font_color", COLORS.text)
	column.add_child(meal)
	var price := Label.new()
	price.text = _money_cents(int(day.get("estimatedCostCents", 0)))
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.add_theme_font_override("font", _display_font)
	price.add_theme_font_size_override("font_size", 21)
	price.add_theme_color_override("font_color", COLORS.warning)
	column.add_child(price)
	var recipe_button := Button.new()
	recipe_button.text = "▤  Rezept"
	recipe_button.custom_minimum_size.y = 40
	recipe_button.pressed.connect(_show_draft_recipe.bind(str(day.get("recipeId", ""))))
	column.add_child(recipe_button)
	var note := str(day.get("mealPrepNote", "")).strip_edges()
	if note.is_empty():
		note = str(day.get("leftoverNote", "")).strip_edges()
	if not note.is_empty():
		var tag := Label.new()
		tag.text = (
			"Meal-Prep" if not str(day.get("mealPrepNote", "")).is_empty()
			else "Reste"
		)
		tag.tooltip_text = note
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_color_override("font_color", COLORS.accent)
		column.add_child(tag)
	return panel


func _build_draft_summary(draft: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 300
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 18, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Wochenübersicht"
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", COLORS.gold)
	column.add_child(title)
	column.add_child(_summary_line("Wochenbudget", _money_cents(int(draft.weeklyBudgetCents))))
	column.add_child(_summary_line("Sicherheitspuffer", _money_cents(int(draft.safetyBufferCents))))
	column.add_child(HSeparator.new())
	column.add_child(_summary_line("Geplant", _money_cents(int(draft.estimatedCostCents))))
	column.add_child(_summary_line(
		"Verbleibend",
		_money_cents(int(draft.remainingCents)),
		COLORS.success
	))
	var shopping_title := Label.new()
	shopping_title.text = "Einkauf · Vorschau"
	shopping_title.add_theme_font_override("font", _display_font)
	shopping_title.add_theme_font_size_override("font_size", 20)
	shopping_title.add_theme_color_override("font_color", COLORS.gold)
	column.add_child(shopping_title)
	var items: Array = draft.shoppingItems
	for index in range(mini(items.size(), 5)):
		var item: Dictionary = items[index]
		column.add_child(_summary_line(
			str(item.get("name", "")),
			_money_cents(int(item.get("estimatedPriceCents", 0)))
		))
	if items.size() > 5:
		var more := Label.new()
		more.text = "+ %d weitere Artikel" % (items.size() - 5)
		more.add_theme_color_override("font_color", COLORS.muted)
		column.add_child(more)
	var price_note := Label.new()
	price_note.text = str(draft.get("priceBasis", "Schätzpreise; Kassenpreise können abweichen."))
	price_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	price_note.add_theme_font_size_override("font_size", 12)
	price_note.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(price_note)
	var edit := Button.new()
	edit.text = "Angaben bearbeiten"
	edit.pressed.connect(_set_step.bind(1))
	column.add_child(edit)
	var review := Button.new()
	review.text = "✓  Plan prüfen"
	review.custom_minimum_size.y = 52
	review.add_theme_font_size_override("font_size", 18)
	review.add_theme_color_override("font_color", Color("#1a1117"))
	review.add_theme_stylebox_override("normal", _style(COLORS.accent, 14, COLORS.gold))
	review.pressed.connect(_set_step.bind(3))
	column.add_child(review)
	return panel


func _build_review_step(draft: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 22, COLORS.gold))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Plan prüfen und gemeinsam übernehmen"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _display_font)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	var explanation := Label.new()
	explanation.text = (
		"Mit der Bestätigung werden %d KI-Rezepte, genau sieben Tage und %d "
		+ "Einkaufsartikel in die aktive Woche übernommen. Vorher wird automatisch "
		+ "eine Datensicherung erstellt. Es wird keine Ausgabe gebucht."
	) % [draft.recipes.size(), draft.shoppingItems.size()]
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(explanation)
	var metrics := BoxContainer.new()
	metrics.vertical = _compact
	metrics.add_theme_constant_override("separation", 12)
	metrics.add_child(_metric_card("Budget", _money_cents(int(draft.weeklyBudgetCents)), COLORS.accent))
	metrics.add_child(_metric_card("Geplant", _money_cents(int(draft.estimatedCostCents)), COLORS.warning))
	metrics.add_child(_metric_card("Puffer + frei", _money_cents(
		int(draft.safetyBufferCents) + int(draft.remainingCents)
	), COLORS.success))
	_field_rows.append(metrics)
	column.add_child(metrics)
	for warning: Variant in draft.get("warnings", []):
		var warning_label := Label.new()
		warning_label.text = "ⓘ %s" % str(warning)
		warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning_label.add_theme_color_override("font_color", COLORS.warning)
		column.add_child(warning_label)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(_status_label)
	var buttons := BoxContainer.new()
	buttons.vertical = _compact
	buttons.add_theme_constant_override("separation", 10)
	var back := Button.new()
	back.text = "Zurück zum Entwurf"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.custom_minimum_size.y = 50
	back.pressed.connect(_set_step.bind(2))
	buttons.add_child(back)
	_apply_button = Button.new()
	_apply_button.text = "✓  Jetzt vollständig übernehmen"
	_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button.custom_minimum_size.y = 50
	_apply_button.add_theme_color_override("font_color", Color("#1a1117"))
	_apply_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 14, COLORS.gold))
	_apply_button.pressed.connect(_apply_ai_plan)
	buttons.add_child(_apply_button)
	_field_rows.append(buttons)
	column.add_child(buttons)
	return panel


func _request_ai_plan() -> void:
	var weekly_budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	var data := {
		"weeklyBudgetCents": roundi(weekly_budget * 100.0),
		"safetyBufferCents": roundi(_buffer_input.value * 100.0),
		"people": roundi(_people_input.value),
		"servingsPerMeal": roundi(_servings_input.value),
		"maxActiveMinutes": roundi(_minutes_input.value),
		"dietaryStyle": _diet_input.get_item_text(_diet_input.selected),
		"planningStyle": _planning_style_input.get_item_text(
			_planning_style_input.selected
		),
		"allergies": _split_list(_allergies_input.text),
		"excludedIngredients": _split_list(_excluded_input.text),
		"preferredIngredients": _split_list(_preferred_input.text),
		"pantry": _parse_pantry(_pantry_input.text),
		"personalPrices": ShoppingManager.get_ai_personal_prices(),
	}
	_form_state = data.duplicate(true)
	ShoppingManager.save_planning_profile(_form_state)
	_planning_message = "Die KI-Planung wird sicher auf dem Server erstellt …"
	_generate_button.disabled = true
	_generate_button.text = "✦  KI erstellt den Wochenplan …"
	_status_label.text = _planning_message
	var result := await AiPlanningManager.request_draft(data)
	if is_instance_valid(_generate_button):
		_generate_button.disabled = false
		_generate_button.text = "✦  KI-Wochenplan erstellen"
	if bool(result.get("success", false)):
		_planning_message = str(result.get("message", "Der geprüfte KI-Entwurf ist bereit."))
		_step = 2
		_rebuild_content()
	else:
		_planning_message = str(result.get("message", "Die Planung ist fehlgeschlagen."))
		if is_instance_valid(_status_label):
			_status_label.text = _planning_message
		status_message.emit(_planning_message)


func _apply_ai_plan() -> void:
	_apply_button.disabled = true
	_status_label.text = "Datensicherung und Übernahme laufen …"
	var result := AiPlanningManager.apply_draft()
	_apply_button.disabled = false
	_status_label.text = str(result.get("message", "Die Übernahme ist fehlgeschlagen."))
	status_message.emit(_status_label.text)
	if bool(result.get("success", false)):
		_step = 1
		_rebuild_content()


func _set_step(step: int) -> void:
	if step > 1 and not AiPlanningManager.has_draft():
		return
	_step = clampi(step, 1, 3)
	_rebuild_content()


func _apply_layout() -> void:
	if not is_instance_valid(_content):
		return
	for side in ["margin_left", "margin_right"]:
		add_theme_constant_override(side, 10 if _compact else 22)
	add_theme_constant_override("margin_top", 10 if _compact else 18)
	add_theme_constant_override("margin_bottom", 112 if _host_compact else 18)
	if is_instance_valid(_header):
		_header.vertical = _compact
	if is_instance_valid(_step_row):
		_step_row.vertical = false
	for index in _step_buttons.size():
		_step_buttons[index].text = (
			str(index + 1) if _host_compact
			else ["Angaben", "Entwurf", "Übernehmen"][index]
		)
	if is_instance_valid(_body):
		_body.vertical = _compact
	if is_instance_valid(_day_cards):
		_day_cards.vertical = _compact
		for card: Control in _day_cards.get_children():
			card.custom_minimum_size = Vector2(0 if _compact else 100, 0)
	if is_instance_valid(_summary_panel):
		_summary_panel.custom_minimum_size.x = 0 if _compact else 260
	for row in _field_rows:
		if is_instance_valid(row):
			row.vertical = _compact


func _on_draft_changed(_draft: Dictionary) -> void:
	if not AiPlanningManager.has_draft() and _step > 1:
		_step = 1


func _on_planning_status_changed(_status: String, message: String) -> void:
	_planning_message = message
	if is_instance_valid(_status_label):
		_status_label.text = message


func _on_plan_changed(_plan: Array) -> void:
	if _step == 1 or _active_section == "recipes":
		_queue_visible_rebuild()


func _on_week_changed(_week: int) -> void:
	_queue_visible_rebuild()


func _on_shopping_changed(
	_items: Array,
	_summary: Dictionary,
	_booked: bool
) -> void:
	if _step == 1 or _active_section in ["recipes", "prices"]:
		_queue_visible_rebuild()


func _on_personal_prices_changed(_prices: Array) -> void:
	if _active_section == "prices":
		_queue_visible_rebuild()


func _on_recipes_changed(_recipes: Array) -> void:
	if _active_section == "recipes":
		_queue_visible_rebuild()


func _on_budget_changed(_snapshot: Dictionary) -> void:
	if _step == 1:
		_queue_visible_rebuild()


func _queue_visible_rebuild() -> void:
	if not visible or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_apply_queued_rebuild")


func _apply_queued_rebuild() -> void:
	_rebuild_queued = false
	if visible:
		_rebuild_content()


func _on_resized() -> void:
	call_deferred("_refresh_responsive_mode")


func _refresh_responsive_mode() -> void:
	if not is_instance_valid(_content):
		return
	var effective_compact := _host_compact or size.x < 1080.0
	var phone_compact := effective_compact and size.x < 430.0
	if _compact == effective_compact and _phone_compact == phone_compact:
		return
	_compact = effective_compact
	_phone_compact = phone_compact
	_apply_layout()


func _show_draft_recipe(source_id: String) -> void:
	var draft := AiPlanningManager.get_draft()
	for raw_recipe: Variant in draft.get("recipes", []):
		if raw_recipe is Dictionary and str(raw_recipe.get("id", "")) == source_id:
			_show_recipe_data(raw_recipe)
			return


func _show_stored_recipe(recipe_id: String) -> void:
	var recipe := RecipeCatalog.get_recipe(recipe_id)
	if recipe.is_empty():
		recipe = CustomRecipeManager.get_recipe(recipe_id)
	if not recipe.is_empty():
		_show_recipe_data(recipe)


func _show_recipe_data(recipe: Dictionary) -> void:
	if not is_instance_valid(_recipe_dialog):
		_recipe_dialog = AcceptDialog.new()
		_recipe_dialog.ok_button_text = "Schließen"
		add_child(_recipe_dialog)
	_recipe_dialog.title = str(recipe.get("title", "Rezept"))
	var lines: Array[String] = []
	lines.append("Zutaten")
	for ingredient: Variant in recipe.get("ingredients", []):
		if not ingredient is Dictionary:
			continue
		var cents := int(ingredient.get("estimatedPriceCents", -1))
		var price := (
			_money_cents(cents)
			if cents >= 0
			else _money(float(ingredient.get("estimated_price", 0.0)))
		)
		lines.append("• %s · %s · %s" % [
			str(ingredient.get("name", "")),
			str(ingredient.get("quantity", "")),
			price,
		])
	lines.append("")
	lines.append("Zubereitung")
	lines.append(str(recipe.get("preparation", "")))
	_recipe_dialog.dialog_text = "\n".join(lines)
	_recipe_dialog.popup_centered(Vector2i(680 if not _compact else 350, 640))


func _metric_card(title_text: String, value_text: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(COLORS.card, 14, color))
	var column := VBoxContainer.new()
	panel.add_child(column)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_override("font", _display_font)
	value.add_theme_font_size_override("font_size", 23)
	value.add_theme_color_override("font_color", color)
	column.add_child(value)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(title)
	return panel


func _summary_line(label_text: String, value_text: String, color: Color = COLORS.text) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_color", COLORS.muted)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.size_flags_horizontal = Control.SIZE_SHRINK_END
	value.add_theme_color_override("font_color", color)
	row.add_child(value)
	return row


func _field_box(label_text: String, control: Control) -> Control:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", COLORS.gold)
	column.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(control)
	return column


func _two_field_row(left: Control, right: Control) -> BoxContainer:
	var row := BoxContainer.new()
	row.vertical = _compact
	row.add_theme_constant_override("separation", 12)
	row.add_child(left)
	row.add_child(right)
	_field_rows.append(row)
	return row


func _number_input(minimum: float, maximum: float, value: float, step: float) -> SpinBox:
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.value = value
	input.step = step
	input.custom_minimum_size.y = 44
	return input


func _line_input(placeholder: String) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size.y = 44
	return input


func _style(fill: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	if border.a > 0.0:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = border
	if fill.a > 0.15 and radius >= 12:
		style.shadow_color = Color("#00000066")
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 3)
	return style


static func _split_list(text: String) -> Array[String]:
	var result: Array[String] = []
	for raw_value in text.replace("\n", ",").split(","):
		var value := str(raw_value).strip_edges()
		if not value.is_empty() and not result.has(value):
			result.append(value)
	return result


static func _parse_pantry(text: String) -> Array:
	var result: Array = []
	for raw_line in text.split("\n"):
		var line := str(raw_line).strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("|", false, 1)
		var name := str(parts[0]).strip_edges()
		var quantity := str(parts[1]).strip_edges() if parts.size() > 1 else "vorhanden"
		if not name.is_empty():
			result.append({"name": name, "quantity": quantity})
	return result


static func _select_option(input: OptionButton, value: String) -> void:
	for index in input.item_count:
		if input.get_item_text(index) == value:
			input.select(index)
			return


static func _list_to_text(values: Variant) -> String:
	if not values is Array:
		return ""
	var parts: Array[String] = []
	for value: Variant in values:
		parts.append(str(value))
	return ", ".join(parts)


static func _pantry_to_text(values: Variant) -> String:
	if not values is Array:
		return ""
	var lines: Array[String] = []
	for value: Variant in values:
		if value is Dictionary:
			lines.append("%s | %s" % [
				str(value.get("name", "")),
				str(value.get("quantity", "")),
			])
	return "\n".join(lines)


static func _find_draft_day(draft: Dictionary, day_index: int) -> Dictionary:
	for raw_day: Variant in draft.get("days", []):
		if raw_day is Dictionary and int(raw_day.get("dayIndex", -1)) == day_index:
			return raw_day
	return {}


static func _day_names() -> Array[String]:
	return ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]


static func _money_cents(cents: int) -> String:
	return _money(float(cents) / 100.0)


static func _money(value: float) -> String:
	return ("%.2f €" % value).replace(".", ",")
