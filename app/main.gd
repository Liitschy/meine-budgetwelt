extends Control

const BudgetWorldView := preload("res://ui/budget_world_view.gd")
const MonthUtils := preload("res://core/month_utils.gd")
const RecipeCatalog := preload("res://core/recipe_catalog.gd")
const WeeklyNeedCalculator := preload("res://core/weekly_need_calculator.gd")
const PackPlanner := preload("res://core/pack_planner.gd")

const COLORS := {
	"background": Color("#02151e"),
	"sidebar": Color("#052833f2"),
	"panel": Color("#07333ce8"),
	"panel_soft": Color("#0a4148f2"),
	"accent": Color("#39dfc8"),
	"gold": Color("#e6b85c"),
	"text": Color("#f5f0df"),
	"muted": Color("#a7c7bf"),
	"warning": Color("#ef9a5d"),
	"success": Color("#85dfa0"),
}

var world_view: Control
var summary_values: Dictionary = {}
var input_fields: Dictionary = {}
var setup_panel: PanelContainer
var status_label: Label
var dashboard_page: VBoxContainer
var dashboard_scroll: ScrollContainer
var fixed_costs_page: Control
var fixed_cost_list: VBoxContainer
var fixed_summary_values: Dictionary = {}
var add_cost_panel: PanelContainer
var cost_name_input: LineEdit
var cost_category_input: OptionButton
var cost_amount_input: SpinBox
var cost_due_day_input: SpinBox
var cost_frequency_input: OptionButton
var cost_anchor_month_input: OptionButton
var cost_dialog_title: Label
var cost_save_button: Button
var _editing_fixed_cost_id := ""
var dashboard_month_label: Label
var fixed_cost_month_label: Label
var month_selector_label: Label
var month_change_panel: PanelContainer
var month_change_title: Label
var month_opening_balance: SpinBox
var pending_month_id := ""
var sidebar_panel: Control
var mobile_navigation: Control
var mobile_nav_buttons: Dictionary = {}
var book_navigation_controls: Array[Control] = []
var app_shell: VBoxContainer
var app_bar: Control
var app_local_status: Label
var desktop_backdrop: TextureRect
var dashboard_header: BoxContainer
var dashboard_title: Label
var month_controls: HBoxContainer
var month_edit_button: Button
var dashboard_body: BoxContainer
var week_cards: BoxContainer
var summary_panel: Control
var mobile_dashboard_metrics: Control
var mobile_dashboard_actions: Control
var mobile_dashboard_values: Dictionary = {}
var month_flow_panel: Control
var fixed_header: BoxContainer
var fixed_page_art: TextureRect
var fixed_summary_row: BoxContainer
var fixed_list_header: Control
var fixed_list_panel: Control
var fixed_hint_label: Label
var savings_header: BoxContainer
var savings_page_art: TextureRect
var savings_list_panel: Control
var transactions_header: BoxContainer
var transactions_page_art: TextureRect
var transactions_list_panel: Control
var add_cost_dialog: Control
var month_change_dialog: Control
var setup_dialog: Control
var _compact_layout := false
var savings_page: Control
var savings_list: VBoxContainer
var savings_summary_values: Dictionary = {}
var savings_summary_row: BoxContainer
var savings_list_title: Label
var add_goal_panel: PanelContainer
var add_goal_dialog: Control
var goal_name_input: LineEdit
var goal_target_input: SpinBox
var goal_saved_input: SpinBox
var goal_monthly_input: SpinBox
var deposit_panel: PanelContainer
var deposit_dialog: Control
var deposit_amount_input: SpinBox
var deposit_goal_id := ""
var deposit_goal_title: Label
var transactions_page: Control
var transaction_list: VBoxContainer
var transaction_summary_values: Dictionary = {}
var transaction_summary_row: BoxContainer
var transaction_weekly_filter_button: Button
var transaction_filter_summary: Label
var transaction_list_header: BoxContainer
var transaction_list_title: Label
var add_transaction_panel: PanelContainer
var add_transaction_dialog: Control
var transaction_kind_input: OptionButton
var transaction_category_input: OptionButton
var transaction_description_input: LineEdit
var transaction_amount_input: SpinBox
var transaction_day_input: SpinBox
var confirmation_panel: PanelContainer
var confirmation_message: Label
var _confirmation_action := Callable()
var restore_dialog: FileDialog
var restore_confirmation: ConfirmationDialog
var _pending_restore_path := ""
var balance_panel: PanelContainer
var balance_dialog: Control
var balance_input: SpinBox
var fixed_payment_panel: PanelContainer
var fixed_payment_dialog: Control
var fixed_payment_input: SpinBox
var fixed_payment_title: Label
var _payment_fixed_cost_id := ""
var shopping_page: VBoxContainer
var shopping_list: VBoxContainer
var shopping_summary_values: Dictionary = {}
var shopping_summary_row: BoxContainer
var shopping_week_buttons: Array[Button] = []
var shopping_book_button: Button
var add_shopping_item_panel: PanelContainer
var add_shopping_item_dialog: Control
var shopping_name_input: LineEdit
var shopping_quantity_input: LineEdit
var shopping_price_input: SpinBox
var meal_plan_page: VBoxContainer
var meal_plan_list: VBoxContainer
var meal_week_label: Label
var meal_day_controls: Array = []
var recipe_panel: PanelContainer
var recipe_dialog: Control
var recipe_title: Label
var recipe_ingredients: Label
var recipe_preparation: Label
var recipe_add_button: Button
var _open_recipe_id := ""
var custom_recipe_panel: PanelContainer
var custom_recipe_dialog: Control
var custom_recipe_list: VBoxContainer
var custom_recipe_editor: VBoxContainer
var custom_recipe_title_input: LineEdit
var custom_recipe_mode_input: OptionButton
var custom_recipe_ingredients_list: VBoxContainer
var custom_recipe_ingredient_controls: Array = []
var custom_recipe_preparation_input: TextEdit
var custom_recipe_day_input: OptionButton
var _editing_custom_recipe_id := ""
var upcoming_cost_list: VBoxContainer
var dashboard_flow_values: Dictionary = {}
var display_font: SystemFont
var interface_font: SystemFont


func _ready() -> void:
	_configure_web_content_scale()
	_apply_design_theme()
	_build_interface()
	_apply_heading_fonts(self)
	BudgetManager.budget_changed.connect(_refresh)
	FixedCostManager.fixed_costs_changed.connect(_on_fixed_costs_changed)
	SavingsManager.savings_goals_changed.connect(_on_savings_goals_changed)
	TransactionManager.active_transactions_changed.connect(_on_transactions_changed)
	ShoppingManager.shopping_changed.connect(_on_shopping_changed)
	ShoppingManager.active_week_changed.connect(_on_shopping_week_changed)
	MealPlanManager.plan_changed.connect(_on_meal_plan_changed)
	CustomRecipeManager.recipes_changed.connect(_on_custom_recipes_changed)
	MonthManager.active_month_changed.connect(_on_active_month_changed)
	UpdateManager.update_check_finished.connect(_on_update_check_finished)
	_build_restore_dialog()
	_apply_fixed_cost_summary(FixedCostManager.get_summary())
	_apply_savings_summary(SavingsManager.get_summary())
	_apply_transaction_summary(TransactionManager.get_active_summary())
	_apply_shopping_state()
	_refresh(BudgetManager.get_snapshot())
	_rebuild_fixed_cost_rows()
	_rebuild_upcoming_costs()
	_rebuild_savings_rows()
	_rebuild_transaction_rows()
	_rebuild_shopping_rows()
	_rebuild_meal_plan_rows()
	_update_month_labels()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	call_deferred("_reset_dashboard_scroll")


func _configure_web_content_scale() -> void:
	if not OS.has_feature("web"):
		return
	var css_width := int(JavaScriptBridge.eval("Math.round(window.innerWidth)", true))
	var css_height := int(JavaScriptBridge.eval("Math.round(window.innerHeight)", true))
	if css_width < 280 or css_height < 480:
		return
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_size = Vector2i(css_width, css_height)


func _apply_design_theme() -> void:
	interface_font = SystemFont.new()
	interface_font.font_names = PackedStringArray([
		"Segoe UI Variable Display",
		"Segoe UI Variable Text",
		"Segoe UI",
	])
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray([
		"Georgia",
		"Palatino Linotype",
	])

	var app_theme := Theme.new()
	app_theme.default_font = interface_font
	app_theme.default_font_size = 15
	app_theme.set_color("font_color", "Label", COLORS.text)
	app_theme.set_color("font_color", "Button", COLORS.text)
	app_theme.set_color("font_hover_color", "Button", Color.WHITE)
	app_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	app_theme.set_stylebox("normal", "Button", _style(Color("#082c35e8"), 12, Color("#39645e")))
	app_theme.set_stylebox("hover", "Button", _style(Color("#104c50f2"), 12, COLORS.gold))
	app_theme.set_stylebox("pressed", "Button", _style(Color("#0a6262"), 12, COLORS.accent))
	app_theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, 12, COLORS.accent))
	app_theme.set_stylebox("normal", "LineEdit", _style(Color("#061f28f2"), 9, Color("#3c635d")))
	app_theme.set_stylebox("focus", "LineEdit", _style(Color("#0a353b"), 9, COLORS.gold))
	app_theme.set_stylebox("normal", "SpinBox", _style(Color("#061f28f2"), 9, Color("#3c635d")))
	app_theme.set_stylebox("normal", "OptionButton", _style(Color("#061f28f2"), 9, Color("#3c635d")))
	app_theme.set_color("font_color", "LineEdit", COLORS.text)
	app_theme.set_color("font_color", "SpinBox", COLORS.text)
	app_theme.set_color("font_color", "OptionButton", COLORS.text)
	app_theme.set_color("font_color", "CheckBox", COLORS.text)
	app_theme.set_color("font_pressed_color", "CheckBox", COLORS.success)
	app_theme.set_color("icon_normal_color", "CheckBox", COLORS.muted)
	app_theme.set_color("icon_pressed_color", "CheckBox", COLORS.success)
	app_theme.set_color("separator_color", "HSeparator", Color("#6b7658"))
	app_theme.set_stylebox("background", "ProgressBar", _style(Color("#041f28"), 9, Color("#34524e")))
	app_theme.set_stylebox("fill", "ProgressBar", _style(Color("#32bfae"), 9, COLORS.gold))
	theme = app_theme


func _apply_heading_fonts(node: Node) -> void:
	for child in node.get_children():
		if child is Label and child.get_theme_font_size("font_size") >= 26:
			child.add_theme_font_override("font", display_font)
			if not child.has_theme_color_override("font_color"):
				child.add_theme_color_override("font_color", COLORS.text)
		_apply_heading_fonts(child)


func _reset_dashboard_scroll() -> void:
	if is_instance_valid(dashboard_scroll):
		dashboard_scroll.scroll_vertical = 0


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = COLORS.background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	desktop_backdrop = TextureRect.new()
	desktop_backdrop.texture = load("res://assets/world/budget_world_island.png")
	desktop_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desktop_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desktop_backdrop.modulate = Color(0.42, 0.72, 0.66, 0.16)
	desktop_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop_backdrop)

	var backdrop_tint := ColorRect.new()
	backdrop_tint.color = Color(0.01, 0.07, 0.09, 0.58)
	backdrop_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	desktop_backdrop.add_child(backdrop_tint)

	var shell := VBoxContainer.new()
	app_shell = shell
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	add_child(shell)

	app_bar = _build_app_bar()
	shell.add_child(app_bar)

	mobile_navigation = _build_mobile_navigation()
	mobile_navigation.visible = false
	shell.add_child(mobile_navigation)

	var root := HBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 0)
	shell.add_child(root)

	sidebar_panel = _build_sidebar()
	root.add_child(sidebar_panel)

	dashboard_page = VBoxContainer.new()
	dashboard_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_page.add_theme_constant_override("separation", 18)
	dashboard_scroll = ScrollContainer.new()
	dashboard_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dashboard_scroll.add_child(dashboard_page)
	root.add_child(dashboard_scroll)

	dashboard_page.add_child(_build_header())

	dashboard_body = BoxContainer.new()
	dashboard_body.vertical = false
	dashboard_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_body.add_theme_constant_override("separation", 18)
	dashboard_page.add_child(dashboard_body)

	world_view = BudgetWorldView.new()
	world_view.custom_minimum_size = Vector2(700, 580)
	world_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dashboard_body.add_child(world_view)

	summary_panel = _build_summary_column()
	dashboard_body.add_child(summary_panel)

	mobile_dashboard_metrics = _build_mobile_dashboard_metrics()
	mobile_dashboard_metrics.visible = false
	dashboard_body.add_child(mobile_dashboard_metrics)
	mobile_dashboard_actions = _build_mobile_dashboard_actions()
	mobile_dashboard_actions.visible = false
	dashboard_body.add_child(mobile_dashboard_actions)

	month_flow_panel = _build_month_flow()
	dashboard_page.add_child(month_flow_panel)

	fixed_costs_page = _build_fixed_costs_page()
	fixed_costs_page.visible = false
	root.add_child(fixed_costs_page)

	savings_page = _build_savings_page()
	savings_page.visible = false
	root.add_child(savings_page)

	transactions_page = _build_transactions_page()
	transactions_page.visible = false
	root.add_child(transactions_page)


	setup_panel = _build_setup_panel()
	setup_panel.visible = false
	add_child(setup_panel)

	add_cost_panel = _build_add_cost_panel()
	add_cost_panel.visible = false
	add_child(add_cost_panel)

	month_change_panel = _build_month_change_panel()
	month_change_panel.visible = false
	add_child(month_change_panel)

	add_goal_panel = _build_add_goal_panel()
	add_goal_panel.visible = false
	add_child(add_goal_panel)

	deposit_panel = _build_deposit_panel()
	deposit_panel.visible = false
	add_child(deposit_panel)

	add_transaction_panel = _build_add_transaction_panel()
	add_transaction_panel.visible = false
	add_child(add_transaction_panel)

	confirmation_panel = _build_confirmation_panel()
	confirmation_panel.visible = false
	add_child(confirmation_panel)

	balance_panel = _build_balance_panel()
	balance_panel.visible = false
	add_child(balance_panel)

	fixed_payment_panel = _build_fixed_payment_panel()
	fixed_payment_panel.visible = false
	add_child(fixed_payment_panel)


func _build_app_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 48
	bar.add_theme_stylebox_override("panel", _style(Color("#031a23f2"), 0, Color("#3d625b")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("margin_left", 18)
	row.add_theme_constant_override("margin_right", 18)
	bar.add_child(row)

	var leaf := Label.new()
	leaf.text = "◈"
	leaf.add_theme_font_size_override("font_size", 22)
	leaf.add_theme_color_override("font_color", COLORS.accent)
	row.add_child(leaf)

	var title := Label.new()
	title.text = "Meine Budgetwelt"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", COLORS.text)
	row.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var local_status := Label.new()
	local_status.text = "●  Sicher lokal gespeichert"
	app_local_status = local_status
	local_status.add_theme_font_size_override("font_size", 12)
	local_status.add_theme_color_override("font_color", COLORS.success)
	row.add_child(local_status)
	return bar


func _build_summary_column() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 345
	column.add_theme_constant_override("separation", 16)
	column.add_child(_build_summary())
	column.add_child(_build_upcoming_costs())
	return column


func _build_upcoming_costs() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#15515b")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.add_theme_constant_override("margin_left", 18)
	column.add_theme_constant_override("margin_right", 18)
	column.add_theme_constant_override("margin_top", 14)
	column.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Nächste Fixkosten"
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	column.add_child(HSeparator.new())

	upcoming_cost_list = VBoxContainer.new()
	upcoming_cost_list.add_theme_constant_override("separation", 6)
	column.add_child(upcoming_cost_list)
	return panel


func _build_month_flow() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 104
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 17, Color("#15515b")))
	var row := BoxContainer.new()
	row.vertical = false
	week_cards = row
	row.add_theme_constant_override("separation", 10)
	row.add_theme_constant_override("margin_left", 18)
	row.add_theme_constant_override("margin_right", 18)
	row.add_theme_constant_override("margin_top", 12)
	row.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(row)

	var definitions := [
		["week_0", "❧", "Woche 1 · 01.–07.", COLORS.accent],
		["week_1", "❧", "Woche 2 · 08.–14.", Color("#8f70e8")],
		["week_2", "❧", "Woche 3 · 15.–21.", COLORS.warning],
		["week_3", "❧", "Woche 4 · 22.–Monatsende", Color("#4c9de8")],
	]
	for definition in definitions:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style(Color("#0b3942"), 14, definition[3]))
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 10)
		card.add_child(card_row)
		var icon := Label.new()
		icon.text = definition[1]
		icon.add_theme_font_size_override("font_size", 25)
		icon.add_theme_color_override("font_color", definition[3])
		card_row.add_child(icon)
		var labels := VBoxContainer.new()
		var caption := Label.new()
		caption.text = definition[2]
		caption.add_theme_color_override("font_color", COLORS.muted)
		labels.add_child(caption)
		var value := Label.new()
		value.text = "0,00 € übrig"
		value.add_theme_font_size_override("font_size", 18)
		value.add_theme_color_override("font_color", COLORS.text)
		labels.add_child(value)
		dashboard_flow_values[definition[0]] = value
		card_row.add_child(labels)
		row.add_child(card)
	return panel




func _build_mobile_dashboard_metrics() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for definition in [
		["balance", "KONTOSTAND", COLORS.accent],
		["free", "FREI VERFÜGBAR", Color("#5ee8db")],
	]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 110
		var card_style := _style(Color("#041b22ee"), 22, Color("#b98b42"))
		card_style.set_border_width_all(2)
		card.add_theme_stylebox_override("panel", card_style)
		var labels := VBoxContainer.new()
		labels.alignment = BoxContainer.ALIGNMENT_CENTER
		var title := Label.new()
		title.text = definition[1]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_override("font", display_font)
		title.add_theme_font_size_override("font_size", 15)
		title.add_theme_color_override("font_color", Color("#e3c37d"))
		labels.add_child(title)
		var ornament := Label.new()
		ornament.text = "◇"
		ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ornament.add_theme_color_override("font_color", definition[2])
		labels.add_child(ornament)
		var value := Label.new()
		value.text = "0,00 €"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_override("font", display_font)
		value.add_theme_font_size_override("font_size", 30)
		value.add_theme_color_override("font_color", Color("#f5ead1"))
		labels.add_child(value)
		mobile_dashboard_values[definition[0]] = value
		card.add_child(labels)
		row.add_child(card)
	return row


func _build_mobile_dashboard_actions() -> Control:
	var panel := PanelContainer.new()
	var parchment := _style(Color("#cdb27cf2"), 24, Color("#8a642f"))
	parchment.content_margin_left = 14
	parchment.content_margin_right = 14
	parchment.content_margin_top = 14
	parchment.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", parchment)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	for definition in [
		["fixed", "FIXKOSTEN", "fixed_costs"],
		["weekly", "WOCHENBUDGET", "transactions"],
	]:
		var button := Button.new()
		button.custom_minimum_size.y = 96
		button.text = ""
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#07191def"), 18, Color("#9f7638"))
		)
		button.pressed.connect(_show_page.bind(definition[2]))
		var content := HBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.add_theme_constant_override("margin_left", 18)
		content.add_theme_constant_override("margin_right", 18)
		var emblem := Label.new()
		emblem.text = "▤" if definition[0] == "fixed" else "◉"
		emblem.custom_minimum_size.x = 62
		emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emblem.add_theme_font_size_override("font_size", 34)
		emblem.add_theme_color_override("font_color", Color("#d8a958"))
		content.add_child(emblem)
		var labels := VBoxContainer.new()
		labels.alignment = BoxContainer.ALIGNMENT_CENTER
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = definition[1]
		title.add_theme_font_override("font", display_font)
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color("#e4c783"))
		labels.add_child(title)
		var value := Label.new()
		value.text = "0,00 €"
		value.add_theme_font_override("font", display_font)
		value.add_theme_font_size_override("font_size", 30)
		value.add_theme_color_override("font_color", Color("#f5ead1"))
		labels.add_child(value)
		mobile_dashboard_values[definition[0]] = value
		content.add_child(labels)
		var arrow := Label.new()
		arrow.text = "›"
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.add_theme_font_size_override("font_size", 40)
		arrow.add_theme_color_override("font_color", Color("#d8a958"))
		content.add_child(arrow)
		button.add_child(content)
		column.add_child(button)
	panel.add_child(column)
	return panel


func _build_mobile_navigation() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 88
	panel.add_theme_stylebox_override("panel", _style(Color("#03181ef8"), 0, Color("#b78b43")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_theme_constant_override("margin_left", 8)
	row.add_theme_constant_override("margin_right", 8)
	row.add_theme_constant_override("margin_top", 6)
	row.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(row)

	for item in [
		["res://assets/icons/home.svg", "Budget", "dashboard"],
		["res://assets/icons/fixed-costs.svg", "Fixkosten", "fixed_costs"],
		["res://assets/icons/savings.svg", "Sparen", "savings"],
		["res://assets/icons/bookings.svg", "Buchungen", "transactions"],
	]:
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size.y = 72
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, 0))
		button.add_theme_stylebox_override("hover", _style(Color("#0b3438"), 12, Color("#87662f")))
		button.pressed.connect(_show_page.bind(item[2]))
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := TextureRect.new()
		icon.texture = load(item[0])
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color("#d0aa64")
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		var label := Label.new()
		label.text = item[1]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", display_font)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("#d9c99d"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		button.add_child(content)
		button.set_meta("mobile_icon", icon)
		button.set_meta("mobile_label", label)
		mobile_nav_buttons[item[2]] = button
		row.add_child(button)
	return panel


func _build_sidebar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 220
	panel.add_theme_stylebox_override("panel", _style(COLORS.sidebar, 0))

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.add_theme_constant_override("margin_left", 16)
	column.add_theme_constant_override("margin_right", 16)
	column.add_theme_constant_override("margin_top", 24)
	column.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(column)

	var emblem_center := CenterContainer.new()
	emblem_center.custom_minimum_size.y = 112
	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(74, 74)
	emblem.add_theme_stylebox_override("panel", _style(Color("#07313a"), 37, COLORS.accent))
	var emblem_icon := TextureRect.new()
	emblem_icon.texture = load("res://assets/icons/leaf.svg")
	emblem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.add_child(emblem_icon)
	emblem_center.add_child(emblem)
	column.add_child(emblem_center)
	column.add_spacer(false)

	var items := [
		["res://assets/icons/home.svg", "Deine Budgetwelt"],
		["res://assets/icons/fixed-costs.svg", "Fixkosten"],
		["res://assets/icons/savings.svg", "Sparen"],
		["res://assets/icons/bookings.svg", "Buchungen"],
	]
	for index in items.size():
		var item: Array = items[index]
		var button := Button.new()
		button.text = str(item[1])
		button.icon = load(str(item[0]))
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", COLORS.text)
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#0a4952") if index == 0 else Color.TRANSPARENT, 12)
		)
		button.add_theme_stylebox_override("hover", _style(Color("#0d5660"), 12))
		if index == 0:
			button.pressed.connect(_show_page.bind("dashboard"))
		elif index == 1:
			button.pressed.connect(_show_page.bind("fixed_costs"))
		elif index == 2:
			button.pressed.connect(_show_page.bind("savings"))
		elif index == 3:
			button.pressed.connect(_show_page.bind("transactions"))
		else:
			button.pressed.connect(_show_not_ready.bind(str(item[1])))
		column.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var version := Label.new()
	version.text = "Version %s" % UpdateManager.get_current_version()
	version.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(version)

	var backup_button := Button.new()
	backup_button.text = "▣  Daten sichern"
	backup_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	backup_button.pressed.connect(_create_data_backup)
	column.add_child(backup_button)

	var restore_button := Button.new()
	restore_button.text = "↶  Daten wiederherstellen"
	restore_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	restore_button.pressed.connect(_open_restore_dialog)
	column.add_child(restore_button)

	var update_button := Button.new()
	update_button.text = "↻  Nach Updates suchen"
	update_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	update_button.pressed.connect(UpdateManager.check_for_updates)
	column.add_child(update_button)

	status_label = Label.new()
	status_label.text = "Lokale Datenspeicherung aktiv"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(status_label)

	return panel


func _build_header() -> Control:
	var row := BoxContainer.new()
	row.vertical = false
	dashboard_header = row
	row.custom_minimum_size.y = 74

	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Deine Budgetwelt"
	dashboard_title = title
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Alles Wichtige auf einen Blick"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	dashboard_month_label = subtitle
	titles.add_child(subtitle)
	row.add_child(titles)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	month_controls = HBoxContainer.new()
	month_controls.add_theme_constant_override("separation", 4)
	row.add_child(month_controls)

	var previous_month := Button.new()
	previous_month.text = "‹"
	previous_month.tooltip_text = "Vorheriger Monat"
	previous_month.custom_minimum_size = Vector2(48, 48)
	previous_month.add_theme_font_size_override("font_size", 24)
	previous_month.pressed.connect(_request_month_change.bind(-1))
	month_controls.add_child(previous_month)

	var current_month := Label.new()
	current_month.text = "Monat"
	current_month.custom_minimum_size.x = 130
	current_month.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_month.add_theme_font_size_override("font_size", 18)
	current_month.add_theme_color_override("font_color", COLORS.text)
	month_selector_label = current_month
	month_controls.add_child(current_month)

	var next_month := Button.new()
	next_month.text = "›"
	next_month.tooltip_text = "Nächster Monat"
	next_month.custom_minimum_size = Vector2(48, 48)
	next_month.add_theme_font_size_override("font_size", 24)
	next_month.pressed.connect(_request_month_change.bind(1))
	month_controls.add_child(next_month)

	var edit_button := Button.new()
	edit_button.text = "Monat einrichten"
	edit_button.custom_minimum_size = Vector2(160, 48)
	month_edit_button = edit_button
	edit_button.add_theme_font_size_override("font_size", 16)
	edit_button.add_theme_color_override("font_color", Color("#042226"))
	edit_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 14))
	edit_button.add_theme_stylebox_override("hover", _style(Color("#6ce8d7"), 14))
	edit_button.pressed.connect(_open_setup)
	month_controls.add_child(edit_button)

	return row


func _build_summary() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 345
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#15515b")))

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.add_theme_constant_override("margin_left", 20)
	column.add_theme_constant_override("margin_right", 20)
	column.add_theme_constant_override("margin_top", 18)
	column.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Monatsübersicht"
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	var change_balance := Button.new()
	change_balance.text = "Kontostand ändern"
	change_balance.custom_minimum_size.y = 38
	change_balance.add_theme_color_override("font_color", Color("#042226"))
	change_balance.add_theme_stylebox_override("normal", _style(COLORS.accent, 11))
	change_balance.add_theme_stylebox_override("hover", _style(Color("#6ce8d7"), 11))
	change_balance.pressed.connect(_open_balance_dialog)
	column.add_child(change_balance)

	var definitions := [
		["balance", "Kontostand", COLORS.accent],
		["fixed_costs_total", "Für Fixkosten reserviert", COLORS.warning],
		["available_now", "Aktuell verfügbar", COLORS.success],
		["freely_available", "Nach allen Fixkosten frei", COLORS.accent],
		["weekly_free_budget", "Wochenbudget", Color("#59bde8")],
		["weekly_expenses", "Diese Woche ausgegeben", COLORS.warning],
		["weekly_budget_remaining", "Diese Woche noch übrig", Color("#59bde8")],
		["after_savings", "Nach Sparziel verfügbar", Color("#b39dfa")],
	]
	for definition in definitions:
		column.add_child(HSeparator.new())
		column.add_child(_summary_row(definition[0], definition[1], definition[2]))

	var add_weekly_expense := Button.new()
	add_weekly_expense.text = "Wochenausgabe eintragen"
	add_weekly_expense.custom_minimum_size.y = 38
	add_weekly_expense.pressed.connect(_open_weekly_expense)
	column.add_child(add_weekly_expense)
	var add_weekly_credit := Button.new()
	add_weekly_credit.text = "Wochenbudget aufladen"
	add_weekly_credit.custom_minimum_size.y = 38
	add_weekly_credit.add_theme_color_override("font_color", COLORS.gold)
	add_weekly_credit.pressed.connect(_open_weekly_credit)
	column.add_child(add_weekly_credit)

	var hint := Label.new()
	hint.text = "ⓘ  Bezahlte Fixkosten bleiben in der Planung enthalten. So wird nichts doppelt abgezogen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_spacer(false)
	column.add_child(hint)

	return panel


func _summary_row(key: String, title_text: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 72
	row.add_theme_constant_override("separation", 12)

	var marker := ColorRect.new()
	marker.color = accent
	marker.custom_minimum_size = Vector2(4, 42)
	row.add_child(marker)

	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(46, 46)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_panel.add_theme_stylebox_override("panel", _style(Color(accent, 0.10), 23, Color(accent, 0.55)))
	var icon := Label.new()
	var icons := {
		"balance": "◉",
		"fixed_costs_total": "⌂",
		"available_now": "●",
		"freely_available": "◌",
		"weekly_free_budget": "◷",
		"weekly_expenses": "−",
		"weekly_budget_remaining": "✓",
		"after_savings": "♧",
	}
	icon.text = str(icons.get(key, "•"))
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 21)
	icon.add_theme_color_override("font_color", accent)
	icon_panel.add_child(icon)
	row.add_child(icon_panel)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", COLORS.muted)
	labels.add_child(title)

	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_size_override("font_size", 24)
	value.add_theme_color_override("font_color", COLORS.text)
	labels.add_child(value)
	summary_values[key] = value
	row.add_child(labels)
	return row


func _build_week_strip() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 100
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 16, Color("#15515b")))

	var row := BoxContainer.new()
	row.vertical = false
	week_cards = row
	row.add_theme_constant_override("separation", 12)
	row.add_theme_constant_override("margin_left", 18)
	row.add_theme_constant_override("margin_right", 18)
	row.add_theme_constant_override("margin_top", 14)
	row.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(row)

	for week in range(1, 5):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override(
			"panel",
			_style(Color("#0c3c45"), 14, Color("#1c6870"))
		)
		var text := Label.new()
		text.text = "Woche %d\nEinkaufsrahmen: 70,00 €" % week
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_color", COLORS.text)
		card.add_child(text)
		row.add_child(card)

	return panel


func _build_fixed_costs_page() -> Control:
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var art := TextureRect.new()
	fixed_page_art = art
	art.texture = load("res://assets/ui/fixed_costs_ledger_background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(art)

	var header := BoxContainer.new()
	header.vertical = false
	fixed_header = header
	header.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.anchor_left = 0.115
	header.anchor_top = 0.018
	header.anchor_right = 0.97
	header.anchor_bottom = 0.145
	header.offset_left = 0
	header.offset_top = 0
	header.offset_right = 0
	header.offset_bottom = 0
	page.add_child(header)

	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Fixkosten"
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#e9c878"))
	title.add_theme_color_override("font_shadow_color", Color("#120c06aa"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Wiederkehrende Kosten"
	subtitle.add_theme_font_override("font", display_font)
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("#d7bf88"))
	fixed_cost_month_label = subtitle
	titles.add_child(subtitle)
	header.add_child(titles)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var back_button := Button.new()
	back_button.text = "←  Zur Budgetwelt"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#091e22d8")))
	back_button.pressed.connect(_show_page.bind("dashboard"))
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Fixkosten hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#dfbd6a")))
	add_button.pressed.connect(_open_add_cost)
	header.add_child(add_button)

	fixed_summary_row = BoxContainer.new()
	fixed_summary_row.vertical = false
	fixed_summary_row.add_theme_constant_override("separation", 44)
	fixed_summary_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	fixed_summary_row.anchor_left = 0.128
	fixed_summary_row.anchor_top = 0.155
	fixed_summary_row.anchor_right = 0.872
	fixed_summary_row.anchor_bottom = 0.278
	fixed_summary_row.offset_left = 8
	fixed_summary_row.offset_top = 0
	fixed_summary_row.offset_right = -8
	fixed_summary_row.offset_bottom = 0
	fixed_summary_row.add_child(_fixed_summary_card("paid", "Bereits bezahlt", COLORS.success))
	fixed_summary_row.add_child(_fixed_summary_card("open", "Noch offen", COLORS.warning))
	fixed_summary_row.add_child(_fixed_summary_card("free", "Nach allen Fixkosten frei", COLORS.accent))
	page.add_child(fixed_summary_row)

	var list_panel := PanelContainer.new()
	fixed_list_panel = list_panel
	list_panel.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, 0))
	list_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_panel.anchor_left = 0.158
	list_panel.anchor_top = 0.325
	list_panel.anchor_right = 0.94
	list_panel.anchor_bottom = 0.905
	list_panel.offset_left = 0
	list_panel.offset_top = 0
	list_panel.offset_right = 0
	list_panel.offset_bottom = 0
	page.add_child(list_panel)

	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 2)
	list_panel.add_child(list_column)
	var list_header := BoxContainer.new()
	list_header.vertical = false
	fixed_list_header = list_header
	list_header.custom_minimum_size.y = 34
	for header_data in [
		["Kostenpunkt", 0],
		["Kategorie", 150],
		["Fällig", 120],
		["Betrag", 115],
		["Status", 215],
		["Aktionen", 144],
	]:
		var label := Label.new()
		label.text = header_data[0]
		label.custom_minimum_size.x = header_data[1]
		label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if header_data[1] == 0 else Control.SIZE_SHRINK_BEGIN
		)
		label.add_theme_font_override("font", display_font)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color("#4b321b"))
		list_header.add_child(label)
	list_column.add_child(list_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_column.add_child(scroll)
	fixed_cost_list = VBoxContainer.new()
	fixed_cost_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fixed_cost_list.add_theme_constant_override("separation", 1)
	scroll.add_child(fixed_cost_list)

	var hint := Label.new()
	hint.text = "Haken = vollständig bezahlt · € = Teilzahlung"
	fixed_hint_label = hint
	hint.add_theme_color_override("font_color", Color("#684c2d"))
	list_column.add_child(hint)

	_build_book_navigation(page, "fixed_costs")
	return page


func _build_book_navigation(page: Control, active_page: String) -> void:
	var nav := VBoxContainer.new()
	book_navigation_controls.append(nav)
	nav.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav.anchor_left = 0.012
	nav.anchor_top = 0.15
	nav.anchor_right = 0.102
	nav.anchor_bottom = 0.72
	nav.offset_left = 0
	nav.offset_top = 0
	nav.offset_right = 0
	nav.offset_bottom = 0
	nav.add_theme_constant_override("separation", 14)
	page.add_child(nav)

	for item in [
		["❧\nDeine\nBudgetwelt", "dashboard"],
		["▤\nFixkosten", "fixed_costs"],
		["♧\nSparen", "savings"],
		["▥\nBuchungen", "transactions"],
	]:
		var button := Button.new()
		button.text = item[0]
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font", display_font)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override(
			"font_color",
			Color("#efbd5b") if item[1] == active_page else Color("#d9c99d")
		)
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#07131422"), 12, Color.TRANSPARENT)
		)
		button.add_theme_stylebox_override(
			"hover",
			_style(Color("#0d2f2dbb"), 12, Color("#b88a43"))
		)
		button.pressed.connect(_show_page.bind(item[1]))
		nav.add_child(button)

	var utilities := VBoxContainer.new()
	book_navigation_controls.append(utilities)
	utilities.set_anchors_preset(Control.PRESET_FULL_RECT)
	utilities.anchor_left = 0.008
	utilities.anchor_top = 0.82
	utilities.anchor_right = 0.105
	utilities.anchor_bottom = 0.965
	utilities.offset_left = 0
	utilities.offset_top = 0
	utilities.offset_right = 0
	utilities.offset_bottom = 0
	utilities.add_theme_constant_override("separation", 8)
	page.add_child(utilities)
	var save_button := Button.new()
	save_button.text = "▣  Daten sichern"
	save_button.add_theme_color_override("font_color", Color("#dfc98f"))
	save_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#07191ad9")))
	save_button.pressed.connect(_create_data_backup)
	utilities.add_child(save_button)
	var restore_button := Button.new()
	restore_button.text = "↶  Wiederherstellen"
	restore_button.add_theme_color_override("font_color", Color("#dfc98f"))
	restore_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#07191ad9")))
	restore_button.pressed.connect(_open_restore_dialog)
	utilities.add_child(restore_button)
	var update_button := Button.new()
	update_button.text = "◌  Updates suchen"
	update_button.add_theme_color_override("font_color", Color("#dfc98f"))
	update_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#07191ad9")))
	update_button.pressed.connect(UpdateManager.check_for_updates)
	utilities.add_child(update_button)


func _fixed_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, 0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var plaque_inset := Control.new()
	plaque_inset.custom_minimum_size.x = 30
	row.add_child(plaque_inset)
	var emblem_panel := PanelContainer.new()
	emblem_panel.custom_minimum_size = Vector2(62, 62)
	emblem_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	emblem_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	emblem_panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#071f21cc"), 31, Color(accent, 0.75))
	)
	var emblem := Label.new()
	emblem.text = {
		"paid": "✓",
		"open": "◷",
		"free": "✦",
	}.get(key, "✦")
	emblem.custom_minimum_size = Vector2(62, 62)
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.add_theme_font_override("font", interface_font)
	emblem.add_theme_font_size_override("font_size", 30)
	emblem.add_theme_color_override("font_color", accent)
	emblem_panel.add_child(emblem)
	row.add_child(emblem_panel)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#d9c89e"))
	column.add_child(title)

	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_override("font", display_font)
	value.add_theme_font_size_override("font_size", 30)
	value.add_theme_color_override("font_color", Color("#f3d995"))
	column.add_child(value)
	fixed_summary_values[key] = value
	row.add_child(column)
	panel.add_child(row)
	return panel


func _rebuild_fixed_cost_rows() -> void:
	if not is_instance_valid(fixed_cost_list):
		return
	for child in fixed_cost_list.get_children():
		child.queue_free()

	var costs := FixedCostManager.get_costs()
	if costs.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Fixkosten angelegt."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		fixed_cost_list.add_child(empty)
		return

	for cost: Dictionary in costs:
		fixed_cost_list.add_child(_build_fixed_cost_row(cost))


func _build_fixed_cost_row(cost: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size.y = 205 if _compact_layout else 76
	row_panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#041b22f2"), 18, Color("#b98b42"))
		if _compact_layout else _parchment_row_style()
	)

	var row := BoxContainer.new()
	row.vertical = _compact_layout
	row.add_theme_constant_override("separation", 6 if _compact_layout else 12)
	row_panel.add_child(row)

	var paid_amount := float(cost.get(
		"paid_amount",
		float(cost.amount) if bool(cost.paid) else 0.0
	))

	var identity := HBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 10)
	var category_emblem_panel := PanelContainer.new()
	category_emblem_panel.custom_minimum_size = Vector2(48, 48)
	category_emblem_panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#173638"), 24, Color("#b58a45"))
	)
	var category_emblem := TextureRect.new()
	category_emblem.texture = load("res://assets/icons/fixed-costs.svg")
	category_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	category_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	category_emblem.custom_minimum_size = Vector2(30, 30)
	category_emblem.modulate = Color("#1fd3c2")
	category_emblem_panel.add_child(category_emblem)
	identity.add_child(category_emblem_panel)
	var identity_text := VBoxContainer.new()
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := Label.new()
	name.text = str(cost.name)
	name.add_theme_font_override("font", display_font)
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override(
		"font_color", Color("#f0d796") if _compact_layout else Color("#332315")
	)
	identity_text.add_child(name)
	var recurring := Label.new()
	recurring.text = {
		"monthly": "Monatlich",
		"quarterly": "Quartalsweise",
		"yearly": "Jährlich",
	}.get(str(cost.get("frequency", "monthly")), "Monatlich")
	if not bool(cost.get("due_this_month", true)):
		recurring.text += " · diesen Monat nicht fällig"
	recurring.add_theme_color_override(
		"font_color", Color("#a9c5bf") if _compact_layout else Color("#725437")
	)
	identity_text.add_child(recurring)
	identity.add_child(identity_text)
	row.add_child(identity)

	var category := Label.new()
	category.text = "%s  %s" % [_fixed_cost_icon(str(cost.category)), str(cost.category)]
	category.custom_minimum_size.x = 0 if _compact_layout else 170
	category.text = (
		"Kategorie: %s" % str(cost.category)
		if _compact_layout
		else category.text
	)
	category.add_theme_color_override("font_color", Color("#493722"))
	category.visible = not _compact_layout
	row.add_child(category)

	var due := Label.new()
	due.text = "%02d. des Monats" % int(cost.due_day)
	due.custom_minimum_size.x = 0 if _compact_layout else 130
	due.add_theme_color_override(
		"font_color", Color("#d4c18e") if _compact_layout else Color("#493722")
	)
	if _compact_layout:
		due.text = "Fällig: %02d. des Monats" % int(cost.due_day)
	row.add_child(due)

	var amount := Label.new()
	amount.text = _money(float(cost.amount))
	amount.custom_minimum_size.x = 0 if _compact_layout else 130
	amount.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT if _compact_layout else HORIZONTAL_ALIGNMENT_RIGHT
	)
	amount.add_theme_font_override("font", display_font)
	amount.add_theme_font_size_override("font_size", 18)
	amount.add_theme_color_override(
		"font_color", Color("#f6ead0") if _compact_layout else Color("#332315")
	)
	row.add_child(amount)

	var payment_status := VBoxContainer.new()
	payment_status.custom_minimum_size.x = 0 if _compact_layout else 250
	var paid := CheckBox.new()
	paid.text = "%s / %s" % [_money(paid_amount), _money(float(cost.amount))]
	paid.button_pressed = bool(cost.paid)
	paid.disabled = not bool(cost.get("due_this_month", true))
	if paid.disabled:
		paid.text = "Diesen Monat nicht fällig"
	paid.tooltip_text = "Haken setzt den Betrag vollständig bezahlt oder wieder auf offen."
	paid.add_theme_color_override(
		"font_color", Color("#e9dbb7") if _compact_layout else Color("#3e2b18")
	)
	paid.add_theme_color_override(
		"font_hover_color", Color("#ffffff") if _compact_layout else Color("#24170c")
	)
	paid.add_theme_color_override(
		"font_pressed_color", Color("#ffffff") if _compact_layout else Color("#24170c")
	)
	var paid_status_style := (
		_style(Color("#082c31ef"), 9, Color("#8e723f"))
		if _compact_layout else _style(Color("#ead7acee"), 9, Color("#9a7746"))
	)
	paid_status_style.content_margin_top = 6
	paid_status_style.content_margin_bottom = 6
	paid.add_theme_stylebox_override("normal", paid_status_style)
	paid.add_theme_stylebox_override("hover", _style(Color("#f3e3bdf5"), 9, Color("#b48b4d")))
	paid.add_theme_stylebox_override("pressed", _style(Color("#dcc38df5"), 9, Color("#8b6938")))
	paid.toggled.connect(_toggle_fixed_cost.bind(str(cost.id)))
	payment_status.add_child(paid)
	var progress := ProgressBar.new()
	progress.show_percentage = true
	progress.max_value = maxf(float(cost.amount), 0.01)
	progress.value = paid_amount
	progress.custom_minimum_size.y = 13
	progress.add_theme_font_size_override("font_size", 10)
	progress.add_theme_color_override("font_color", Color("#2d2013"))
	progress.add_theme_stylebox_override("background", _style(Color("#b99b6970"), 6))
	progress.add_theme_stylebox_override("fill", _style(Color("#0aa89b"), 6))
	payment_status.add_child(progress)
	row.add_child(payment_status)

	var actions := HBoxContainer.new()
	actions.custom_minimum_size.x = 0 if _compact_layout else 156
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 6)

	var payment := Button.new()
	payment.text = "€"
	payment.tooltip_text = "Teilzahlung für %s eintragen" % str(cost.name)
	payment.custom_minimum_size = Vector2(42, 42)
	if _compact_layout:
		payment.text = "€"
		payment.custom_minimum_size = Vector2(0, 42)
		payment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	payment.add_theme_color_override("font_color", Color("#e8cf8d"))
	payment.add_theme_stylebox_override("normal", _ornament_button_style(Color("#183739")))
	payment.pressed.connect(_open_fixed_payment.bind(str(cost.id)))
	payment.disabled = not bool(cost.get("due_this_month", true))
	actions.add_child(payment)

	var edit := Button.new()
	edit.text = "✎"
	edit.tooltip_text = "%s bearbeiten" % str(cost.name)
	edit.custom_minimum_size = Vector2(42, 42)
	if _compact_layout:
		edit.text = "•••"
		edit.custom_minimum_size = Vector2(0, 42)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_color_override("font_color", Color("#e8cf8d"))
	edit.add_theme_stylebox_override("normal", _ornament_button_style(Color("#183739")))
	edit.pressed.connect(_open_edit_cost.bind(str(cost.id)))
	actions.add_child(edit)

	var remove := Button.new()
	remove.text = "⌫"
	remove.tooltip_text = "%s löschen" % str(cost.name)
	remove.custom_minimum_size = Vector2(42, 42)
	if _compact_layout:
		remove.text = "×"
		remove.custom_minimum_size = Vector2(0, 42)
		remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove.add_theme_color_override("font_color", Color("#e8b45f"))
	remove.add_theme_stylebox_override("normal", _ornament_button_style(Color("#382b20")))
	remove.pressed.connect(_remove_fixed_cost.bind(str(cost.id)))
	actions.add_child(remove)
	if _compact_layout:
		edit.visible = false
		remove.visible = false
		var more := MenuButton.new()
		more.text = "•••"
		more.custom_minimum_size = Vector2(68, 42)
		more.add_theme_color_override("font_color", Color("#e8cf8d"))
		more.add_theme_stylebox_override("normal", _ornament_button_style(Color("#183739")))
		var popup := more.get_popup()
		popup.add_item("Bearbeiten", 0)
		popup.add_item("Kostenpunkt löschen", 1)
		popup.id_pressed.connect(
			func(action_id: int) -> void:
				if action_id == 0:
					_open_edit_cost(str(cost.id))
				else:
					_remove_fixed_cost(str(cost.id))
		)
		actions.add_child(more)
	row.add_child(actions)
	return row_panel


func _build_savings_page() -> Control:
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var art := TextureRect.new()
	savings_page_art = art
	art.texture = load("res://assets/ui/fixed_costs_ledger_background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(art)

	var header := BoxContainer.new()
	header.vertical = false
	savings_header = header
	header.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.anchor_left = 0.115
	header.anchor_top = 0.018
	header.anchor_right = 0.97
	header.anchor_bottom = 0.145
	header.offset_left = 0
	header.offset_top = 0
	header.offset_right = 0
	header.offset_bottom = 0
	page.add_child(header)
	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Sparziele"
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#e9c878"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Baue deine Rücklagen Schritt für Schritt auf"
	subtitle.add_theme_font_override("font", display_font)
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("#d7bf88"))
	titles.add_child(subtitle)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var back_button := Button.new()
	back_button.text = "←  Zur Budgetwelt"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#091e22d8")))
	back_button.pressed.connect(_show_page.bind("dashboard"))
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Sparziel hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#dfbd6a")))
	add_button.pressed.connect(_open_add_goal)
	header.add_child(add_button)

	savings_summary_row = BoxContainer.new()
	savings_summary_row.vertical = false
	savings_summary_row.add_theme_constant_override("separation", 44)
	savings_summary_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	savings_summary_row.anchor_left = 0.128
	savings_summary_row.anchor_top = 0.155
	savings_summary_row.anchor_right = 0.872
	savings_summary_row.anchor_bottom = 0.278
	savings_summary_row.offset_left = 8
	savings_summary_row.offset_top = 0
	savings_summary_row.offset_right = -8
	savings_summary_row.offset_bottom = 0
	savings_summary_row.add_child(
		_savings_summary_card("saved", "Bereits gespart", COLORS.success)
	)
	savings_summary_row.add_child(
		_savings_summary_card("remaining", "Bis zu allen Zielen", Color("#b39dfa"))
	)
	savings_summary_row.add_child(
		_savings_summary_card("monthly", "Monatlich reserviert", COLORS.accent)
	)
	page.add_child(savings_summary_row)

	var list_panel := PanelContainer.new()
	savings_list_panel = list_panel
	list_panel.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, 0))
	list_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_panel.anchor_left = 0.158
	list_panel.anchor_top = 0.325
	list_panel.anchor_right = 0.94
	list_panel.anchor_bottom = 0.905
	list_panel.offset_left = 0
	list_panel.offset_top = 0
	list_panel.offset_right = 0
	list_panel.offset_bottom = 0
	page.add_child(list_panel)
	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 8)
	list_panel.add_child(list_column)
	var list_title := Label.new()
	list_title.text = "Meine Ziele"
	savings_list_title = list_title
	list_title.add_theme_font_override("font", display_font)
	list_title.add_theme_font_size_override("font_size", 20)
	list_title.add_theme_color_override("font_color", Color("#4b321b"))
	list_column.add_child(list_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_column.add_child(scroll)
	savings_list = VBoxContainer.new()
	savings_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	savings_list.add_theme_constant_override("separation", 12)
	scroll.add_child(savings_list)
	_build_book_navigation(page, "savings")
	return page


func _savings_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 112
	var plaque_content_style := _style(Color.TRANSPARENT, 0)
	plaque_content_style.content_margin_left = 82 if key == "saved" else 42
	plaque_content_style.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", plaque_content_style)

	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#d9c89e"))
	column.add_child(title)

	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_override("font", display_font)
	value.add_theme_font_size_override("font_size", 30)
	value.add_theme_color_override("font_color", Color("#f3d995"))
	column.add_child(value)
	savings_summary_values[key] = value
	panel.add_child(column)
	return panel


func _rebuild_savings_rows() -> void:
	if not is_instance_valid(savings_list):
		return
	for child in savings_list.get_children():
		child.queue_free()

	var goals := SavingsManager.get_goals()
	if goals.is_empty():
		var empty := Label.new()
		empty.text = "Noch kein Sparziel angelegt."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override(
			"font_color", Color("#e8ce91") if _compact_layout else Color("#5b432a")
		)
		savings_list.add_child(empty)
		return

	for goal: Dictionary in goals:
		savings_list.add_child(_build_savings_goal_card(goal))


func _build_savings_goal_card(goal: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 190 if _compact_layout else 0
	var card_style := (
		_style(Color("#041b22f2"), 18, Color("#b98b42"))
		if _compact_layout else _style(Color("#fff4d218"), 12, Color("#8e6e3f44"))
	)
	card_style.content_margin_left = 18 if _compact_layout else 0
	card_style.content_margin_right = 18 if _compact_layout else 0
	card_style.content_margin_top = 14 if _compact_layout else 0
	card_style.content_margin_bottom = 14 if _compact_layout else 0
	panel.add_theme_stylebox_override("panel", card_style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	var header := HBoxContainer.new()
	var name := Label.new()
	name.text = str(goal.name)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 27 if _compact_layout else 21)
	name.add_theme_font_override("font", display_font)
	name.add_theme_color_override(
		"font_color", Color("#f0d796") if _compact_layout else Color("#332315")
	)
	header.add_child(name)

	var percentage := Label.new()
	percentage.text = "%d %%" % roundi(
		float(goal.saved_amount) / float(goal.target_amount) * 100.0
	)
	percentage.add_theme_color_override("font_color", Color("#087c70"))
	percentage.add_theme_font_size_override("font_size", 18 if _compact_layout else 15)
	header.add_child(percentage)
	column.add_child(header)

	var progress := ProgressBar.new()
	progress.min_value = 0.0
	progress.max_value = float(goal.target_amount)
	progress.value = float(goal.saved_amount)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 18
	progress.add_theme_stylebox_override("background", _style(Color("#b99b6970"), 8))
	progress.add_theme_stylebox_override("fill", _style(Color("#0aa89b"), 8))
	column.add_child(progress)

	var details := Label.new()
	details.text = "%s von %s  ·  monatlich %s" % [
		_money(float(goal.saved_amount)),
		_money(float(goal.target_amount)),
		_money(float(goal.monthly_contribution)),
	]
	details.add_theme_color_override(
		"font_color", Color("#b8cbc4") if _compact_layout else Color("#5b432a")
	)
	details.add_theme_font_size_override("font_size", 16 if _compact_layout else 15)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)

	var actions := HBoxContainer.new()
	var deposit := Button.new()
	deposit.text = "+ Einzahlung eintragen"
	deposit.custom_minimum_size.y = 46 if _compact_layout else 0
	deposit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deposit.add_theme_color_override("font_color", Color("#e8cf8d"))
	deposit.add_theme_stylebox_override("normal", _ornament_button_style(Color("#183739")))
	deposit.pressed.connect(_open_deposit.bind(str(goal.id), str(goal.name)))
	actions.add_child(deposit)

	var remove := Button.new()
	remove.text = "•••" if _compact_layout else "Ziel löschen"
	remove.custom_minimum_size = Vector2(64, 46) if _compact_layout else Vector2.ZERO
	remove.add_theme_color_override("font_color", Color("#e8b45f"))
	remove.add_theme_stylebox_override("normal", _ornament_button_style(Color("#382b20")))
	remove.pressed.connect(_remove_savings_goal.bind(str(goal.id)))
	actions.add_child(remove)
	column.add_child(actions)
	return panel


func _build_add_goal_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(560, 570)
	add_goal_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 26)
	column.add_theme_constant_override("margin_bottom", 26)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Neues Sparziel"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	column.add_child(_field_label("Bezeichnung"))
	goal_name_input = LineEdit.new()
	goal_name_input.placeholder_text = "Zum Beispiel Urlaub oder Notgroschen"
	goal_name_input.custom_minimum_size.y = 44
	column.add_child(goal_name_input)

	column.add_child(_field_label("Zielbetrag"))
	goal_target_input = _create_savings_money_input()
	column.add_child(goal_target_input)

	column.add_child(_field_label("Bereits gespart"))
	goal_saved_input = _create_savings_money_input()
	column.add_child(goal_saved_input)

	column.add_child(_field_label("Monatlich reservieren"))
	goal_monthly_input = _create_savings_money_input()
	column.add_child(goal_monthly_input)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: add_goal_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Sparziel speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_new_goal)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _create_savings_money_input() -> SpinBox:
	var input := SpinBox.new()
	input.min_value = 0.0
	input.max_value = 1000000.0
	input.step = 0.01
	input.suffix = " €"
	input.custom_minimum_size.y = 44
	_prepare_amount_input(input)
	return input


func _build_deposit_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(500, 330)
	deposit_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	deposit_goal_title = Label.new()
	deposit_goal_title.text = "Einzahlung"
	deposit_goal_title.add_theme_font_size_override("font_size", 28)
	deposit_goal_title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(deposit_goal_title)

	column.add_child(_field_label("Zusätzlich gesparter Betrag"))
	deposit_amount_input = _create_savings_money_input()
	column.add_child(deposit_amount_input)

	var hint := Label.new()
	hint.text = "Die Einzahlung erhöht den Fortschritt. Die monatliche Sparrate wird nicht erneut abgezogen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void: deposit_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Einzahlung speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_deposit)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_transactions_page() -> Control:
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var art := TextureRect.new()
	transactions_page_art = art
	art.texture = load("res://assets/ui/transactions_ledger_background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.add_child(art)

	var header := BoxContainer.new()
	header.vertical = false
	transactions_header = header
	header.set_anchors_preset(Control.PRESET_FULL_RECT)
	header.anchor_left = 0.115
	header.anchor_top = 0.018
	header.anchor_right = 0.97
	header.anchor_bottom = 0.145
	header.offset_left = 0
	header.offset_top = 0
	header.offset_right = 0
	header.offset_bottom = 0
	page.add_child(header)
	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Buchungen"
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#e9c878"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Einnahmen und Ausgaben des ausgewählten Monats"
	subtitle.add_theme_font_override("font", display_font)
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("#d7bf88"))
	titles.add_child(subtitle)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var back_button := Button.new()
	back_button.text = "←  Zur Budgetwelt"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#091e22d8")))
	back_button.pressed.connect(_show_page.bind("dashboard"))
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Buchung hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#dfbd6a")))
	add_button.pressed.connect(_open_add_transaction)
	header.add_child(add_button)

	transaction_summary_row = BoxContainer.new()
	transaction_summary_row.vertical = false
	transaction_summary_row.add_theme_constant_override("separation", 20)
	transaction_summary_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	transaction_summary_row.anchor_left = 0.127
	transaction_summary_row.anchor_top = 0.155
	transaction_summary_row.anchor_right = 0.902
	transaction_summary_row.anchor_bottom = 0.278
	transaction_summary_row.offset_left = 8
	transaction_summary_row.offset_top = 0
	transaction_summary_row.offset_right = -8
	transaction_summary_row.offset_bottom = 0
	transaction_summary_row.add_child(
		_transaction_summary_card("income", "Zusätzliche Einnahmen", COLORS.success)
	)
	transaction_summary_row.add_child(
		_transaction_summary_card("expenses", "Freie Ausgaben", COLORS.warning)
	)
	transaction_summary_row.add_child(
		_transaction_summary_card("savings", "Sparzahlungen", Color("#b39dfa"))
	)
	transaction_summary_row.add_child(
		_transaction_summary_card("available", "Aktuell verfügbar", COLORS.accent)
	)
	page.add_child(transaction_summary_row)

	var list_panel := PanelContainer.new()
	transactions_list_panel = list_panel
	list_panel.add_theme_stylebox_override("panel", _style(Color.TRANSPARENT, 0))
	list_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_panel.anchor_left = 0.158
	list_panel.anchor_top = 0.325
	list_panel.anchor_right = 0.94
	list_panel.anchor_bottom = 0.905
	list_panel.offset_left = 0
	list_panel.offset_top = 0
	list_panel.offset_right = 0
	list_panel.offset_bottom = 0
	page.add_child(list_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	list_panel.add_child(column)
	var list_header := BoxContainer.new()
	list_header.vertical = false
	transaction_list_header = list_header
	list_header.add_theme_constant_override("separation", 10)
	var list_title := Label.new()
	list_title.text = "Verlauf"
	transaction_list_title = list_title
	list_title.add_theme_font_override("font", display_font)
	list_title.add_theme_font_size_override("font_size", 21)
	list_title.add_theme_color_override("font_color", Color("#4b321b"))
	list_header.add_child(list_title)
	var list_spacer := Control.new()
	list_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_header.add_child(list_spacer)
	transaction_filter_summary = Label.new()
	transaction_filter_summary.add_theme_color_override("font_color", Color("#5b432a"))
	list_header.add_child(transaction_filter_summary)
	transaction_weekly_filter_button = Button.new()
	transaction_weekly_filter_button.text = "Nur Wochenbudget"
	transaction_weekly_filter_button.toggle_mode = true
	transaction_weekly_filter_button.custom_minimum_size = Vector2(180, 42)
	transaction_weekly_filter_button.add_theme_color_override("font_color", Color("#e8cf8d"))
	transaction_weekly_filter_button.add_theme_stylebox_override(
		"normal",
		_ornament_button_style(Color("#183739"))
	)
	transaction_weekly_filter_button.toggled.connect(_on_weekly_filter_toggled)
	list_header.add_child(transaction_weekly_filter_button)
	column.add_child(list_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	transaction_list = VBoxContainer.new()
	transaction_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transaction_list.add_theme_constant_override("separation", 8)
	scroll.add_child(transaction_list)
	_build_book_navigation(page, "transactions")
	return page


func _transaction_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 105
	var plaque_content_style := _style(Color.TRANSPARENT, 0)
	plaque_content_style.content_margin_left = 42
	plaque_content_style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", plaque_content_style)

	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_color_override("font_color", Color("#d9c89e"))
	column.add_child(title)

	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_override("font", display_font)
	value.add_theme_font_size_override("font_size", 26)
	value.add_theme_color_override("font_color", Color("#f3d995"))
	column.add_child(value)
	transaction_summary_values[key] = value
	panel.add_child(column)
	return panel


func _rebuild_transaction_rows() -> void:
	if not is_instance_valid(transaction_list):
		return
	for child in transaction_list.get_children():
		child.queue_free()

	var all_transactions := TransactionManager.get_active_transactions()
	var weekly_only := (
		is_instance_valid(transaction_weekly_filter_button)
		and transaction_weekly_filter_button.button_pressed
	)
	var transactions := _filter_weekly_transactions(all_transactions) if weekly_only else all_transactions
	transactions.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.day) > int(b.day)
	)
	if transactions.is_empty():
		var empty := Label.new()
		empty.text = (
			"Für diesen Monat gibt es noch keine Einträge im Wochenbudget."
			if weekly_only
			else "Für diesen Monat sind noch keine Buchungen vorhanden."
		)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.custom_minimum_size.x = 0
		empty.add_theme_color_override(
			"font_color", Color("#e8ce91") if _compact_layout else Color("#5b432a")
		)
		transaction_list.add_child(empty)
		_update_transaction_filter_summary(all_transactions, weekly_only)
		return

	for transaction: Dictionary in transactions:
		transaction_list.add_child(_build_transaction_row(transaction))
	_update_transaction_filter_summary(all_transactions, weekly_only)


func _filter_weekly_transactions(transactions: Array) -> Array:
	return transactions.filter(
		func(transaction: Variant) -> bool:
			return (
				transaction is Dictionary
				and str(transaction.get("kind", "")) in ["expense", "weekly_credit"]
				and str(transaction.get("category", "")) == "Wochenbudget"
			)
	)


func _update_transaction_filter_summary(transactions: Array, weekly_only: bool) -> void:
	if not is_instance_valid(transaction_filter_summary):
		return
	var weekly_transactions := _filter_weekly_transactions(transactions)
	var spent := 0.0
	var credited := 0.0
	for transaction: Dictionary in weekly_transactions:
		if str(transaction.get("kind", "")) == "weekly_credit":
			credited += float(transaction.get("amount", 0.0))
		else:
			spent += float(transaction.get("amount", 0.0))
	transaction_filter_summary.text = (
		"%d Einträge · +%s · −%s" % [
			weekly_transactions.size(),
			_money(credited),
			_money(spent),
		]
		if weekly_only
		else ""
	)


func _on_weekly_filter_toggled(enabled: bool) -> void:
	transaction_weekly_filter_button.text = (
		"Alle Buchungen zeigen" if enabled else "Nur Wochenbudget"
	)
	_rebuild_transaction_rows()


func _build_transaction_row(transaction: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 78 if _compact_layout else 0
	var transaction_style := (
		_style(Color("#041b22f2"), 14, Color("#b98b42"))
		if _compact_layout else _style(Color("#fff4d218"), 10, Color("#8e6e3f44"))
	)
	transaction_style.content_margin_left = 8 if _compact_layout else 0
	transaction_style.content_margin_right = 8 if _compact_layout else 0
	panel.add_theme_stylebox_override("panel", transaction_style)

	var row := HBoxContainer.new()
	panel.add_child(row)

	var day := Label.new()
	day.text = "%02d." % int(transaction.day)
	day.custom_minimum_size.x = 42 if _compact_layout else 68
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day.add_theme_font_size_override("font_size", 18)
	day.add_theme_color_override(
		"font_color", Color("#d6bb78") if _compact_layout else Color("#73552f")
	)
	row.add_child(day)

	var description_column := VBoxContainer.new()
	description_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var description := Label.new()
	description.text = str(transaction.description)
	description.clip_text = _compact_layout
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_size_override("font_size", 17 if _compact_layout else 18)
	description.add_theme_font_override("font", display_font)
	description.add_theme_color_override(
		"font_color", Color("#f0d796") if _compact_layout else Color("#332315")
	)
	description_column.add_child(description)

	var category := Label.new()
	category.text = str(transaction.category)
	if str(transaction.category) == "Wochenbudget":
		var week_number := mini(
			floori(float(clampi(int(transaction.day), 1, 31) - 1) / 7.0),
			3
		) + 1
		category.text = "Wochenbudget · Woche %d" % week_number
	category.add_theme_color_override(
		"font_color", Color("#a9c5bf") if _compact_layout else Color("#5b432a")
	)
	description_column.add_child(category)
	row.add_child(description_column)

	var kind := str(transaction.kind)
	var amount := Label.new()
	amount.text = ("%s%s" % [
		"+" if kind in ["income", "weekly_credit"] else "−",
		_money(float(transaction.amount)),
	])
	amount.custom_minimum_size.x = 92 if _compact_layout else 150
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.add_theme_font_size_override("font_size", 17 if _compact_layout else 19)
	amount.add_theme_color_override(
		"font_color",
		Color("#98681c") if kind == "weekly_credit"
		else Color("#087c70") if kind == "income"
		else Color("#7454a0") if kind == "saving"
		else Color("#a54f2a")
	)
	row.add_child(amount)

	var remove := Button.new()
	remove.text = "⌫"
	remove.tooltip_text = "Buchung löschen"
	remove.custom_minimum_size = Vector2(42, 42)
	if _compact_layout:
		remove.text = "›"
		remove.custom_minimum_size = Vector2(32, 42)
	remove.add_theme_color_override("font_color", Color("#e8b45f"))
	remove.add_theme_stylebox_override("normal", _ornament_button_style(Color("#382b20")))
	remove.pressed.connect(_remove_transaction.bind(str(transaction.id)))
	row.add_child(remove)
	return panel


func _build_add_transaction_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(560, 620)
	add_transaction_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 11)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 24)
	column.add_theme_constant_override("margin_bottom", 24)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Neue Buchung"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	column.add_child(_field_label("Art"))
	transaction_kind_input = OptionButton.new()
	transaction_kind_input.add_item("Ausgabe")
	transaction_kind_input.add_item("Einnahme")
	transaction_kind_input.add_item("Sparzahlung")
	transaction_kind_input.add_item("Wochenbudget aufladen")
	transaction_kind_input.custom_minimum_size.y = 44
	column.add_child(transaction_kind_input)

	column.add_child(_field_label("Kategorie"))
	transaction_category_input = OptionButton.new()
	for category_name in [
		"Lebensmittel",
		"Wochenbudget",
		"Freizeit",
		"Mobilität",
		"Haushalt",
		"Gesundheit",
		"Gehalt",
		"Sparen",
		"Sonstiges",
	]:
		transaction_category_input.add_item(category_name)
	transaction_category_input.custom_minimum_size.y = 44
	column.add_child(transaction_category_input)

	column.add_child(_field_label("Beschreibung"))
	transaction_description_input = LineEdit.new()
	transaction_description_input.placeholder_text = "Zum Beispiel Wocheneinkauf"
	transaction_description_input.custom_minimum_size.y = 44
	column.add_child(transaction_description_input)

	column.add_child(_field_label("Betrag"))
	transaction_amount_input = _create_savings_money_input()
	column.add_child(transaction_amount_input)

	column.add_child(_field_label("Tag im Monat"))
	transaction_day_input = SpinBox.new()
	transaction_day_input.min_value = 1
	transaction_day_input.max_value = 31
	transaction_day_input.step = 1
	transaction_day_input.suffix = ". Tag"
	transaction_day_input.custom_minimum_size.y = 44
	column.add_child(transaction_day_input)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: add_transaction_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Buchung speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_new_transaction)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_shopping_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 76
	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Wocheneinkauf"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Plane deinen Einkauf innerhalb des Wochenbudgets"
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(subtitle)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var meal_plan := Button.new()
	meal_plan.text = "7-Tage-Speiseplan"
	meal_plan.custom_minimum_size = Vector2(190, 48)
	meal_plan.pressed.connect(_show_page.bind("meal_plan"))
	header.add_child(meal_plan)
	var back := Button.new()
	back.text = "←  Zur Budgetwelt"
	back.custom_minimum_size = Vector2(170, 48)
	back.pressed.connect(_show_page.bind("dashboard"))
	header.add_child(back)
	var add := Button.new()
	add.text = "+  Artikel hinzufügen"
	add.custom_minimum_size = Vector2(190, 48)
	add.add_theme_color_override("font_color", Color("#042226"))
	add.add_theme_stylebox_override("normal", _style(COLORS.accent, 14))
	add.pressed.connect(_open_add_shopping_item)
	header.add_child(add)
	page.add_child(header)

	var week_row := HBoxContainer.new()
	week_row.add_theme_constant_override("separation", 8)
	for week in range(1, 6):
		var button := Button.new()
		button.text = "Woche %d" % week
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.pressed.connect(ShoppingManager.set_active_week.bind(week))
		shopping_week_buttons.append(button)
		week_row.add_child(button)
	page.add_child(week_row)

	shopping_summary_row = BoxContainer.new()
	shopping_summary_row.vertical = false
	shopping_summary_row.add_theme_constant_override("separation", 12)
	shopping_summary_row.add_child(
		_shopping_summary_card("budget", "Wochenbudget", COLORS.accent)
	)
	shopping_summary_row.add_child(
		_shopping_summary_card("planned", "Geplant", COLORS.warning)
	)
	shopping_summary_row.add_child(
		_shopping_summary_card("remaining", "Noch verfügbar", COLORS.success)
	)
	page.add_child(shopping_summary_row)

	var list_panel := PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#15515b")))
	var list_column := VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 10)
	list_column.add_theme_constant_override("margin_left", 18)
	list_column.add_theme_constant_override("margin_right", 18)
	list_column.add_theme_constant_override("margin_top", 16)
	list_column.add_theme_constant_override("margin_bottom", 16)
	list_panel.add_child(list_column)

	var list_title := Label.new()
	list_title.text = "Einkaufsliste"
	list_title.add_theme_font_size_override("font_size", 21)
	list_title.add_theme_color_override("font_color", COLORS.text)
	list_column.add_child(list_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_column.add_child(scroll)
	shopping_list = VBoxContainer.new()
	shopping_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shopping_list.add_theme_constant_override("separation", 8)
	scroll.add_child(shopping_list)

	shopping_book_button = Button.new()
	shopping_book_button.text = "Abgehakte Artikel als Einkauf verbuchen"
	shopping_book_button.custom_minimum_size.y = 50
	shopping_book_button.add_theme_color_override("font_color", Color("#042226"))
	shopping_book_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	shopping_book_button.pressed.connect(_book_shopping)
	list_column.add_child(shopping_book_button)
	page.add_child(list_panel)
	return page


func _shopping_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 100
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 16, accent))
	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(title)
	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_size_override("font_size", 25)
	value.add_theme_color_override("font_color", accent)
	column.add_child(value)
	shopping_summary_values[key] = value
	panel.add_child(column)
	return panel


func _rebuild_shopping_rows() -> void:
	if not is_instance_valid(shopping_list):
		return
	for child in shopping_list.get_children():
		child.queue_free()

	var items := ShoppingManager.get_items()
	var booked := ShoppingManager.is_booked()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Artikel für diese Woche eingetragen."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", COLORS.muted)
		shopping_list.add_child(empty)
	else:
		for item: Dictionary in items:
			shopping_list.add_child(_build_shopping_row(item, booked))


func _build_shopping_row(item: Dictionary, booked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#0b3640"), 12))
	var row := HBoxContainer.new()
	panel.add_child(row)

	var checked := CheckBox.new()
	checked.button_pressed = bool(item.checked)
	checked.disabled = booked
	checked.custom_minimum_size.x = 48
	checked.toggled.connect(_toggle_shopping_item.bind(str(item.id)))
	row.add_child(checked)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := Label.new()
	name.text = str(item.name)
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", COLORS.text)
	labels.add_child(name)
	var quantity := Label.new()
	quantity.text = str(item.quantity)
	var pack_plan := str(item.get("pack_plan", ""))
	if not pack_plan.is_empty():
		quantity.text = "Kaufen: %s  ·  %s" % [str(item.quantity), pack_plan]
		var required := str(item.get("required_quantity", ""))
		var surplus := str(item.get("surplus_quantity", ""))
		if not required.is_empty():
			quantity.text += "\nBedarf: %s  ·  Überschuss: %s" % [required, surplus]
	quantity.add_theme_color_override("font_color", COLORS.muted)
	labels.add_child(quantity)
	row.add_child(labels)

	var price := Label.new()
	price.text = _money(float(item.estimated_price))
	price.custom_minimum_size.x = 130
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.add_theme_font_size_override("font_size", 18)
	price.add_theme_color_override("font_color", COLORS.text)
	row.add_child(price)

	var remove := Button.new()
	remove.text = "×"
	remove.disabled = booked
	remove.tooltip_text = "Artikel löschen"
	remove.custom_minimum_size = Vector2(42, 42)
	remove.add_theme_color_override("font_color", COLORS.warning)
	remove.pressed.connect(_remove_shopping_item.bind(str(item.id)))
	row.add_child(remove)
	return panel


func _build_add_shopping_item_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))
	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(540, 470)
	add_shopping_item_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 13)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 26)
	column.add_theme_constant_override("margin_bottom", 26)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Artikel hinzufügen"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)
	column.add_child(_field_label("Lebensmittel oder Produkt"))
	shopping_name_input = LineEdit.new()
	shopping_name_input.placeholder_text = "Zum Beispiel Kartoffeln"
	shopping_name_input.custom_minimum_size.y = 44
	column.add_child(shopping_name_input)
	column.add_child(_field_label("Menge"))
	shopping_quantity_input = LineEdit.new()
	shopping_quantity_input.placeholder_text = "Zum Beispiel 2 kg"
	shopping_quantity_input.custom_minimum_size.y = 44
	column.add_child(shopping_quantity_input)
	column.add_child(_field_label("Geschätzter Packungspreis"))
	shopping_price_input = _create_savings_money_input()
	shopping_price_input.step = 0.1
	column.add_child(shopping_price_input)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: add_shopping_item_panel.visible = false)
	buttons.add_child(cancel)
	var save := Button.new()
	save.text = "Artikel speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_shopping_item)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_meal_plan_page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 80
	var titles := VBoxContainer.new()
	var title := Label.new()
	title.text = "Sparplan für 2 Personen"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", COLORS.text)
	titles.add_child(title)
	meal_week_label = Label.new()
	meal_week_label.text = "Woche 1"
	meal_week_label.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(meal_week_label)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var weekly_list := Button.new()
	weekly_list.text = "Einkaufsliste erstellen"
	weekly_list.custom_minimum_size = Vector2(210, 48)
	weekly_list.add_theme_color_override("font_color", Color("#042226"))
	weekly_list.add_theme_stylebox_override("normal", _style(COLORS.success, 14))
	weekly_list.pressed.connect(_create_weekly_shopping_need)
	header.add_child(weekly_list)
	var mix := Button.new()
	mix.text = "Mischen"
	mix.custom_minimum_size = Vector2(120, 48)
	mix.tooltip_text = "Nur nicht bestätigte Gerichte neu vorschlagen"
	mix.pressed.connect(_mix_unconfirmed_meals)
	header.add_child(mix)
	page.add_child(header)

	var info := Label.new()
	info.text = (
		"Sieben einfache Hauptgerichte für zwei Personen. Rezept öffnen oder "
		+ "mit einem Klick die gemeinsame Einkaufsliste erstellen."
	)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", COLORS.muted)
	page.add_child(info)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#15515b")))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	meal_plan_list = VBoxContainer.new()
	meal_plan_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meal_plan_list.add_theme_constant_override("separation", 10)
	meal_plan_list.add_theme_constant_override("margin_left", 18)
	meal_plan_list.add_theme_constant_override("margin_right", 18)
	meal_plan_list.add_theme_constant_override("margin_top", 16)
	meal_plan_list.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(meal_plan_list)
	page.add_child(panel)
	return page


func _rebuild_meal_plan_rows() -> void:
	if not is_instance_valid(meal_plan_list):
		return
	for child in meal_plan_list.get_children():
		child.queue_free()
	meal_day_controls.clear()
	meal_week_label.text = (
		"%s · Woche %d" % [
			MonthManager.get_active_month_name(),
			ShoppingManager.get_active_week(),
		]
	)

	var plan := MealPlanManager.get_plan()
	var day_names := [
		"Montag",
		"Dienstag",
		"Mittwoch",
		"Donnerstag",
		"Freitag",
		"Samstag",
		"Sonntag",
	]
	for day_index in range(7):
		var day: Dictionary = plan[day_index]
		meal_plan_list.add_child(
			_build_meal_day_row(day_index, day_names[day_index], day)
		)


func _build_meal_day_row(
	day_index: int,
	day_name: String,
	day: Dictionary
) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#0b3640"), 12))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	panel.add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)

	var name := Label.new()
	name.text = day_name
	name.custom_minimum_size.x = 105
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", COLORS.text)
	row.add_child(name)

	var meal := Label.new()
	meal.text = str(day.meal)
	meal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meal.add_theme_font_size_override("font_size", 18)
	meal.add_theme_color_override("font_color", COLORS.text)
	row.add_child(meal)

	var recipe_id := str(day.get("recipe_id", ""))
	var recipe := Button.new()
	recipe.text = "Rezept"
	recipe.custom_minimum_size = Vector2(80, 44)
	recipe.disabled = recipe_id.is_empty()
	recipe.tooltip_text = (
		"Zutaten und Zubereitung anzeigen"
		if not recipe_id.is_empty()
		else "Für ein selbst eingetragenes Gericht ist kein Rezept hinterlegt"
	)
	recipe.pressed.connect(_open_recipe.bind(recipe_id))
	row.add_child(recipe)

	var confirmed := CheckButton.new()
	confirmed.text = "Bestätigt"
	confirmed.button_pressed = bool(day.get("confirmed", false))
	confirmed.tooltip_text = "Dieses Gericht beim Mischen behalten"
	confirmed.toggled.connect(_set_meal_confirmed.bind(day_index))
	row.add_child(confirmed)

	var chain_note := str(day.get("chain_note", ""))
	if not chain_note.is_empty():
		var linked_recipe := RecipeCatalog.get_recipe(str(day.get("recipe_id", "")))
		var time_note := ""
		if not linked_recipe.is_empty():
			time_note = "  ·  2 Personen  ·  ca. %d Min. aktiv" % int(linked_recipe.active_minutes)
		var note := Label.new()
		note.text = "↳ %s%s" % [chain_note, time_note]
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_color_override("font_color", COLORS.accent)
		content.add_child(note)
	return panel


func _build_recipe_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.94), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(620, 520)
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, Color("#1b6770")))
	center.add_child(dialog)
	recipe_dialog = dialog

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	dialog.add_child(column)
	recipe_title = Label.new()
	recipe_title.add_theme_font_size_override("font_size", 27)
	recipe_title.add_theme_color_override("font_color", COLORS.text)
	recipe_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(recipe_title)

	var ingredients_heading := Label.new()
	ingredients_heading.text = "Zutaten und geschätzte Packungspreise"
	ingredients_heading.add_theme_font_size_override("font_size", 18)
	ingredients_heading.add_theme_color_override("font_color", COLORS.accent)
	column.add_child(ingredients_heading)
	recipe_ingredients = Label.new()
	recipe_ingredients.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_ingredients.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_ingredients.add_theme_color_override("font_color", COLORS.text)
	column.add_child(recipe_ingredients)

	var preparation_heading := Label.new()
	preparation_heading.text = "Zubereitung"
	preparation_heading.add_theme_font_size_override("font_size", 18)
	preparation_heading.add_theme_color_override("font_color", COLORS.accent)
	column.add_child(preparation_heading)
	recipe_preparation = Label.new()
	recipe_preparation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_preparation.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(recipe_preparation)

	var note := Label.new()
	note.text = "Preise sind realistische Schätzungen für günstige Eigenmarken und können je nach Markt abweichen."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", COLORS.warning)
	column.add_child(note)

	var buttons := HBoxContainer.new()
	var close := Button.new()
	close.text = "Schließen"
	close.custom_minimum_size = Vector2(130, 46)
	close.pressed.connect(func() -> void: recipe_panel.visible = false)
	buttons.add_child(close)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	recipe_add_button = Button.new()
	recipe_add_button.text = "Zutaten zur Einkaufsliste"
	recipe_add_button.custom_minimum_size = Vector2(230, 46)
	recipe_add_button.add_theme_color_override("font_color", Color("#042226"))
	recipe_add_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	recipe_add_button.pressed.connect(_add_open_recipe_to_shopping)
	buttons.add_child(recipe_add_button)
	column.add_child(buttons)
	return overlay


func _build_custom_recipe_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.96), 0))
	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(780, 720)
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, Color("#1b6770")))
	center.add_child(dialog)
	custom_recipe_dialog = dialog
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	dialog.add_child(column)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Meine Lieblingsrezepte"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var add := Button.new()
	add.text = "+ Neues Rezept"
	add.custom_minimum_size = Vector2(150, 44)
	add.pressed.connect(_start_new_custom_recipe)
	header.add_child(add)
	var close := Button.new()
	close.text = "Schließen"
	close.custom_minimum_size = Vector2(110, 44)
	close.pressed.connect(func() -> void: custom_recipe_panel.visible = false)
	header.add_child(close)
	column.add_child(header)

	var day_row := HBoxContainer.new()
	var day_label := Label.new()
	day_label.text = "Beim Planen eintragen für:"
	day_label.add_theme_color_override("font_color", COLORS.muted)
	day_row.add_child(day_label)
	custom_recipe_day_input = OptionButton.new()
	for day_name in ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]:
		custom_recipe_day_input.add_item(day_name)
	day_row.add_child(custom_recipe_day_input)
	column.add_child(day_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	custom_recipe_list = VBoxContainer.new()
	custom_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_recipe_list.add_theme_constant_override("separation", 8)
	scroll.add_child(custom_recipe_list)
	column.add_child(scroll)

	custom_recipe_editor = VBoxContainer.new()
	custom_recipe_editor.visible = false
	custom_recipe_editor.add_theme_constant_override("separation", 8)
	custom_recipe_title_input = LineEdit.new()
	custom_recipe_title_input.placeholder_text = "Name des Gerichts"
	custom_recipe_title_input.custom_minimum_size.y = 42
	custom_recipe_editor.add_child(custom_recipe_title_input)
	custom_recipe_mode_input = OptionButton.new()
	for mode in ["Normal kochen", "Meal-Prep", "Schnell", "Vorkochen", "Reste", "Fertiggericht"]:
		custom_recipe_mode_input.add_item(mode)
	custom_recipe_editor.add_child(custom_recipe_mode_input)

	var ingredient_header := HBoxContainer.new()
	var ingredient_title := Label.new()
	ingredient_title.text = "Zutaten"
	ingredient_title.add_theme_font_size_override("font_size", 18)
	ingredient_title.add_theme_color_override("font_color", COLORS.accent)
	ingredient_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ingredient_header.add_child(ingredient_title)
	var add_ingredient := Button.new()
	add_ingredient.text = "+ Zutat hinzufügen"
	add_ingredient.pressed.connect(_add_custom_recipe_ingredient_row)
	ingredient_header.add_child(add_ingredient)
	custom_recipe_editor.add_child(ingredient_header)

	var ingredient_columns := HBoxContainer.new()
	for column_data in [
		{"text": "Produkt", "width": 0.0},
		{"text": "Menge / Packung", "width": 190.0},
		{"text": "Preis", "width": 130.0},
		{"text": "", "width": 44.0},
	]:
		var column_label := Label.new()
		column_label.text = str(column_data.text)
		column_label.custom_minimum_size.x = float(column_data.width)
		if float(column_data.width) == 0.0:
			column_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column_label.add_theme_color_override("font_color", COLORS.muted)
		ingredient_columns.add_child(column_label)
	custom_recipe_editor.add_child(ingredient_columns)

	var ingredient_scroll := ScrollContainer.new()
	ingredient_scroll.custom_minimum_size.y = 180
	ingredient_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	custom_recipe_ingredients_list = VBoxContainer.new()
	custom_recipe_ingredients_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_recipe_ingredients_list.add_theme_constant_override("separation", 6)
	ingredient_scroll.add_child(custom_recipe_ingredients_list)
	custom_recipe_editor.add_child(ingredient_scroll)
	custom_recipe_preparation_input = TextEdit.new()
	custom_recipe_preparation_input.placeholder_text = "Zubereitung Schritt für Schritt beschreiben"
	custom_recipe_preparation_input.custom_minimum_size.y = 110
	custom_recipe_editor.add_child(custom_recipe_preparation_input)
	var editor_buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.pressed.connect(_close_custom_recipe_editor)
	editor_buttons.add_child(cancel)
	var editor_spacer := Control.new()
	editor_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	editor_buttons.add_child(editor_spacer)
	var save := Button.new()
	save.text = "Rezept speichern"
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 10))
	save.pressed.connect(_save_custom_recipe)
	editor_buttons.add_child(save)
	custom_recipe_editor.add_child(editor_buttons)
	column.add_child(custom_recipe_editor)
	return overlay


func _open_custom_recipe_library() -> void:
	_close_custom_recipe_editor()
	_rebuild_custom_recipe_rows()
	custom_recipe_panel.visible = true


func _rebuild_custom_recipe_rows() -> void:
	if not is_instance_valid(custom_recipe_list):
		return
	for child in custom_recipe_list.get_children():
		child.queue_free()
	var recipes := CustomRecipeManager.get_recipes()
	if recipes.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine eigenen Rezepte. Lege dein erstes Lieblingsgericht an."
		empty.add_theme_color_override("font_color", COLORS.muted)
		custom_recipe_list.add_child(empty)
		return
	for recipe: Dictionary in recipes:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _style(Color("#0b3640"), 10))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		panel.add_child(row)
		var label := Label.new()
		label.text = "%s\n%s · %d Zutaten" % [
			str(recipe.title),
			str(recipe.mode),
			recipe.ingredients.size(),
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", COLORS.text)
		row.add_child(label)
		var view := Button.new()
		view.text = "Rezept"
		view.pressed.connect(_open_recipe.bind(str(recipe.id)))
		row.add_child(view)
		var plan := Button.new()
		plan.text = "Einplanen"
		plan.pressed.connect(_plan_custom_recipe.bind(str(recipe.id)))
		row.add_child(plan)
		var shop := Button.new()
		shop.text = "Einkauf"
		shop.disabled = ShoppingManager.is_booked()
		shop.pressed.connect(_add_custom_recipe_to_shopping.bind(str(recipe.id)))
		row.add_child(shop)
		var edit := Button.new()
		edit.text = "Bearbeiten"
		edit.pressed.connect(_edit_custom_recipe.bind(str(recipe.id)))
		row.add_child(edit)
		var remove := Button.new()
		remove.text = "Löschen"
		remove.pressed.connect(_delete_custom_recipe.bind(str(recipe.id)))
		row.add_child(remove)
		custom_recipe_list.add_child(panel)


func _start_new_custom_recipe() -> void:
	_editing_custom_recipe_id = ""
	custom_recipe_title_input.clear()
	custom_recipe_mode_input.select(0)
	_clear_custom_recipe_ingredient_rows()
	_add_custom_recipe_ingredient_row()
	custom_recipe_preparation_input.clear()
	custom_recipe_list.get_parent().visible = false
	custom_recipe_editor.visible = true
	custom_recipe_title_input.grab_focus()


func _edit_custom_recipe(recipe_id: String) -> void:
	var recipe := CustomRecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
	_editing_custom_recipe_id = recipe_id
	custom_recipe_title_input.text = str(recipe.title)
	for index in custom_recipe_mode_input.item_count:
		if custom_recipe_mode_input.get_item_text(index) == str(recipe.mode):
			custom_recipe_mode_input.select(index)
	_clear_custom_recipe_ingredient_rows()
	for ingredient: Dictionary in recipe.ingredients:
		_add_custom_recipe_ingredient_row(ingredient)
	custom_recipe_preparation_input.text = str(recipe.preparation)
	custom_recipe_list.get_parent().visible = false
	custom_recipe_editor.visible = true


func _close_custom_recipe_editor() -> void:
	if is_instance_valid(custom_recipe_editor):
		custom_recipe_editor.visible = false
	if is_instance_valid(custom_recipe_list):
		custom_recipe_list.get_parent().visible = true


func _save_custom_recipe() -> void:
	var ingredients := _collect_custom_recipe_ingredients()
	var recipe_id := CustomRecipeManager.save_recipe(
		_editing_custom_recipe_id,
		custom_recipe_title_input.text,
		custom_recipe_mode_input.get_item_text(custom_recipe_mode_input.selected),
		ingredients,
		custom_recipe_preparation_input.text
	)
	if recipe_id.is_empty():
		status_label.text = "Bitte Name, Zubereitung und mindestens eine gültige Zutatenzeile eintragen."
		return
	_editing_custom_recipe_id = recipe_id
	_close_custom_recipe_editor()
	_rebuild_custom_recipe_rows()
	status_label.text = "✓ Eigenes Rezept wurde lokal gespeichert."


func _add_custom_recipe_ingredient_row(ingredient: Dictionary = {}) -> void:
	var row := BoxContainer.new()
	row.vertical = _compact_layout
	row.add_theme_constant_override("separation", 8)
	var name := LineEdit.new()
	name.placeholder_text = "z. B. Kartoffeln"
	name.text = str(ingredient.get("name", ""))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size.y = 42
	row.add_child(name)
	var quantity := LineEdit.new()
	quantity.placeholder_text = "z. B. 2,5 kg"
	quantity.text = str(ingredient.get("quantity", ""))
	quantity.custom_minimum_size = Vector2(190, 42)
	row.add_child(quantity)
	var price := _create_savings_money_input()
	price.custom_minimum_size = Vector2(130, 42)
	price.step = 0.05
	price.value = float(ingredient.get("estimated_price", 0.0))
	row.add_child(price)
	var remove := Button.new()
	remove.text = "×"
	remove.tooltip_text = "Zutat entfernen"
	remove.custom_minimum_size = Vector2(44, 42)
	row.add_child(remove)
	var controls := {
		"row": row,
		"name": name,
		"quantity": quantity,
		"price": price,
	}
	remove.pressed.connect(_remove_custom_recipe_ingredient_row.bind(controls))
	custom_recipe_ingredient_controls.append(controls)
	custom_recipe_ingredients_list.add_child(row)


func _remove_custom_recipe_ingredient_row(controls: Dictionary) -> void:
	if custom_recipe_ingredient_controls.size() <= 1:
		var name: LineEdit = controls.name
		var quantity: LineEdit = controls.quantity
		var price: SpinBox = controls.price
		name.clear()
		quantity.clear()
		price.value = 0.0
		return
	custom_recipe_ingredient_controls.erase(controls)
	var row: Control = controls.row
	row.queue_free()


func _clear_custom_recipe_ingredient_rows() -> void:
	for controls: Dictionary in custom_recipe_ingredient_controls:
		var row: Control = controls.row
		row.queue_free()
	custom_recipe_ingredient_controls.clear()


func _collect_custom_recipe_ingredients() -> Array:
	var ingredients: Array = []
	for controls: Dictionary in custom_recipe_ingredient_controls:
		var name: LineEdit = controls.name
		var quantity: LineEdit = controls.quantity
		var price: SpinBox = controls.price
		var clean_name := name.text.strip_edges()
		var clean_quantity := quantity.text.strip_edges()
		if clean_name.is_empty() and clean_quantity.is_empty() and price.value == 0.0:
			continue
		if clean_name.is_empty() or clean_quantity.is_empty():
			return []
		ingredients.append({
			"name": clean_name,
			"quantity": clean_quantity,
			"estimated_price": price.value,
		})
	return ingredients


func _plan_custom_recipe(recipe_id: String) -> void:
	var recipe := CustomRecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
	var day_index := custom_recipe_day_input.selected
	var plan := MealPlanManager.get_plan()
	var day: Dictionary = plan[day_index]
	MealPlanManager.update_day(
		day_index,
		str(recipe.mode),
		str(recipe.title),
		recipe_id
	)
	custom_recipe_panel.visible = false
	status_label.text = "✓ %s wurde für %s eingeplant." % [
		str(recipe.title),
		custom_recipe_day_input.get_item_text(day_index),
	]


func _add_custom_recipe_to_shopping(recipe_id: String) -> void:
	var recipe := CustomRecipeManager.get_recipe(recipe_id)
	var purchase_plan := PackPlanner.plan_all(recipe.get("ingredients", []))
	var added := ShoppingManager.add_recipe_ingredients(purchase_plan)
	status_label.text = (
		"✓ %d Zutaten wurden zur Einkaufsliste hinzugefügt." % added
		if added > 0
		else "Keine neuen Zutaten hinzugefügt."
	)
	_rebuild_custom_recipe_rows()


func _delete_custom_recipe(recipe_id: String) -> void:
	custom_recipe_panel.visible = false
	_request_confirmation(
		"Dieses eigene Rezept wird dauerhaft aus deiner Sammlung gelöscht.",
		Callable(CustomRecipeManager, "remove_recipe").bind(recipe_id)
	)


func _on_custom_recipes_changed(_recipes: Array) -> void:
	_rebuild_custom_recipe_rows()


func _open_recipe(recipe_id: String) -> void:
	var recipe := RecipeCatalog.get_recipe(recipe_id)
	if recipe.is_empty():
		recipe = CustomRecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		status_label.text = "Für dieses Gericht sind noch keine Rezeptdetails hinterlegt."
		return
	custom_recipe_panel.visible = false
	_open_recipe_id = recipe_id
	recipe_title.text = str(recipe.title)
	if recipe.has("servings"):
		recipe_title.text += "  ·  %d Personen  ·  ca. %d Min. aktiv" % [
			int(recipe.servings),
			int(recipe.get("active_minutes", 20)),
		]
	var lines: Array[String] = []
	var total := 0.0
	for ingredient: Dictionary in recipe.ingredients:
		var price := float(ingredient.estimated_price)
		total += price
		var source_note := (
			"  ·  aus Vorbereitung/Resten"
			if not bool(ingredient.get("include_in_shopping", true))
			else ""
		)
		lines.append("• %s – %s  ·  %s%s" % [
			str(ingredient.name),
			str(ingredient.quantity),
			_money(price),
			source_note,
		])
	lines.append("\nGeschätzter Einkauf: %s" % _money(total))
	recipe_ingredients.text = "\n".join(lines)
	recipe_preparation.text = str(recipe.preparation)
	recipe_add_button.disabled = ShoppingManager.is_booked()
	recipe_panel.visible = true


func _add_open_recipe_to_shopping() -> void:
	var ingredients := RecipeCatalog.ingredients_for(_open_recipe_id)
	if ingredients.is_empty():
		ingredients = CustomRecipeManager.get_recipe(_open_recipe_id).get("ingredients", [])
	var purchase_plan := PackPlanner.plan_all(ingredients)
	var added := ShoppingManager.add_recipe_ingredients(purchase_plan)
	recipe_panel.visible = false
	if added > 0:
		status_label.text = "✓ %d Zutaten wurden zur Einkaufsliste hinzugefügt." % added
	else:
		status_label.text = "Keine neuen Zutaten: bereits auf der Einkaufsliste."


func _save_meal_day(day_index: int) -> void:
	var controls: Dictionary = meal_day_controls[day_index]
	var mode: OptionButton = controls.mode
	var meal: LineEdit = controls.meal
	MealPlanManager.update_day(
		day_index,
		mode.get_item_text(mode.selected),
		meal.text
	)
	status_label.text = "✓ Tagesplan wurde gespeichert."


func _generate_meal_suggestions() -> void:
	MealPlanManager.generate_suggestions()
	status_label.text = "✓ Der sparsame 7-Tage-Plan für zwei Personen wurde erstellt."


func _mix_unconfirmed_meals() -> void:
	MealPlanManager.mix_unconfirmed()
	status_label.text = "✓ Nur die unbestätigten Gerichte wurden neu gemischt."


func _set_meal_confirmed(confirmed: bool, day_index: int) -> void:
	MealPlanManager.set_confirmed(day_index, confirmed)
	status_label.text = (
		"✓ Gericht bleibt beim Mischen erhalten."
		if confirmed
		else "Gericht kann beim nächsten Mischen ersetzt werden."
	)


func _create_weekly_shopping_need() -> void:
	if ShoppingManager.is_booked():
		status_label.text = "Diese Einkaufswoche ist bereits abgeschlossen."
		return
	var all_ingredients: Array = []
	var skipped_days := 0
	for day: Dictionary in MealPlanManager.get_plan():
		var recipe_id := str(day.get("recipe_id", ""))
		if recipe_id.is_empty():
			skipped_days += 1
			continue
		var recipe := RecipeCatalog.get_recipe(recipe_id)
		if recipe.is_empty():
			recipe = CustomRecipeManager.get_recipe(recipe_id)
		if recipe.is_empty():
			skipped_days += 1
			continue
		for ingredient: Dictionary in recipe.get("ingredients", []):
			if bool(ingredient.get("include_in_shopping", true)):
				all_ingredients.append(ingredient.duplicate(true))
	if all_ingredients.is_empty():
		status_label.text = "Im Wochenplan sind noch keine Gerichte mit Rezeptdaten vorhanden."
		return
	var weekly_need := WeeklyNeedCalculator.aggregate(all_ingredients)
	var purchase_plan := PackPlanner.plan_all(weekly_need)
	var added := ShoppingManager.replace_weekly_recipe_ingredients(purchase_plan)
	_show_page("shopping")
	status_label.text = (
		"✓ Einkaufsliste mit %d Produkten erstellt; %d Tage ohne Rezept ausgelassen."
	) % [
		added,
		skipped_days,
	]


func _build_balance_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(470, 300)
	balance_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Kontostand ändern"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	var hint := Label.new()
	hint.text = "Trage den aktuellen Kontostand für diesen Monat ein."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)

	balance_input = SpinBox.new()
	balance_input.min_value = 0.0
	balance_input.max_value = 1000000.0
	balance_input.step = 0.01
	balance_input.suffix = " €"
	balance_input.custom_minimum_size.y = 48
	_prepare_amount_input(balance_input)
	column.add_child(balance_input)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: balance_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Kontostand speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_balance)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_fixed_payment_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))
	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(480, 330)
	fixed_payment_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	fixed_payment_title = Label.new()
	fixed_payment_title.text = "Teilzahlung eintragen"
	fixed_payment_title.add_theme_font_size_override("font_size", 27)
	fixed_payment_title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(fixed_payment_title)
	var hint := Label.new()
	hint.text = "Der eingetragene Betrag wird vom offenen Betrag dieses Kostenpunkts abgezogen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)

	fixed_payment_input = SpinBox.new()
	fixed_payment_input.min_value = 0.0
	fixed_payment_input.max_value = 1000000.0
	fixed_payment_input.step = 0.01
	fixed_payment_input.suffix = " €"
	fixed_payment_input.custom_minimum_size.y = 48
	_prepare_amount_input(fixed_payment_input)
	column.add_child(fixed_payment_input)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: fixed_payment_panel.visible = false)
	buttons.add_child(cancel)
	var save := Button.new()
	save.text = "Zahlung speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_fixed_payment)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_confirmation_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(480, 270)
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.warning))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Wirklich löschen?"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	confirmation_message = Label.new()
	confirmation_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmation_message.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(confirmation_message)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(_cancel_confirmation)
	buttons.add_child(cancel)

	var confirm := Button.new()
	confirm.text = "Endgültig löschen"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.custom_minimum_size.y = 48
	confirm.add_theme_color_override("font_color", Color.WHITE)
	confirm.add_theme_stylebox_override("normal", _style(Color("#b94c43"), 12))
	confirm.pressed.connect(_confirm_action)
	buttons.add_child(confirm)
	column.add_child(buttons)
	return overlay


func _build_add_cost_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(540, 680)
	add_cost_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Neue Fixkosten"
	cost_dialog_title = title
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	column.add_child(_field_label("Bezeichnung"))
	cost_name_input = LineEdit.new()
	cost_name_input.placeholder_text = "Zum Beispiel Miete oder Strom"
	cost_name_input.custom_minimum_size.y = 44
	column.add_child(cost_name_input)

	column.add_child(_field_label("Kategorie"))
	cost_category_input = OptionButton.new()
	for category in ["Wohnen", "Energie", "Kommunikation", "Versicherung", "Mobilität", "Abonnement", "Sonstiges"]:
		cost_category_input.add_item(category)
	cost_category_input.custom_minimum_size.y = 44
	column.add_child(cost_category_input)

	column.add_child(_field_label("Betrag bei Fälligkeit"))
	cost_amount_input = SpinBox.new()
	cost_amount_input.min_value = 0.0
	cost_amount_input.max_value = 1000000.0
	cost_amount_input.step = 0.01
	cost_amount_input.suffix = " €"
	cost_amount_input.custom_minimum_size.y = 44
	_prepare_amount_input(cost_amount_input)
	column.add_child(cost_amount_input)

	column.add_child(_field_label("Zahlungsrhythmus"))
	cost_frequency_input = OptionButton.new()
	cost_frequency_input.add_item("Monatlich")
	cost_frequency_input.add_item("Quartalsweise")
	cost_frequency_input.add_item("Jährlich")
	cost_frequency_input.custom_minimum_size.y = 44
	cost_frequency_input.item_selected.connect(_on_cost_frequency_changed)
	column.add_child(cost_frequency_input)

	column.add_child(_field_label("Erster Fälligkeitsmonat"))
	cost_anchor_month_input = OptionButton.new()
	for month_name: String in MonthUtils.MONTH_NAMES:
		cost_anchor_month_input.add_item(month_name)
	cost_anchor_month_input.custom_minimum_size.y = 44
	column.add_child(cost_anchor_month_input)

	column.add_child(_field_label("Fälligkeit im Monat"))
	cost_due_day_input = SpinBox.new()
	cost_due_day_input.min_value = 1
	cost_due_day_input.max_value = 31
	cost_due_day_input.step = 1
	cost_due_day_input.suffix = ". Tag"
	cost_due_day_input.custom_minimum_size.y = 44
	column.add_child(cost_due_day_input)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: add_cost_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Fixkosten speichern"
	cost_save_button = save
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_cost)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLORS.muted)
	return label


func _build_month_change_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(570, 500)
	month_change_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	month_change_title = Label.new()
	month_change_title.text = "Neuen Monat beginnen"
	month_change_title.add_theme_font_size_override("font_size", 29)
	month_change_title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(month_change_title)

	var explanation := Label.new()
	explanation.text = (
		"Die Fixkosten werden übernommen und als offen zurückgesetzt. " +
		"Der abgeschlossene Monat bleibt vollständig in der Historie."
	)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(explanation)

	column.add_child(_field_label("Monatslohn oder Startkontostand"))
	month_opening_balance = SpinBox.new()
	month_opening_balance.min_value = 0.0
	month_opening_balance.max_value = 1000000.0
	month_opening_balance.step = 0.01
	month_opening_balance.suffix = " €"
	month_opening_balance.custom_minimum_size.y = 46
	_prepare_amount_input(month_opening_balance)
	column.add_child(month_opening_balance)

	var privacy := Label.new()
	privacy.text = "🔒 Die manuelle Eingabe wird ausschließlich lokal auf diesem PC gespeichert."
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	privacy.add_theme_color_override("font_color", COLORS.success)
	column.add_child(privacy)

	var buttons := HBoxContainer.new()
	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: month_change_panel.visible = false)
	buttons.add_child(cancel)

	var create := Button.new()
	create.text = "Monat beginnen"
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create.custom_minimum_size.y = 48
	create.add_theme_color_override("font_color", Color("#042226"))
	create.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	create.pressed.connect(_confirm_new_month)
	buttons.add_child(create)
	column.add_child(buttons)
	return overlay


func _build_setup_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color(0.01, 0.04, 0.05, 0.92), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)

	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(560, 620)
	setup_dialog = dialog
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel_soft, 22, COLORS.accent))
	center.add_child(dialog)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.add_theme_constant_override("margin_left", 30)
	column.add_theme_constant_override("margin_right", 30)
	column.add_theme_constant_override("margin_top", 28)
	column.add_theme_constant_override("margin_bottom", 28)
	dialog.add_child(column)

	var title := Label.new()
	title.text = "Monat einrichten"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLORS.text)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Alle Werte werden ausschließlich auf diesem PC gespeichert."
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(subtitle)

	var fields := [
		["balance", "Monatslohn oder Kontostand"],
	]
	for field in fields:
		column.add_child(_money_input(field[0], field[1]))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)

	var cancel := Button.new()
	cancel.text = "Abbrechen"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.custom_minimum_size.y = 48
	cancel.pressed.connect(func() -> void: setup_panel.visible = false)
	buttons.add_child(cancel)

	var save := Button.new()
	save.text = "Werte speichern"
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size.y = 48
	save.add_theme_color_override("font_color", Color("#042226"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_setup)
	buttons.add_child(save)
	column.add_child(buttons)

	return overlay


func _money_input(key: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 58

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLORS.text)
	row.add_child(label)

	var input := SpinBox.new()
	input.custom_minimum_size = Vector2(190, 44)
	input.min_value = 0.0
	input.max_value = 1000000.0
	input.step = 0.01
	input.suffix = " €"
	_prepare_amount_input(input)
	input_fields[key] = input
	row.add_child(input)
	return row


func _prepare_amount_input(input: SpinBox) -> void:
	input.update_on_text_changed = true
	var line_edit := input.get_line_edit()
	line_edit.focus_entered.connect(_select_amount_text.bind(line_edit))
	line_edit.text_changed.connect(_normalize_amount_text.bind(line_edit, input))


func _normalize_amount_text(text: String, line_edit: LineEdit, input: SpinBox) -> void:
	if not text.contains(","):
		return
	var caret_position := line_edit.caret_column
	var normalized_text := text.replace(",", ".")
	line_edit.text = normalized_text
	line_edit.caret_column = mini(caret_position, line_edit.text.length())
	var numeric_text := normalized_text.trim_suffix(input.suffix).strip_edges()
	if numeric_text.is_valid_float():
		input.value = float(numeric_text)


func _select_amount_text(line_edit: LineEdit) -> void:
	line_edit.call_deferred("select_all")


func _open_setup() -> void:
	var snapshot := BudgetManager.get_snapshot()
	for key: String in input_fields:
		input_fields[key].value = float(snapshot[key])
	setup_panel.visible = true


func _open_balance_dialog() -> void:
	balance_input.value = float(BudgetManager.get_snapshot().current_balance)
	balance_panel.visible = true
	var line_edit := balance_input.get_line_edit()
	line_edit.grab_focus()
	line_edit.select_all()


func _save_balance() -> void:
	var snapshot := BudgetManager.get_snapshot()
	var corrected_starting_balance := maxf(
		balance_input.value
		- float(snapshot.additional_income)
		- float(snapshot.get("weekly_credit_total", 0.0))
		+ float(snapshot.fixed_costs_paid)
		+ float(snapshot.variable_expenses)
		+ float(snapshot.savings_payments),
		0.0
	)
	BudgetManager.update_budget({"balance": corrected_starting_balance})
	balance_panel.visible = false
	status_label.text = "✓ Aktueller Kontostand wurde lokal gespeichert."


func _save_setup() -> void:
	var values := {}
	for key: String in input_fields:
		values[key] = input_fields[key].value
	BudgetManager.update_budget(values)
	setup_panel.visible = false
	status_label.text = "✓ Monatswerte wurden lokal gespeichert."


func _request_month_change(offset: int) -> void:
	var target := MonthUtils.add_months(MonthManager.get_active_month_id(), offset)
	if MonthManager.has_month(target):
		MonthManager.switch_to_month(target)
		return

	pending_month_id = target
	month_change_title.text = "%s beginnen" % MonthUtils.display_name(target)
	month_opening_balance.value = float(BudgetManager.get_snapshot().balance)
	month_change_panel.visible = true


func _confirm_new_month() -> void:
	if pending_month_id.is_empty():
		return
	MonthManager.switch_to_month(pending_month_id, month_opening_balance.value)
	month_change_panel.visible = false
	pending_month_id = ""
	status_label.text = "✓ Neuer Monat angelegt; Fixkosten wurden als offen übernommen."


func _on_active_month_changed(_month_id: String, _display_name: String) -> void:
	_update_month_labels()
	_rebuild_fixed_cost_rows()


func _update_month_labels() -> void:
	var month_name := MonthManager.get_active_month_name()
	if is_instance_valid(month_selector_label):
		month_selector_label.text = month_name
	if is_instance_valid(dashboard_month_label):
		dashboard_month_label.text = "%s  ·  Alles Wichtige auf einen Blick" % month_name
	if is_instance_valid(fixed_cost_month_label):
		fixed_cost_month_label.text = "Wiederkehrende Kosten für %s" % month_name


static func _should_use_compact_layout(view_size: Vector2, is_web: bool) -> bool:
	return view_size.x < 900.0 or (is_web and view_size.y > view_size.x)


static func _should_stack_dashboard(view_size: Vector2, is_web: bool) -> bool:
	return view_size.x < 1180.0 or (is_web and view_size.y > view_size.x)


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return

	var is_web := OS.has_feature("web")
	var compact := _should_use_compact_layout(size, is_web)
	var stacked_content := _should_stack_dashboard(size, is_web)
	var layout_changed := compact != _compact_layout
	_compact_layout = compact

	var book_open := (
		(is_instance_valid(fixed_costs_page) and fixed_costs_page.visible)
		or (is_instance_valid(savings_page) and savings_page.visible)
		or (is_instance_valid(transactions_page) and transactions_page.visible)
	)
	sidebar_panel.visible = not compact and not book_open
	desktop_backdrop.visible = not compact
	mobile_navigation.visible = compact
	if compact and app_shell.get_child(app_shell.get_child_count() - 1) != mobile_navigation:
		app_shell.move_child(mobile_navigation, app_shell.get_child_count() - 1)
	if is_instance_valid(app_local_status):
		app_local_status.text = "● Lokal" if compact else "●  Sicher lokal gespeichert"
		app_local_status.add_theme_font_size_override("font_size", 11 if compact else 12)
	if is_instance_valid(app_bar):
		app_bar.visible = not compact and not book_open
	dashboard_header.vertical = compact
	var dashboard_titles := dashboard_header.get_child(0) as VBoxContainer
	dashboard_titles.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	)
	for heading: Label in dashboard_titles.get_children():
		heading.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
		)
	if is_instance_valid(dashboard_title):
		dashboard_title.text = "Meine Budgetwelt" if compact else "Deine Budgetwelt"
		dashboard_title.add_theme_font_size_override("font_size", 38 if compact else 36)
	if is_instance_valid(month_selector_label):
		month_selector_label.custom_minimum_size.x = 150 if compact else 130
		month_selector_label.add_theme_font_override("font", display_font)
		month_selector_label.add_theme_font_size_override("font_size", 20 if compact else 18)
	if is_instance_valid(month_controls):
		month_controls.size_flags_horizontal = (
			Control.SIZE_SHRINK_CENTER if compact else Control.SIZE_SHRINK_END
		)
	if is_instance_valid(month_edit_button):
		month_edit_button.text = "⚙" if compact else "Monat einrichten"
		month_edit_button.custom_minimum_size.x = 52 if compact else 160
	dashboard_body.vertical = stacked_content
	mobile_dashboard_metrics.visible = compact
	mobile_dashboard_actions.visible = compact
	summary_panel.visible = not compact
	month_flow_panel.visible = not compact
	if compact:
		dashboard_body.move_child(mobile_dashboard_metrics, 0)
		dashboard_body.move_child(world_view, 1)
		dashboard_body.move_child(mobile_dashboard_actions, 2)
	elif dashboard_body.get_child(0) != world_view:
		dashboard_body.move_child(world_view, 0)
		dashboard_body.move_child(summary_panel, 1)
	if world_view.has_method("set_compact_mode"):
		world_view.set_compact_mode(compact)
	if is_instance_valid(week_cards):
		week_cards.vertical = compact
	fixed_header.vertical = false
	fixed_summary_row.vertical = false
	fixed_list_header.visible = not compact

	world_view.custom_minimum_size = (
		Vector2(0, 320) if compact
		else Vector2(0, 500) if stacked_content
		else Vector2(700, clampf(size.y - 260.0, 620.0, 900.0))
	)
	summary_panel.custom_minimum_size.x = 0 if stacked_content else 345

	dashboard_header.custom_minimum_size.y = 0 if compact else 74
	fixed_header.custom_minimum_size.y = 0 if compact else 82

	var dialog_width := maxf(size.x - 32.0, 280.0)
	if is_instance_valid(add_cost_dialog):
		add_cost_dialog.custom_minimum_size.x = minf(540.0, dialog_width)
	if is_instance_valid(balance_dialog):
		balance_dialog.custom_minimum_size.x = minf(470.0, dialog_width)
	if is_instance_valid(fixed_payment_dialog):
		fixed_payment_dialog.custom_minimum_size.x = minf(480.0, dialog_width)
	if is_instance_valid(month_change_dialog):
		month_change_dialog.custom_minimum_size.x = minf(570.0, dialog_width)
	if is_instance_valid(setup_dialog):
		setup_dialog.custom_minimum_size.x = minf(560.0, dialog_width)
	if is_instance_valid(add_goal_dialog):
		add_goal_dialog.custom_minimum_size.x = minf(560.0, dialog_width)
	if is_instance_valid(deposit_dialog):
		deposit_dialog.custom_minimum_size.x = minf(500.0, dialog_width)
	if is_instance_valid(add_transaction_dialog):
		add_transaction_dialog.custom_minimum_size.x = minf(560.0, dialog_width)
	if is_instance_valid(add_shopping_item_dialog):
		add_shopping_item_dialog.custom_minimum_size.x = minf(540.0, dialog_width)
	if is_instance_valid(recipe_dialog):
		recipe_dialog.custom_minimum_size.x = minf(620.0, dialog_width)
	if is_instance_valid(custom_recipe_dialog):
		custom_recipe_dialog.custom_minimum_size.x = minf(780.0, dialog_width)
		custom_recipe_dialog.custom_minimum_size.y = minf(720.0, maxf(size.y - 32.0, 520.0))
	for controls: Dictionary in custom_recipe_ingredient_controls:
		var ingredient_row: BoxContainer = controls.row
		ingredient_row.vertical = compact
	if is_instance_valid(savings_summary_row):
		savings_summary_row.vertical = false
	if is_instance_valid(transaction_summary_row):
		transaction_summary_row.vertical = false
	if is_instance_valid(transaction_list_header):
		transaction_list_header.vertical = compact
		transaction_list_header.get_child(1).visible = not compact
		transaction_filter_summary.visible = not compact
		transaction_weekly_filter_button.text = (
			"Wochenbudget filtern" if compact else
			"Alle Buchungen zeigen" if transaction_weekly_filter_button.button_pressed
			else "Nur Wochenbudget"
		)
		transaction_weekly_filter_button.custom_minimum_size = (
			Vector2(0, 44) if compact else Vector2(180, 42)
		)
		transaction_weekly_filter_button.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_END
		)
	if is_instance_valid(fixed_hint_label):
		fixed_hint_label.visible = not compact
	if is_instance_valid(shopping_summary_row):
		shopping_summary_row.vertical = compact

	_apply_mobile_book_layout(compact)
	_update_mobile_navigation()

	if layout_changed:
		_rebuild_fixed_cost_rows()
		_rebuild_savings_rows()
		_rebuild_transaction_rows()
		_rebuild_shopping_rows()
	call_deferred("_reset_dashboard_scroll")


func _apply_mobile_book_layout(compact: bool) -> void:
	for control: Control in book_navigation_controls:
		control.visible = not compact
	var mobile_art := load("res://assets/world/budget_world_island.png")
	if is_instance_valid(fixed_page_art):
		fixed_page_art.texture = mobile_art if compact else load(
			"res://assets/ui/fixed_costs_ledger_background.png"
		)
	if is_instance_valid(savings_page_art):
		savings_page_art.texture = mobile_art if compact else load(
			"res://assets/ui/fixed_costs_ledger_background.png"
		)
	if is_instance_valid(transactions_page_art):
		transactions_page_art.texture = mobile_art if compact else load(
			"res://assets/ui/transactions_ledger_background.png"
		)
	if is_instance_valid(savings_list_title):
		savings_list_title.add_theme_color_override(
			"font_color", Color("#e8ce91") if compact else Color("#4b321b")
		)
	if is_instance_valid(transaction_list_title):
		transaction_list_title.add_theme_color_override(
			"font_color", Color("#e8ce91") if compact else Color("#4b321b")
		)

	_configure_book_region(
		fixed_header, fixed_summary_row, fixed_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.03, 0.145, 0.97, 0.285),
		Vector4(0.035, 0.30, 0.965, 0.985)
	)
	_configure_book_region(
		savings_header, savings_summary_row, savings_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.03, 0.145, 0.97, 0.285),
		Vector4(0.035, 0.30, 0.965, 0.985)
	)
	_configure_book_region(
		transactions_header, transaction_summary_row, transactions_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.04, 0.145, 0.96, 0.275),
		Vector4(0.035, 0.29, 0.965, 0.985)
	)

	_style_mobile_book_header(fixed_header, compact, "＋")
	_style_mobile_book_header(savings_header, compact, "＋")
	_style_mobile_book_header(transactions_header, compact, "＋")
	_style_mobile_fixed_summaries(compact)
	_style_mobile_simple_summaries(savings_summary_row, compact)
	_style_mobile_simple_summaries(transaction_summary_row, compact)

	if is_instance_valid(transaction_summary_row):
		for index in transaction_summary_row.get_child_count():
			transaction_summary_row.get_child(index).visible = not compact or index == 3


func _configure_book_region(
	header: Control,
	summary: Control,
	list_panel: Control,
	compact: bool,
	mobile_header: Vector4,
	mobile_summary: Vector4,
	mobile_list: Vector4
) -> void:
	if not is_instance_valid(header) or not is_instance_valid(summary) or not is_instance_valid(list_panel):
		return
	var header_region := mobile_header if compact else Vector4(0.115, 0.018, 0.97, 0.145)
	var summary_region := mobile_summary if compact else Vector4(0.128, 0.155, 0.872, 0.278)
	var list_region := mobile_list if compact else Vector4(0.158, 0.325, 0.94, 0.905)
	_set_anchor_region(header, header_region)
	_set_anchor_region(summary, summary_region)
	_set_anchor_region(list_panel, list_region)


func _set_anchor_region(control: Control, region: Vector4) -> void:
	control.anchor_left = region.x
	control.anchor_top = region.y
	control.anchor_right = region.z
	control.anchor_bottom = region.w
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


func _style_mobile_book_header(header: BoxContainer, compact: bool, mobile_add_text: String) -> void:
	if not is_instance_valid(header) or header.get_child_count() < 4:
		return
	if not header.has_meta("responsive_titles"):
		header.set_meta("responsive_titles", header.get_child(0))
		header.set_meta("responsive_spacer", header.get_child(1))
		header.set_meta("responsive_back", header.get_child(2))
		header.set_meta("responsive_add", header.get_child(3))
	var titles := header.get_meta("responsive_titles") as VBoxContainer
	var title := titles.get_child(0) as Label
	var subtitle := titles.get_child(1) as Label
	var spacer := header.get_meta("responsive_spacer") as Control
	var back_button := header.get_meta("responsive_back") as Button
	var add_button := header.get_meta("responsive_add") as Button
	if compact:
		header.move_child(back_button, 0)
		header.move_child(titles, 1)
		header.move_child(add_button, 2)
		spacer.visible = false
	else:
		header.move_child(titles, 0)
		header.move_child(spacer, 1)
		header.move_child(back_button, 2)
		header.move_child(add_button, 3)
		spacer.visible = true
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 34 if compact else 46)
	subtitle.add_theme_font_size_override("font_size", 16 if compact else 17)
	if compact:
		subtitle.text = MonthManager.get_active_month_name()
		subtitle.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	else:
		subtitle.text = (
			"Wiederkehrende Kosten für %s" % MonthManager.get_active_month_name()
			if header == fixed_header
			else "Baue deine Rücklagen Schritt für Schritt auf"
			if header == savings_header
			else "Einnahmen und Ausgaben des ausgewählten Monats"
		)
		subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	back_button.visible = true
	back_button.text = "‹" if compact else "←  Zur Budgetwelt"
	back_button.custom_minimum_size = Vector2(54, 54) if compact else Vector2(150, 42)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 34 if compact else 15)
	if compact:
		back_button.add_theme_stylebox_override(
			"normal", _style(Color("#07191def"), 27, Color("#b98b42"))
		)
	add_button.text = "+" if compact else (
		"＋  Fixkosten hinzufügen" if header == fixed_header
		else "＋  Sparziel hinzufügen" if header == savings_header
		else "＋  Buchung hinzufügen"
	)
	add_button.custom_minimum_size = Vector2(54, 54) if compact else Vector2(195, 42)
	add_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_button.add_theme_font_size_override("font_size", 30 if compact else 15)
	if compact:
		add_button.add_theme_stylebox_override(
			"normal", _style(Color("#dfbd6a"), 27, Color("#f2d78d"))
		)


func _style_mobile_fixed_summaries(compact: bool) -> void:
	if not is_instance_valid(fixed_summary_row):
		return
	fixed_summary_row.add_theme_constant_override("separation", 6 if compact else 44)
	for card: Control in fixed_summary_row.get_children():
		card.clip_contents = compact
		card.add_theme_stylebox_override(
			"panel",
			_style(Color("#041b22e8"), 16, Color("#b98b42"))
			if compact else _style(Color.TRANSPARENT, 0)
		)
		var row := card.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", 4 if compact else 14)
		row.get_child(0).visible = not compact
		row.get_child(1).visible = not compact
		(row.get_child(1) as Control).custom_minimum_size = (
			Vector2(34, 34) if compact else Vector2(62, 62)
		)
		((row.get_child(1) as Control).get_child(0) as Control).custom_minimum_size = (
			Vector2(34, 34) if compact else Vector2(62, 62)
		)
		var labels := row.get_child(2) as VBoxContainer
		labels.custom_minimum_size.x = 0
		var title := labels.get_child(0) as Label
		var value := labels.get_child(1) as Label
		if compact:
			title.text = (
				"Bezahlt" if card == fixed_summary_row.get_child(0)
				else "Noch offen" if card == fixed_summary_row.get_child(1)
				else "Danach frei"
			)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_font_size_override("font_size", 13 if compact else 17)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if compact else TextServer.AUTOWRAP_OFF
		value.add_theme_font_size_override("font_size", 20 if compact else 30)


func _style_mobile_simple_summaries(row: BoxContainer, compact: bool) -> void:
	if not is_instance_valid(row):
		return
	row.add_theme_constant_override("separation", 6 if compact else 44)
	for index in row.get_child_count():
		var card := row.get_child(index) as Control
		card.clip_contents = compact
		var style := (
			_style(Color("#041b22e8"), 16, Color("#b98b42"))
			if compact else _style(Color.TRANSPARENT, 0)
		)
		style.content_margin_left = 8 if compact else 42
		style.content_margin_right = 8 if compact else 18
		style.content_margin_top = 8 if compact else 0
		style.content_margin_bottom = 8 if compact else 0
		card.add_theme_stylebox_override("panel", style)
		var labels := card.get_child(0) as VBoxContainer
		labels.custom_minimum_size.x = 0
		var title := labels.get_child(0) as Label
		var value := labels.get_child(1) as Label
		if compact and row == savings_summary_row:
			title.text = ["Gespart", "Noch bis Ziel", "Monatlich"][index]
		title.clip_text = compact
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
		)
		value.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER if compact else HORIZONTAL_ALIGNMENT_LEFT
		)
		title.add_theme_font_size_override("font_size", 13 if compact else 17)
		value.add_theme_font_size_override("font_size", 20 if compact else 30)


func _update_mobile_navigation(active_page: String = "") -> void:
	if active_page.is_empty():
		active_page = (
			"fixed_costs" if is_instance_valid(fixed_costs_page) and fixed_costs_page.visible
			else "savings" if is_instance_valid(savings_page) and savings_page.visible
			else "transactions" if is_instance_valid(transactions_page) and transactions_page.visible
			else "dashboard"
		)
	for key: String in mobile_nav_buttons:
		var button: Button = mobile_nav_buttons[key]
		var active := key == active_page
		var label := button.get_meta("mobile_label") as Label
		var icon := button.get_meta("mobile_icon") as TextureRect
		label.add_theme_color_override(
			"font_color", Color("#43e5d2") if active else Color("#d9c99d")
		)
		icon.modulate = Color("#43e5d2") if active else Color("#d0aa64")
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#0b3438cc"), 12, Color("#33d9c5")) if active
			else _style(Color.TRANSPARENT, 0)
		)


func _show_page(page: String) -> void:
	var book_page := page in ["fixed_costs", "savings", "transactions"]
	dashboard_scroll.visible = page == "dashboard"
	fixed_costs_page.visible = page == "fixed_costs"
	savings_page.visible = page == "savings"
	transactions_page.visible = page == "transactions"
	if is_instance_valid(app_bar):
		app_bar.visible = not _compact_layout and not book_page
	if is_instance_valid(sidebar_panel):
		sidebar_panel.visible = not _compact_layout and not book_page
	if is_instance_valid(mobile_navigation):
		mobile_navigation.visible = _compact_layout
	if is_instance_valid(shopping_page):
		shopping_page.visible = false
	if is_instance_valid(meal_plan_page):
		meal_plan_page.visible = false
	_update_mobile_navigation(page)
	if page == "fixed_costs":
		_rebuild_fixed_cost_rows()
	elif page == "savings":
		_rebuild_savings_rows()
	elif page == "transactions":
		_rebuild_transaction_rows()
	elif page == "shopping":
		_apply_shopping_state()
		_rebuild_shopping_rows()
	elif page == "meal_plan":
		_rebuild_meal_plan_rows()


func _show_not_ready(page_name: String) -> void:
	status_label.text = "%s folgt in einem späteren Entwicklungsschritt." % page_name


func _open_add_cost() -> void:
	_editing_fixed_cost_id = ""
	cost_dialog_title.text = "Neue Fixkosten"
	cost_save_button.text = "Fixkosten speichern"
	cost_name_input.clear()
	cost_category_input.select(0)
	cost_amount_input.value = 0.0
	cost_due_day_input.value = 1
	cost_frequency_input.select(0)
	cost_anchor_month_input.select(_active_month_number() - 1)
	_on_cost_frequency_changed(0)
	add_cost_panel.visible = true
	cost_name_input.grab_focus()


func _open_edit_cost(cost_id: String) -> void:
	for cost: Dictionary in FixedCostManager.get_costs():
		if str(cost.id) != cost_id:
			continue
		_editing_fixed_cost_id = cost_id
		cost_dialog_title.text = "Fixkosten bearbeiten"
		cost_save_button.text = "Änderungen speichern"
		cost_name_input.text = str(cost.name)
		for index in cost_category_input.item_count:
			if cost_category_input.get_item_text(index) == str(cost.category):
				cost_category_input.select(index)
				break
		cost_amount_input.value = float(cost.amount)
		cost_due_day_input.value = int(cost.due_day)
		cost_frequency_input.select({
			"monthly": 0,
			"quarterly": 1,
			"yearly": 2,
		}.get(str(cost.get("frequency", "monthly")), 0))
		cost_anchor_month_input.select(int(cost.get("anchor_month", 1)) - 1)
		_on_cost_frequency_changed(cost_frequency_input.selected)
		add_cost_panel.visible = true
		cost_name_input.grab_focus()
		cost_name_input.select_all()
		return


func _save_cost() -> void:
	var category := cost_category_input.get_item_text(cost_category_input.selected)
	var frequency: String = ["monthly", "quarterly", "yearly"][cost_frequency_input.selected]
	var anchor_month := cost_anchor_month_input.selected + 1
	var active_month_id := MonthManager.get_active_month_id()
	var saved := false
	if _editing_fixed_cost_id.is_empty():
		saved = FixedCostManager.add_cost(
			cost_name_input.text,
			category,
			cost_amount_input.value,
			int(cost_due_day_input.value),
			frequency,
			anchor_month,
			active_month_id
		)
	else:
		saved = FixedCostManager.update_cost(
			_editing_fixed_cost_id,
			cost_name_input.text,
			category,
			cost_amount_input.value,
			int(cost_due_day_input.value),
			frequency,
			anchor_month,
			active_month_id
		)
	if saved:
		add_cost_panel.visible = false
		_editing_fixed_cost_id = ""
		status_label.text = "✓ Fixkosten wurden lokal gespeichert."
	else:
		cost_name_input.placeholder_text = "Bitte Bezeichnung und Betrag eintragen"


func _active_month_number() -> int:
	var parts := MonthManager.get_active_month_id().split("-")
	return clampi(int(parts[1]), 1, 12) if parts.size() == 2 else 1


func _on_cost_frequency_changed(index: int) -> void:
	if is_instance_valid(cost_anchor_month_input):
		cost_anchor_month_input.disabled = index == 0
		cost_anchor_month_input.tooltip_text = (
			"Bei monatlichen Fixkosten ist kein Startmonat erforderlich."
			if index == 0
			else "Dieser Monat bestimmt den ersten Fälligkeitstermin."
		)


func _toggle_fixed_cost(paid: bool, cost_id: String) -> void:
	FixedCostManager.set_paid(cost_id, paid)


func _open_fixed_payment(cost_id: String) -> void:
	for cost: Dictionary in FixedCostManager.get_costs():
		if str(cost.id) != cost_id:
			continue
		var paid_amount := float(cost.get("paid_amount", 0.0))
		var open_amount := maxf(float(cost.amount) - paid_amount, 0.0)
		_payment_fixed_cost_id = cost_id
		fixed_payment_title.text = "%s: noch %s offen" % [
			str(cost.name),
			_money(open_amount),
		]
		fixed_payment_input.max_value = open_amount
		fixed_payment_input.value = 0.0
		fixed_payment_panel.visible = true
		var line_edit := fixed_payment_input.get_line_edit()
		line_edit.grab_focus()
		line_edit.select_all()
		return


func _save_fixed_payment() -> void:
	if _payment_fixed_cost_id.is_empty():
		return
	if FixedCostManager.add_payment(_payment_fixed_cost_id, fixed_payment_input.value):
		fixed_payment_panel.visible = false
		_payment_fixed_cost_id = ""
		status_label.text = "✓ Teilzahlung wurde gespeichert."


func _remove_fixed_cost(cost_id: String) -> void:
	_request_confirmation(
		"Dieser Fixkostenpunkt wird aus dem aktuellen und den folgenden neuen Monaten entfernt.",
		Callable(FixedCostManager, "remove_cost").bind(cost_id)
	)


func _open_add_goal() -> void:
	goal_name_input.clear()
	goal_target_input.value = 0.0
	goal_saved_input.value = 0.0
	goal_monthly_input.value = 0.0
	add_goal_panel.visible = true
	goal_name_input.grab_focus()


func _save_new_goal() -> void:
	var saved := SavingsManager.add_goal(
		goal_name_input.text,
		goal_target_input.value,
		goal_saved_input.value,
		goal_monthly_input.value
	)
	if saved:
		add_goal_panel.visible = false
		status_label.text = "✓ Sparziel wurde lokal gespeichert."
	else:
		goal_name_input.placeholder_text = "Bitte Bezeichnung und Zielbetrag eintragen"


func _open_deposit(goal_id: String, goal_name: String) -> void:
	deposit_goal_id = goal_id
	deposit_goal_title.text = "Einzahlung für %s" % goal_name
	deposit_amount_input.value = 0.0
	deposit_panel.visible = true
	deposit_amount_input.get_line_edit().grab_focus()


func _save_deposit() -> void:
	if SavingsManager.add_deposit(deposit_goal_id, deposit_amount_input.value):
		deposit_panel.visible = false
		deposit_goal_id = ""
		status_label.text = "✓ Einzahlung wurde gespeichert."


func _remove_savings_goal(goal_id: String) -> void:
	_request_confirmation(
		"Das Sparziel und sein angezeigter Fortschritt werden gelöscht.",
		Callable(SavingsManager, "remove_goal").bind(goal_id)
	)


func _open_add_transaction() -> void:
	transaction_kind_input.select(0)
	transaction_category_input.select(0)
	transaction_description_input.clear()
	transaction_amount_input.value = 0.0
	transaction_day_input.value = int(Time.get_date_dict_from_system().day)
	add_transaction_panel.visible = true
	transaction_description_input.grab_focus()


func _open_weekly_expense() -> void:
	_open_add_transaction()
	for index in transaction_category_input.item_count:
		if transaction_category_input.get_item_text(index) == "Wochenbudget":
			transaction_category_input.select(index)
			break
	transaction_description_input.placeholder_text = "Zum Beispiel Einkauf oder Freizeit"


func _open_weekly_credit() -> void:
	_open_add_transaction()
	transaction_kind_input.select(3)
	for index in transaction_category_input.item_count:
		if transaction_category_input.get_item_text(index) == "Wochenbudget":
			transaction_category_input.select(index)
			break
	transaction_description_input.text = "Zusätzliches Wochenbudget"
	transaction_day_input.value = int(Time.get_date_dict_from_system().day)
	transaction_amount_input.grab_focus()


func _save_new_transaction() -> void:
	var kinds := ["expense", "income", "saving", "weekly_credit"]
	var kind: String = kinds[transaction_kind_input.selected]
	var category := transaction_category_input.get_item_text(
		transaction_category_input.selected
	)
	var saved := TransactionManager.add_transaction(
		kind,
		category,
		transaction_description_input.text,
		transaction_amount_input.value,
		int(transaction_day_input.value)
	)
	if saved:
		add_transaction_panel.visible = false
		status_label.text = "✓ Buchung wurde lokal gespeichert."
	else:
		transaction_description_input.placeholder_text = (
			"Bitte Beschreibung und Betrag eintragen"
		)


func _remove_transaction(transaction_id: String) -> void:
	_request_confirmation(
		"Die Buchung wird aus diesem Monat entfernt und das verfügbare Geld neu berechnet.",
		Callable(TransactionManager, "remove_transaction").bind(transaction_id)
	)


func _open_add_shopping_item() -> void:
	if ShoppingManager.is_booked():
		status_label.text = "Diese Woche wurde bereits verbucht und ist abgeschlossen."
		return
	shopping_name_input.clear()
	shopping_quantity_input.clear()
	shopping_price_input.value = 0.0
	add_shopping_item_panel.visible = true
	shopping_name_input.grab_focus()


func _save_shopping_item() -> void:
	var saved := ShoppingManager.add_item(
		shopping_name_input.text,
		shopping_quantity_input.text,
		shopping_price_input.value
	)
	if saved:
		add_shopping_item_panel.visible = false
		status_label.text = "✓ Artikel wurde zur Einkaufsliste hinzugefügt."
	else:
		shopping_name_input.placeholder_text = "Bitte Produktnamen eintragen"


func _toggle_shopping_item(checked: bool, item_id: String) -> void:
	ShoppingManager.set_checked(item_id, checked)


func _remove_shopping_item(item_id: String) -> void:
	_request_confirmation(
		"Der Artikel wird aus der aktuellen Wochenliste entfernt.",
		Callable(ShoppingManager, "remove_item").bind(item_id)
	)


func _book_shopping() -> void:
	if ShoppingManager.is_booked():
		return
	var budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	var summary := ShoppingManager.get_summary(budget)
	var amount := float(summary.checked)
	if amount <= 0.0:
		status_label.text = "Bitte zuerst die tatsächlich gekauften Artikel abhaken."
		return

	var saved := TransactionManager.add_transaction(
		"expense",
		"Lebensmittel",
		"Wocheneinkauf Woche %d" % ShoppingManager.get_active_week(),
		amount,
		int(Time.get_date_dict_from_system().day)
	)
	if saved:
		ShoppingManager.mark_booked()
		status_label.text = "✓ Wocheneinkauf wurde als Monatsausgabe verbucht."


func _on_shopping_changed(
	_items: Array,
	_summary: Dictionary,
	_booked: bool
) -> void:
	_apply_shopping_state()
	_rebuild_shopping_rows()


func _on_shopping_week_changed(_week: int) -> void:
	_apply_shopping_state()
	_rebuild_shopping_rows()


func _on_meal_plan_changed(_plan: Array) -> void:
	_rebuild_meal_plan_rows()


func _apply_shopping_state() -> void:
	if not is_instance_valid(shopping_book_button):
		return
	var budget := float(BudgetManager.get_snapshot().weekly_grocery_budget)
	var summary := ShoppingManager.get_summary(budget)
	var booked := ShoppingManager.is_booked()
	shopping_summary_values.budget.text = _money(budget)
	shopping_summary_values.planned.text = _money(float(summary.planned))
	shopping_summary_values.remaining.text = _money(float(summary.remaining))
	shopping_summary_values.remaining.add_theme_color_override(
		"font_color",
		COLORS.warning if bool(summary.over_budget) else COLORS.success
	)
	shopping_book_button.disabled = booked or float(summary.checked) <= 0.0
	shopping_book_button.text = (
		"✓ Einkauf wurde als Monatsausgabe verbucht"
		if booked
		else "Abgehakte Artikel als Einkauf verbuchen"
	)
	for index in shopping_week_buttons.size():
		shopping_week_buttons[index].button_pressed = (
			index + 1 == ShoppingManager.get_active_week()
		)


func _request_confirmation(message: String, action: Callable) -> void:
	confirmation_message.text = message
	_confirmation_action = action
	confirmation_panel.visible = true


func _cancel_confirmation() -> void:
	confirmation_panel.visible = false
	_confirmation_action = Callable()


func _confirm_action() -> void:
	if _confirmation_action.is_valid():
		_confirmation_action.call()
	confirmation_panel.visible = false
	_confirmation_action = Callable()
	status_label.text = "✓ Eintrag wurde gelöscht."


func _create_data_backup() -> void:
	var result := StorageManager.create_backup()
	status_label.text = str(result.message)
	if bool(result.success):
		status_label.tooltip_text = str(result.path)


func _build_restore_dialog() -> void:
	restore_dialog = FileDialog.new()
	restore_dialog.title = "Sicherung auswählen"
	restore_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	restore_dialog.access = FileDialog.ACCESS_USERDATA
	restore_dialog.use_native_dialog = false
	restore_dialog.dir_selected.connect(_on_restore_directory_selected)
	add_child(restore_dialog)

	restore_confirmation = ConfirmationDialog.new()
	restore_confirmation.title = "Daten wiederherstellen"
	restore_confirmation.ok_button_text = "Wiederherstellen"
	restore_confirmation.cancel_button_text = "Abbrechen"
	restore_confirmation.confirmed.connect(_restore_selected_backup)
	add_child(restore_confirmation)


func _open_restore_dialog() -> void:
	var backup_path := "user://backups"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_path))
	restore_dialog.current_dir = backup_path
	restore_dialog.popup_centered_ratio(0.72)


func _on_restore_directory_selected(path: String) -> void:
	_pending_restore_path = path
	var backup_name := path.trim_suffix("/").get_file()
	restore_confirmation.dialog_text = (
		"Sicherung „%s“ wiederherstellen?\n\n" % backup_name
		+ "Die aktuellen Daten werden vorher automatisch gesichert. "
		+ "Danach startet die App neu."
	)
	restore_confirmation.popup_centered(Vector2i(540, 220))


func _restore_selected_backup() -> void:
	var result := StorageManager.restore_backup(_pending_restore_path)
	_pending_restore_path = ""
	status_label.text = str(result.message)
	if not bool(result.get("success", false)):
		return
	status_label.tooltip_text = str(result.get("safety_backup_path", ""))
	var executable_path := OS.get_executable_path()
	if not OS.has_feature("editor") and FileAccess.file_exists(executable_path):
		OS.create_process(executable_path, PackedStringArray())
		get_tree().quit()
		return
	get_tree().reload_current_scene()


func _on_transactions_changed(
	_transactions: Array,
	summary: Dictionary
) -> void:
	_apply_transaction_summary(summary)
	_rebuild_transaction_rows()


func _apply_transaction_summary(summary: Dictionary) -> void:
	BudgetManager.update_budget({
		"additional_income": float(summary.income),
		"variable_expenses": float(summary.expenses),
		"savings_payments": float(summary.savings),
		"weekly_expenses": float(summary.get("weekly_expenses", 0.0)),
		"weekly_credit": float(summary.get("weekly_credit", 0.0)),
		"weekly_credit_total": float(summary.get("weekly_credit_total", 0.0)),
	})
	if transaction_summary_values.has("income"):
		transaction_summary_values.income.text = _money(float(summary.income))
		transaction_summary_values.expenses.text = _money(float(summary.expenses))
		transaction_summary_values.savings.text = _money(float(summary.savings))
		transaction_summary_values.available.text = _money(
			float(BudgetManager.get_snapshot().available_now)
		)


func _on_savings_goals_changed(_goals: Array, summary: Dictionary) -> void:
	_apply_savings_summary(summary)
	_rebuild_savings_rows()


func _apply_savings_summary(summary: Dictionary) -> void:
	BudgetManager.update_budget({
		"savings_goal": float(summary.monthly_total),
	})
	if savings_summary_values.has("saved"):
		savings_summary_values.saved.text = _money(float(summary.saved_total))
		savings_summary_values.remaining.text = _money(float(summary.remaining_total))
		savings_summary_values.monthly.text = _money(float(summary.monthly_total))


func _on_fixed_costs_changed(_costs: Array, summary: Dictionary) -> void:
	_apply_fixed_cost_summary(summary)
	_rebuild_fixed_cost_rows()
	_rebuild_upcoming_costs()


func _rebuild_upcoming_costs() -> void:
	if not is_instance_valid(upcoming_cost_list):
		return
	for child in upcoming_cost_list.get_children():
		child.queue_free()

	var costs := FixedCostManager.get_costs()
	costs = costs.filter(
		func(cost: Dictionary) -> bool:
			return bool(cost.get("due_this_month", true))
	)
	costs.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			if bool(first.get("paid", false)) != bool(second.get("paid", false)):
				return not bool(first.get("paid", false))
			return int(first.get("due_day", 1)) < int(second.get("due_day", 1))
	)
	if costs.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Fixkosten eingetragen."
		empty.add_theme_color_override("font_color", COLORS.muted)
		upcoming_cost_list.add_child(empty)
		return

	for index in mini(costs.size(), 2):
		var cost: Dictionary = costs[index]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 48
		var icon := Label.new()
		icon.text = "✓" if bool(cost.get("paid", false)) else "⌂"
		icon.custom_minimum_size.x = 30
		icon.add_theme_font_size_override("font_size", 19)
		icon.add_theme_color_override(
			"font_color",
			COLORS.success if bool(cost.get("paid", false)) else COLORS.warning
		)
		row.add_child(icon)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name := Label.new()
		name.text = str(cost.get("name", "Fixkosten"))
		name.add_theme_color_override("font_color", COLORS.text)
		labels.add_child(name)
		var due := Label.new()
		due.text = "Fällig am %02d." % int(cost.get("due_day", 1))
		due.add_theme_font_size_override("font_size", 11)
		due.add_theme_color_override("font_color", COLORS.muted)
		labels.add_child(due)
		row.add_child(labels)
		var amount := Label.new()
		amount.text = _money(float(cost.get("amount", 0.0)))
		amount.add_theme_color_override("font_color", COLORS.text)
		row.add_child(amount)
		upcoming_cost_list.add_child(row)
		if index == 0:
			upcoming_cost_list.add_child(HSeparator.new())


func _apply_fixed_cost_summary(summary: Dictionary) -> void:
	BudgetManager.update_budget({
		"fixed_costs_total": float(summary.total),
		"fixed_costs_paid": float(summary.paid),
	})
	if fixed_summary_values.has("paid"):
		fixed_summary_values.paid.text = _money(float(summary.paid))
		fixed_summary_values.open.text = _money(float(summary.open))
		fixed_summary_values.free.text = _money(
			float(BudgetManager.get_snapshot().freely_available)
		)


func _refresh(snapshot: Dictionary) -> void:
	if is_instance_valid(world_view):
		var world_snapshot := snapshot.duplicate(true)
		world_snapshot["balance"] = float(snapshot.current_balance)
		world_snapshot["fixed_costs"] = FixedCostManager.get_costs().filter(
			func(cost: Dictionary) -> bool:
				return bool(cost.get("due_this_month", true))
		)
		world_view.set_snapshot(world_snapshot)
	for key: String in summary_values:
		var display_value := (
			float(snapshot.current_balance)
			if key == "balance"
			else float(snapshot[key])
		)
		summary_values[key].text = _money(display_value)
	if mobile_dashboard_values.has("balance"):
		mobile_dashboard_values.balance.text = _money(float(snapshot.current_balance))
		mobile_dashboard_values.free.text = _money(float(snapshot.freely_available))
		mobile_dashboard_values.fixed.text = _money(float(snapshot.fixed_costs_total))
		mobile_dashboard_values.weekly.text = _money(float(snapshot.weekly_free_budget))
	var week_spending := [0.0, 0.0, 0.0, 0.0]
	var week_credit := [0.0, 0.0, 0.0, 0.0]
	for transaction: Dictionary in TransactionManager.get_active_transactions():
		if str(transaction.get("category", "")) != "Wochenbudget":
			continue
		var week_index := mini(
			floori(float(clampi(int(transaction.get("day", 1)), 1, 31) - 1) / 7.0),
			3
		)
		if str(transaction.get("kind", "")) == "weekly_credit":
			week_credit[week_index] += float(transaction.get("amount", 0.0))
		elif str(transaction.get("kind", "")) == "expense":
			week_spending[week_index] += float(transaction.get("amount", 0.0))
	var base_weekly_budget := maxf(
		float(snapshot.weekly_free_budget) - float(snapshot.get("weekly_credit", 0.0)),
		0.0
	)
	for week_index in 4:
		var weekly_budget := base_weekly_budget + float(week_credit[week_index])
		var remaining := maxf(weekly_budget - float(week_spending[week_index]), 0.0)
		var value: Label = dashboard_flow_values.get("week_%d" % week_index)
		if is_instance_valid(value):
			value.text = "%s / %s" % [
				_money(remaining),
				_money(weekly_budget),
			]
	if fixed_summary_values.has("free"):
		fixed_summary_values.free.text = _money(float(snapshot.freely_available))
	if transaction_summary_values.has("available"):
		transaction_summary_values.available.text = _money(float(snapshot.available_now))
	_apply_shopping_state()


func _on_update_check_finished(result: Dictionary) -> void:
	status_label.text = str(result.get("message", "Update-Prüfung abgeschlossen."))
	if str(result.get("status", "")) != "update_available":
		return
	var download_url := str(result.get("download_url", "")).strip_edges()
	if download_url.begins_with("https://github.com/Liitschy/meine-budgetwelt/releases/"):
		status_label.text = "Neue Version %s gefunden – Download wird geöffnet." % str(
			result.get("version", "")
		)
		OS.shell_open(download_url)
	else:
		status_label.text = "Neue Version gefunden, aber der Download-Link ist ungültig."


func _style(
	background: Color,
	radius: int,
	border: Color = Color.TRANSPARENT
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _parchment_style() -> StyleBoxFlat:
	var style := _style(Color("#d9c292f5"), 20, Color("#98713a"))
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 14
	style.shadow_color = Color("#050302b8")
	style.shadow_size = 16
	return style


func _parchment_row_style() -> StyleBoxFlat:
	var style := _style(Color("#fff4d208"), 8, Color("#8e6e3f22"))
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style


func _glass_relic_style(accent: Color) -> StyleBoxFlat:
	var style := _style(Color("#092b2ddb"), 22, Color("#c19a50"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(accent, 0.22)
	style.shadow_size = 10
	return style


func _ornament_button_style(background: Color) -> StyleBoxFlat:
	var style := _style(background, 12, Color("#b68a46"))
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 1
	style.border_width_bottom = 2
	style.shadow_color = Color("#05030288")
	style.shadow_size = 4
	return style


func _fixed_cost_icon(category: String) -> String:
	match category:
		"Wohnen":
			return "⌂"
		"Kommunikation":
			return "◉"
		"Versicherung":
			return "♢"
		"Mobilität":
			return "◆"
		"Gesundheit":
			return "♥"
		"Abonnement":
			return "✦"
		"Sparen":
			return "❧"
		_:
			return "◈"


func _money(value: float) -> String:
	var raw := "%.2f" % value
	var parts := raw.split(".")
	var integer_part := parts[0]
	var grouped := ""
	while integer_part.length() > 3:
		grouped = "." + integer_part.right(3) + grouped
		integer_part = integer_part.left(integer_part.length() - 3)
	grouped = integer_part + grouped
	return "%s,%s €" % [grouped, parts[1]]
