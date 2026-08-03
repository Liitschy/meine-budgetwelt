extends Control

const BudgetWorldView := preload("res://ui/budget_world_view.gd")
const MonthUtils := preload("res://core/month_utils.gd")
const RecipeCatalog := preload("res://core/recipe_catalog.gd")
const WeeklyNeedCalculator := preload("res://core/weekly_need_calculator.gd")
const PackPlanner := preload("res://core/pack_planner.gd")
const WeeklyPlanningPage := preload("res://ui/weekly_planning_page.gd")
const WeeklyBudgetChart := preload("res://ui/weekly_budget_chart.gd")
const BankingPanel := preload("res://ui/banking_panel.gd")
const TouchScrollHelper := preload("res://core/touch_scroll_helper.gd")

const COLORS := {
	"background": Color("#080a0f"),
	"sidebar": Color("#090d12f2"),
	"panel": Color("#0d1218e8"),
	"panel_soft": Color("#10161cf2"),
	"accent": Color("#f0d3ae"),
	"gold": Color("#d58b5e"),
	"text": Color("#f0d3ae"),
	"muted": Color("#aaa4a4"),
	"warning": Color("#d99a68"),
	"success": Color("#9fbe9a"),
}
const BOOK_ART_SIZE := Vector2(1672.0, 941.0)

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
var sidebar_nav_buttons: Dictionary = {}
var book_navigation_controls: Array[Control] = []
var app_shell: VBoxContainer
var app_bar: Control
var app_bar_row: HBoxContainer
var desktop_nav_buttons: Dictionary = {}
var desktop_nav_container: Control
var desktop_month_control: Control
var desktop_month_selector_label: Button
var desktop_metric_row: Control
var weekly_budget_chart: Control
var app_local_status: Label
var app_bar_back_button: Button
var app_bar_leaf: Label
var app_bar_title: Label
var app_bar_settings_button: Button
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
var mobile_dashboard_captions: BoxContainer
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
var _current_page := "dashboard"
var _page_history: Array[String] = []
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
var settings_page: Control
var settings_account_label: Label
var settings_sync_label: Label
var settings_margin: MarginContainer
var settings_header: BoxContainer
var settings_header_back: Button
var settings_title: Label
var banking_panel: Control
var bank_institution_dialog: ConfirmationDialog
var bank_institution_input: OptionButton
var bank_institution_status: Label
var _bank_institutions: Array = []
var weekly_planning_page: Control
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
var login_panel: Control
var login_backdrop: Control
var login_margin: MarginContainer
var login_card: PanelContainer
var login_layout: BoxContainer
var login_title: Label
var login_name_row: Control
var login_name_input: LineEdit
var login_email_input: LineEdit
var login_password_input: LineEdit
var login_invitation_row: Control
var login_invitation_input: LineEdit
var login_remember_row: Control
var login_remember_input: CheckBox
var login_forgot_button: Button
var login_submit_button: Button
var login_mode_button: Button
var login_status_label: Label
var login_server_label: Label
var account_button: Button
var _registration_mode := false
var startup_status_panel: Control
var startup_status_card: PanelContainer
var startup_update_status: Label
var startup_update_action: Button
var update_confirmation: ConfirmationDialog
var _pending_update_url := ""
var _pending_update_sha256_url := ""
var _pending_update_version := ""
var _startup_update_check_active := false
var _automatic_update_active := false
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
var upcoming_cost_header: BoxContainer
var upcoming_cost_filter: Button
var dashboard_flow_values: Dictionary = {}
var display_font: Font
var interface_font: Font
var _responsive_layout_queued := false
var _sync_status_code := "synced"
var _sync_status_message := "Synchronisiert"


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_min_size(Vector2i(960, 640))
	_configure_web_content_scale()
	_apply_design_theme()
	_build_interface()
	_apply_heading_fonts(self)
	if not get_tree().node_added.is_connected(_on_touch_scroll_node_added):
		get_tree().node_added.connect(_on_touch_scroll_node_added)
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
	UpdateManager.update_download_status.connect(_on_update_download_status)
	SyncManager.session_changed.connect(_on_account_session_changed)
	SyncManager.sync_status_changed.connect(_on_sync_status_changed)
	SyncManager.sync_conflict.connect(_on_sync_conflict)
	_build_restore_dialog()
	_build_update_confirmation_dialog()
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
	resized.connect(_queue_responsive_layout)
	get_viewport().size_changed.connect(_queue_responsive_layout)
	_apply_responsive_layout()
	_configure_touch_scrolling()
	_queue_responsive_layout()
	call_deferred("_reset_dashboard_scroll")
	if get_tree().current_scene == self:
		call_deferred("_begin_account_startup")
		call_deferred("_begin_startup_update_check")


func _configure_web_content_scale() -> void:
	if not OS.has_feature("web"):
		return
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if browser_window == null:
		return
	var css_width := int(browser_window.innerWidth)
	var css_height := int(browser_window.innerHeight)
	if css_width < 280 or css_height < 320:
		return
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.content_scale_size = Vector2i(css_width, css_height)


func _apply_design_theme() -> void:
	if DisplayServer.get_name() == "headless":
		interface_font = ThemeDB.fallback_font
		display_font = ThemeDB.fallback_font
	else:
		var interface_system_font := SystemFont.new()
		interface_system_font.font_names = PackedStringArray([
			"Segoe UI Variable Display",
			"Segoe UI Variable Text",
			"Segoe UI",
		])
		interface_font = interface_system_font
		var display_system_font := SystemFont.new()
		display_system_font.font_names = PackedStringArray([
			"Georgia",
			"Palatino Linotype",
		])
		display_font = display_system_font
	var app_theme := Theme.new()
	app_theme.default_font = interface_font
	app_theme.default_font_size = 15
	app_theme.set_color("font_color", "Label", COLORS.text)
	app_theme.set_color("font_color", "Button", COLORS.text)
	app_theme.set_color("font_hover_color", "Button", Color.WHITE)
	app_theme.set_color("font_pressed_color", "Button", Color.WHITE)
	app_theme.set_stylebox("normal", "Button", _style(Color("#171624e8"), 12, Color("#5b4031")))
	app_theme.set_stylebox("hover", "Button", _style(Color("#292337f2"), 12, COLORS.accent))
	app_theme.set_stylebox("pressed", "Button", _style(Color("#382838"), 12, COLORS.gold))
	app_theme.set_stylebox("focus", "Button", _style(Color.TRANSPARENT, 12, COLORS.accent))
	app_theme.set_stylebox("normal", "LineEdit", _style(Color("#10111cf2"), 9, Color("#665468")))
	app_theme.set_stylebox("focus", "LineEdit", _style(Color("#10161c"), 9, COLORS.accent))
	app_theme.set_stylebox("normal", "SpinBox", _style(Color("#10111cf2"), 9, Color("#665468")))
	app_theme.set_stylebox("normal", "OptionButton", _style(Color("#10111cf2"), 9, Color("#665468")))
	app_theme.set_color("font_color", "LineEdit", COLORS.text)
	app_theme.set_color("font_color", "SpinBox", COLORS.text)
	app_theme.set_color("font_color", "OptionButton", COLORS.text)
	app_theme.set_color("font_color", "CheckBox", COLORS.text)
	app_theme.set_color("font_pressed_color", "CheckBox", COLORS.success)
	app_theme.set_color("icon_normal_color", "CheckBox", COLORS.muted)
	app_theme.set_color("icon_pressed_color", "CheckBox", COLORS.success)
	app_theme.set_color("separator_color", "HSeparator", Color("#5b4031"))
	app_theme.set_stylebox("background", "ProgressBar", _style(Color("#10111c"), 9, Color("#55485c")))
	app_theme.set_stylebox("fill", "ProgressBar", _style(Color("#d58b5e"), 9, COLORS.accent))
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


func _configure_touch_scrolling() -> void:
	TouchScrollHelper.configure(self)


func _on_touch_scroll_node_added(node: Node) -> void:
	TouchScrollHelper.configure_added_descendant(node)


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = COLORS.background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	desktop_backdrop = TextureRect.new()
	desktop_backdrop.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	desktop_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	desktop_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	desktop_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.92)
	desktop_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desktop_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(desktop_backdrop)

	var backdrop_tint := ColorRect.new()
	backdrop_tint.color = Color("#080a0f52")
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
	var dashboard_margin := MarginContainer.new()
	dashboard_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dashboard_margin.add_theme_constant_override("margin_left", 24)
	dashboard_margin.add_theme_constant_override("margin_right", 24)
	dashboard_margin.add_theme_constant_override("margin_top", 14)
	dashboard_margin.add_theme_constant_override("margin_bottom", 18)
	dashboard_margin.add_child(dashboard_page)
	dashboard_scroll.add_child(dashboard_margin)
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

	settings_page = _build_settings_page()
	settings_page.visible = false
	root.add_child(settings_page)

	weekly_planning_page = WeeklyPlanningPage.new()
	weekly_planning_page.visible = false
	weekly_planning_page.status_message.connect(_on_weekly_planning_status)
	weekly_planning_page.request_remove_shopping_item.connect(_remove_shopping_item)
	weekly_planning_page.request_book_shopping.connect(_book_shopping)
	weekly_planning_page.request_remove_recipe.connect(_remove_weekly_recipe)
	weekly_planning_page.request_remove_personal_price.connect(_remove_personal_price)
	root.add_child(weekly_planning_page)


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

	startup_status_panel = _build_startup_status_panel()
	startup_status_panel.visible = false
	add_child(startup_status_panel)

	login_panel = _build_login_panel()
	login_panel.visible = true
	add_child(login_panel)


func _build_login_panel() -> Control:
	var backdrop := Control.new()
	login_backdrop = backdrop
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var island := TextureRect.new()
	island.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	island.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	island.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	island.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	island.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(island)

	var tint := ColorRect.new()
	tint.color = Color("#080a0f66")
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(tint)

	var margin := MarginContainer.new()
	settings_margin = margin
	login_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	backdrop.add_child(margin)

	var login_scroll := ScrollContainer.new()
	login_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	login_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	login_scroll.follow_focus = true
	margin.add_child(login_scroll)
	login_layout = BoxContainer.new()
	login_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	login_scroll.add_child(login_layout)
	var card_center := CenterContainer.new()
	card_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	login_layout.add_child(card_center)

	login_card = PanelContainer.new()
	login_card.custom_minimum_size = Vector2(440, 0)
	var glass := _style(Color("#17131ef2"), 28, Color("#d58b5eaa"))
	glass.content_margin_left = 34
	glass.content_margin_right = 34
	glass.content_margin_top = 30
	glass.content_margin_bottom = 30
	glass.shadow_color = Color("#00070bbf")
	glass.shadow_size = 24
	login_card.add_theme_stylebox_override("panel", glass)
	card_center.add_child(login_card)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	login_card.add_child(column)
	var brand := Label.new()
	brand.text = "MEINE BUDGETWELT"
	brand.add_theme_font_size_override("font_size", 13)
	brand.add_theme_color_override("font_color", COLORS.accent)
	column.add_child(brand)
	login_title = Label.new()
	login_title.text = "Willkommen zurück"
	login_title.add_theme_font_override("font", display_font)
	login_title.add_theme_font_size_override("font_size", 34)
	column.add_child(login_title)
	var hint := Label.new()
	hint.text = "Melde dich an, damit Desktop und PWA denselben sicheren Datenstand verwenden."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(hint)
	login_server_label = Label.new()
	login_server_label.add_theme_font_size_override("font_size", 12)
	login_server_label.add_theme_color_override("font_color", COLORS.success)
	column.add_child(login_server_label)
	_update_login_server_label()

	login_name_input = LineEdit.new()
	login_name_input.placeholder_text = "Name"
	login_name_input.custom_minimum_size.y = 48
	login_name_row = login_name_input
	login_name_row.visible = false
	column.add_child(login_name_row)
	login_email_input = LineEdit.new()
	login_email_input.placeholder_text = "E-Mail-Adresse"
	login_email_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	login_email_input.custom_minimum_size.y = 48
	column.add_child(login_email_input)
	login_password_input = LineEdit.new()
	login_password_input.placeholder_text = "Kennwort – mindestens 8 Zeichen"
	login_password_input.secret = true
	login_password_input.custom_minimum_size.y = 48
	login_password_input.text_submitted.connect(func(_text: String) -> void: _submit_account_form())
	column.add_child(login_password_input)
	login_invitation_input = LineEdit.new()
	login_invitation_input.placeholder_text = "Einladungscode"
	login_invitation_input.custom_minimum_size.y = 48
	login_invitation_row = login_invitation_input
	login_invitation_row.visible = false
	column.add_child(login_invitation_row)

	login_remember_row = BoxContainer.new()
	var preferences := login_remember_row as BoxContainer
	login_remember_input = CheckBox.new()
	login_remember_input.text = "Angemeldet bleiben"
	preferences.add_child(login_remember_input)
	var preference_spacer := Control.new()
	preference_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preferences.add_child(preference_spacer)
	var show_password := CheckBox.new()
	show_password.text = "Kennwort anzeigen"
	show_password.toggled.connect(
		func(visible_password: bool) -> void:
			login_password_input.secret = not visible_password
	)
	preferences.add_child(show_password)
	column.add_child(preferences)

	login_forgot_button = Button.new()
	login_forgot_button.text = "Kennwort vergessen?"
	login_forgot_button.flat = true
	login_forgot_button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	login_forgot_button.pressed.connect(_request_login_password_reset)
	column.add_child(login_forgot_button)
	login_status_label = Label.new()
	login_status_label.text = "Bitte mit deinem Konto anmelden."
	login_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	login_status_label.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(login_status_label)
	login_submit_button = Button.new()
	login_submit_button.text = "Sicher anmelden"
	login_submit_button.custom_minimum_size.y = 52
	login_submit_button.add_theme_color_override("font_color", Color("#1a1117"))
	login_submit_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 14))
	login_submit_button.add_theme_stylebox_override("hover", _style(Color("#f0d8ad"), 14))
	login_submit_button.pressed.connect(_submit_account_form)
	column.add_child(login_submit_button)
	login_mode_button = Button.new()
	login_mode_button.text = "Konto mit Einladung erstellen"
	login_mode_button.flat = true
	login_mode_button.pressed.connect(_toggle_registration_mode)
	column.add_child(login_mode_button)

	var art_space := Control.new()
	art_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_layout.add_child(art_space)
	backdrop.resized.connect(_apply_login_layout)
	return backdrop


func _begin_account_startup() -> void:
	login_panel.visible = true
	_update_login_server_label()
	if SyncManager.startup_restore_attempted:
		if SyncManager.is_logged_in():
			login_panel.visible = false
			_apply_account_identity(SyncManager.current_user)
			call_deferred("_resume_banking_callback")
		else:
			login_status_label.text = "Bitte mit deinem Konto anmelden."
		return
	login_status_label.text = "Gespeicherte Sitzung wird sicher geprüft …"
	var result := await SyncManager.restore_session()
	if bool(result.get("success", false)):
		login_panel.visible = false
		_apply_account_identity(SyncManager.current_user)
		call_deferred("_resume_banking_callback")
	else:
		login_status_label.text = "Bitte mit deinem Konto anmelden."


func _submit_account_form() -> void:
	if _registration_mode:
		await _perform_registration()
	else:
		await _perform_login()


func _perform_login() -> void:
	login_submit_button.disabled = true
	login_status_label.text = "Anmeldung und Synchronisation werden geprüft …"
	var result := await SyncManager.login(
		login_email_input.text,
		login_password_input.text,
		login_remember_input.button_pressed
	)
	login_password_input.clear()
	login_submit_button.disabled = false
	login_status_label.text = str(result.get("message", "Anmeldung fehlgeschlagen."))
	if bool(result.get("success", false)):
		login_panel.visible = false
		_apply_account_identity(SyncManager.current_user)
		call_deferred("_resume_banking_callback")


func _perform_registration() -> void:
	if login_name_input.text.strip_edges().is_empty() or login_email_input.text.strip_edges().is_empty():
		login_status_label.text = "Bitte Name und E-Mail-Adresse vollständig eingeben."
		return
	login_submit_button.disabled = true
	login_status_label.text = "Konto wird über die Einladung erstellt …"
	var password := login_password_input.text
	var result := await SyncManager.register_with_invitation(
		login_name_input.text,
		password,
		login_invitation_input.text
	)
	if bool(result.get("success", false)):
		result = await SyncManager.login(
			login_email_input.text,
			password,
			login_remember_input.button_pressed
		)
	login_password_input.clear()
	login_submit_button.disabled = false
	login_status_label.text = str(result.get("message", "Konto konnte nicht erstellt werden."))
	if bool(result.get("success", false)):
		login_panel.visible = false
		_apply_account_identity(SyncManager.current_user)
		call_deferred("_resume_banking_callback")


func _request_login_password_reset() -> void:
	if login_email_input.text.strip_edges().is_empty():
		login_status_label.text = "Bitte zuerst deine E-Mail-Adresse eintragen."
		return
	login_forgot_button.disabled = true
	var result := await SyncManager.request_password_reset(login_email_input.text)
	login_forgot_button.disabled = false
	login_status_label.text = str(result.get("message", "Die Anfrage ist fehlgeschlagen."))


func _toggle_registration_mode() -> void:
	_registration_mode = not _registration_mode
	login_name_row.visible = _registration_mode
	login_invitation_row.visible = _registration_mode
	login_forgot_button.visible = not _registration_mode
	login_title.text = "Konto erstellen" if _registration_mode else "Willkommen zurück"
	login_submit_button.text = "Konto sicher erstellen" if _registration_mode else "Sicher anmelden"
	login_mode_button.text = "Zurück zur Anmeldung" if _registration_mode else "Konto mit Einladung erstellen"
	login_status_label.text = (
		"Für diese private Budgetwelt wird der Einladungscode des Administrators benötigt."
		if _registration_mode
		else "Bitte mit deinem Konto anmelden."
	)


func _update_login_server_label() -> void:
	if not is_instance_valid(login_server_label):
		return
	var server_target := SyncManager.server_url.trim_prefix("https://").trim_prefix("http://")
	login_server_label.text = "●  Serverziel: %s" % server_target


func _resume_banking_callback() -> void:
	if not OS.has_feature("web") or not SyncManager.is_logged_in():
		return
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if browser_window == null:
		return
	var query := str(browser_window.location.search)
	if not query.contains("banking="):
		return
	_show_page("transactions")
	await _show_bank_import()
	var callback_message := (
		"Die Bankfreigabe wurde bestätigt. Du kannst die Bank jetzt manuell aktualisieren."
		if query.contains("banking=connected")
		else "Die Bankfreigabe ist noch nicht abgeschlossen."
		if query.contains("banking=pending")
		else "Die Bankfreigabe wurde abgebrochen."
		if query.contains("banking=rejected")
		else "Die Bankfreigabe konnte nicht bestätigt werden."
	)
	banking_panel.set_message(
		callback_message,
		"success" if query.contains("banking=connected") else "error"
	)
	JavaScriptBridge.eval(
		"window.history.replaceState({}, document.title, window.location.pathname);",
		true
	)


func _on_account_session_changed(user: Dictionary) -> void:
	_apply_account_identity(user)


func _apply_account_identity(user: Dictionary) -> void:
	if is_instance_valid(account_button):
		account_button.text = str(user.get("displayName", "Konto")) if not user.is_empty() else "Anmelden"
	if is_instance_valid(settings_account_label):
		var display_name := str(user.get("displayName", "")).strip_edges()
		var email := str(user.get("email", "")).strip_edges()
		settings_account_label.text = (
			"%s · %s" % [display_name, email]
			if not user.is_empty()
			else "Kein Konto angemeldet"
		)
	_update_account_greeting()


func _update_account_greeting() -> void:
	if not is_instance_valid(dashboard_title):
		return
	var hour := int(Time.get_time_dict_from_system().hour)
	var greeting := "Guten Morgen" if hour < 11 else "Guten Tag" if hour < 18 else "Guten Abend"
	var name := str(SyncManager.current_user.get("displayName", "")).strip_edges()
	if name.is_empty():
		dashboard_title.text = greeting
	elif _compact_layout:
		dashboard_title.text = "%s, %s" % [greeting, name]
	else:
		dashboard_title.text = "%s,\n%s" % [greeting, name]

func _logout_account() -> void:
	await SyncManager.logout()
	login_panel.visible = true
	login_panel.move_to_front()
	login_status_label.text = "Du wurdest sicher abgemeldet."


func _on_sync_status_changed(status: String, message: String) -> void:
	_sync_status_code = status
	_sync_status_message = message
	if is_instance_valid(app_local_status):
		app_local_status.add_theme_color_override(
			"font_color",
			COLORS.success if status == "synced" else COLORS.warning if status in ["syncing", "conflict"] else COLORS.muted
		)
		_update_compact_sync_status()
	if is_instance_valid(status_label):
		status_label.text = message
	if is_instance_valid(settings_sync_label):
		settings_sync_label.text = message
		settings_sync_label.add_theme_color_override(
			"font_color",
			COLORS.success if status == "synced" else COLORS.warning if status in ["syncing", "conflict"] else COLORS.muted
		)


func _on_sync_conflict(_current: Dictionary) -> void:
	status_label.text = "Neuere Serverdaten wurden geschützt. Bitte vor dem Weiterarbeiten aktualisieren."


func _apply_login_layout() -> void:
	if not is_instance_valid(login_layout):
		return
	var available_size := login_backdrop.size if is_instance_valid(login_backdrop) else size
	var compact := available_size.x < 760.0 or available_size.y > available_size.x
	var outer_margin := 12 if compact else 36
	for side in ["margin_left", "margin_right"]:
		login_margin.add_theme_constant_override(side, outer_margin)
	login_margin.add_theme_constant_override("margin_top", 16 if compact else 28)
	login_margin.add_theme_constant_override("margin_bottom", 16 if compact else 28)
	login_layout.vertical = compact
	login_card.custom_minimum_size.x = minf(
		440.0,
		maxf(available_size.x - float(outer_margin * 2), 240.0)
	)
	var glass := login_card.get_theme_stylebox("panel") as StyleBoxFlat
	if glass != null:
		var content_margin := 24.0 if compact else 34.0
		glass.content_margin_left = content_margin
		glass.content_margin_right = content_margin
	login_title.add_theme_font_size_override("font_size", 29 if compact else 34)
	(login_remember_row as BoxContainer).vertical = compact


func _build_startup_status_panel() -> Control:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#080a0ff5")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	startup_status_card = PanelContainer.new()
	var panel := startup_status_card
	panel.add_theme_stylebox_override("panel", _style(Color("#17131f"), 22, COLORS.accent))
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Meine Budgetwelt startet"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)

	var version := Label.new()
	version.text = "Version %s" % UpdateManager.get_current_version()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(version)

	startup_update_status = Label.new()
	startup_update_status.text = "Update-Status wird vorbereitet …"
	startup_update_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	startup_update_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	startup_update_status.add_theme_font_size_override("font_size", 17)
	column.add_child(startup_update_status)

	startup_update_action = Button.new()
	startup_update_action.text = "Bitte warten …"
	startup_update_action.disabled = true
	startup_update_action.custom_minimum_size.y = 48
	startup_update_action.pressed.connect(_on_startup_update_action)
	column.add_child(startup_update_action)
	backdrop.resized.connect(_resize_startup_status_panel.bind(backdrop, panel, title))
	call_deferred("_resize_startup_status_panel", backdrop, panel, title)
	return backdrop


func _resize_startup_status_panel(backdrop: Control, panel: Control, title: Label) -> void:
	var panel_width := maxf(0.0, minf(520.0, backdrop.size.x - 24.0))
	var compact := panel_width < 440.0
	panel.custom_minimum_size = Vector2(panel_width, 310.0 if compact else 260.0)
	title.add_theme_font_size_override("font_size", 26 if compact else 30)


func _build_update_confirmation_dialog() -> void:
	update_confirmation = ConfirmationDialog.new()
	update_confirmation.title = "Update sicher installieren"
	update_confirmation.ok_button_text = "Herunterladen und prüfen"
	update_confirmation.cancel_button_text = "Später"
	update_confirmation.dialog_text = (
		"Der offizielle Setup-Installer und seine SHA-256-Prüfsumme werden geladen.\n"
		+ "Nur bei erfolgreicher Prüfung wird vorher eine Datensicherung erstellt "
		+ "und anschließend der Installer gestartet."
	)
	update_confirmation.confirmed.connect(_open_confirmed_update)
	add_child(update_confirmation)


func _begin_startup_update_check() -> void:
	if UpdateManager.startup_check_completed:
		_startup_update_check_active = false
		startup_status_panel.visible = false
		_show_required_login_if_needed()
		return
	if OS.has_feature("web"):
		_startup_update_check_active = false
		startup_status_panel.visible = true
		startup_status_panel.move_to_front()
		startup_update_status.text = "PWA-Updates werden beim Start sicher über den Server geladen."
		startup_update_action.text = "Zur Anmeldung"
		startup_update_action.disabled = false
		return
	_startup_update_check_active = true
	startup_status_panel.visible = true
	startup_status_panel.move_to_front()
	startup_update_status.text = "Updates werden geprüft …"
	startup_update_action.text = "Prüfung überspringen"
	startup_update_action.disabled = false
	UpdateManager.check_for_updates()


func _request_manual_update_check() -> void:
	_automatic_update_active = false
	status_label.text = "Updates werden geprüft …"
	UpdateManager.check_for_updates()


func _on_startup_update_action() -> void:
	if _startup_update_check_active:
		startup_status_panel.visible = false
		_show_required_login_if_needed()
		return
	if not _pending_update_url.is_empty():
		update_confirmation.popup_centered(Vector2i(mini(520, int(size.x) - 24), 230))
		return
	startup_status_panel.visible = false
	_show_required_login_if_needed()


func _show_required_login_if_needed() -> void:
	if not SyncManager.is_logged_in():
		login_panel.visible = true
		login_panel.move_to_front()


func _open_confirmed_update() -> void:
	if (
		_pending_update_version.is_empty()
		or _pending_update_url.is_empty()
		or _pending_update_sha256_url.is_empty()
	):
		return
	startup_status_panel.visible = true
	startup_status_panel.move_to_front()
	startup_update_status.text = "Der sichere Update-Download wird vorbereitet …"
	startup_update_action.text = "Bitte warten …"
	startup_update_action.disabled = true
	_automatic_update_active = false
	UpdateManager.download_update(
		_pending_update_version,
		_pending_update_url,
		_pending_update_sha256_url
	)


func _build_app_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size.y = 62
	var bar_style := _style(Color("#080b10f7"), 0, Color("#684632"))
	bar_style.border_width_left = 0
	bar_style.border_width_right = 0
	bar_style.border_width_top = 0
	bar_style.border_width_bottom = 1
	bar.add_theme_stylebox_override("panel", bar_style)
	var row := HBoxContainer.new()
	app_bar_row = row
	row.add_theme_constant_override("separation", 12)
	row.add_theme_constant_override("margin_left", 32)
	row.add_theme_constant_override("margin_right", 24)
	bar.add_child(row)

	app_bar_back_button = Button.new()
	app_bar_back_button.text = "‹"
	app_bar_back_button.tooltip_text = "Zurück"
	app_bar_back_button.custom_minimum_size = Vector2(42, 42)
	app_bar_back_button.flat = true
	app_bar_back_button.visible = false
	app_bar_back_button.pressed.connect(_navigate_back)
	row.add_child(app_bar_back_button)

	var brand := Label.new()
	app_bar_title = brand
	brand.text = "Meine Budgetwelt"
	brand.custom_minimum_size.x = 310
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.clip_text = true
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.add_theme_font_override("font", display_font)
	brand.add_theme_font_size_override("font_size", 26)
	brand.add_theme_color_override("font_color", Color("#d99569"))
	row.add_child(brand)

	app_bar_leaf = Label.new()
	app_bar_leaf.visible = false

	var nav := HBoxContainer.new()
	desktop_nav_container = nav
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	row.add_child(nav)
	for definition: Array in [
		["✦", "Übersicht", "dashboard"],
		["⌁", "Fixkosten", "fixed_costs"],
		["✣", "Sparen", "savings"],
		["⌁", "Buchungen", "transactions"],
		["✧", "Wochenplanung", "weekly_planning"],
		["✥", "Einstellungen", "settings"],
	]:
		var button := Button.new()
		button.text = "%s  %s" % [definition[0], definition[1]]
		button.flat = true
		button.custom_minimum_size = Vector2(126 if definition[2] != "weekly_planning" else 158, 54)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("#a9a1a2"))
		button.add_theme_stylebox_override("normal", _style(Color.TRANSPARENT, 0))
		button.add_theme_stylebox_override("hover", _style(Color("#17191fbb"), 0, Color("#6f4935")))
		button.pressed.connect(_show_page.bind(str(definition[2])))
		desktop_nav_buttons[str(definition[2])] = button
		nav.add_child(button)

	var month_panel := PanelContainer.new()
	desktop_month_control = month_panel
	month_panel.custom_minimum_size = Vector2(190, 42)
	month_panel.add_theme_stylebox_override("panel", _style(Color("#10141af2"), 10, Color("#4e382c")))
	var month_row := HBoxContainer.new()
	month_panel.add_child(month_row)
	desktop_month_selector_label = Button.new()
	desktop_month_selector_label.text = "August 2026  ⌄"
	desktop_month_selector_label.flat = true
	desktop_month_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop_month_selector_label.add_theme_color_override("font_color", Color("#e6c7a7"))
	desktop_month_selector_label.pressed.connect(_open_setup)
	month_row.add_child(desktop_month_selector_label)
	var calendar := Button.new()
	calendar.text = "▣"
	calendar.tooltip_text = "Monat einrichten"
	calendar.flat = true
	calendar.custom_minimum_size.x = 44
	calendar.add_theme_color_override("font_color", Color("#d58b5e"))
	calendar.pressed.connect(_open_setup)
	month_row.add_child(calendar)
	row.add_child(month_panel)

	app_local_status = Label.new()
	app_local_status.text = "Aktuell"
	app_local_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	app_local_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	app_local_status.clip_text = true
	app_local_status.add_theme_font_size_override("font_size", 15)
	app_local_status.add_theme_color_override("font_color", Color("#9ecb9c"))
	app_local_status.visible = false
	row.add_child(app_local_status)

	app_bar_settings_button = Button.new()
	app_bar_settings_button.visible = false
	account_button = Button.new()
	account_button.visible = false
	status_label = Label.new()
	status_label.visible = false
	return bar

func _build_summary_column() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 385
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	column.add_child(_build_upcoming_costs())
	return column

func _build_upcoming_costs() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := _style(Color("#0c1116f2"), 18, Color("#6f4935"))
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	var column := VBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	var header := BoxContainer.new()
	upcoming_cost_header = header
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var title := Label.new()
	title.text = "Nächste Fixkosten"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#f0d3ae"))
	header.add_child(title)
	var filter := Button.new()
	upcoming_cost_filter = filter
	filter.text = "Diese Woche  v"
	filter.custom_minimum_size = Vector2(104, 38)
	filter.add_theme_color_override("font_color", Color("#d7c2ab"))
	filter.add_theme_stylebox_override("normal", _style(Color("#14181df2"), 13, Color("#4e382c")))
	filter.pressed.connect(_show_page.bind("fixed_costs"))
	header.add_child(filter)
	column.add_child(HSeparator.new())

	upcoming_cost_list = VBoxContainer.new()
	upcoming_cost_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upcoming_cost_list.add_theme_constant_override("separation", 0)
	column.add_child(upcoming_cost_list)

	var all_button := Button.new()
	all_button.text = "Alle Fixkosten anzeigen  ›"
	all_button.custom_minimum_size.y = 42
	all_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	all_button.add_theme_color_override("font_color", Color("#d7c2ab"))
	all_button.add_theme_stylebox_override("normal", _style(Color("#10151af2"), 12, Color("#4e382c")))
	all_button.pressed.connect(_show_page.bind("fixed_costs"))
	column.add_child(all_button)
	return panel

func _build_month_flow() -> Control:
	weekly_budget_chart = WeeklyBudgetChart.new()
	weekly_budget_chart.custom_minimum_size.y = 168
	weekly_budget_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return weekly_budget_chart

func _build_mobile_dashboard_metrics() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for definition: Array in [
		["balance", "Kontostand", "res://assets/icons/orbit.svg", Color("#d8a35f")],
		["free", "Frei verfügbar", "res://assets/icons/leaf.svg", Color("#d98a5c")],
		["weekly", "Wochenbudget", "res://assets/icons/meal-plan.svg", Color("#d8a35f")],
	]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 132
		var card_style := _style(Color("#0d1218f2"), 18, Color("#5b4031"))
		card_style.content_margin_left = 10
		card_style.content_margin_right = 10
		card_style.content_margin_top = 15
		card_style.content_margin_bottom = 14
		card.add_theme_stylebox_override("panel", card_style)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		card.add_child(column)
		var content := HBoxContainer.new()
		content.add_theme_constant_override("separation", 6)
		column.add_child(content)
		var icon := TextureRect.new()
		icon.texture = load(str(definition[2]))
		icon.custom_minimum_size = Vector2(40, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = definition[1]
		title.add_theme_font_size_override("font_size", 12)
		title.add_theme_color_override("font_color", Color("#d7c2ab"))
		labels.add_child(title)
		var value := Label.new()
		value.text = "0,00 €"
		value.add_theme_font_override("font", display_font)
		value.add_theme_font_size_override("font_size", 22)
		value.add_theme_color_override("font_color", Color("#f0d3ae") if definition[0] != "free" else Color("#d98a5c"))
		labels.add_child(value)
		mobile_dashboard_values[definition[0]] = value
		content.add_child(labels)
		var progress := ProgressBar.new()
		progress.show_percentage = false
		progress.custom_minimum_size.y = 6
		progress.value = 45.0
		progress.add_theme_stylebox_override("background", _style(Color("#25282a"), 3))
		progress.add_theme_stylebox_override("fill", _style(Color("#f0d3ae") if definition[0] != "free" else Color("#d98a5c"), 3))
		mobile_dashboard_values["%s_progress" % definition[0]] = progress
		column.add_child(progress)
		grid.add_child(card)
	return grid

func _build_mobile_dashboard_actions() -> Control:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size.y = 190
	button.add_theme_stylebox_override("normal", _style(Color("#0d1218f2"), 18, Color("#5b4031")))
	button.add_theme_stylebox_override("hover", _style(Color("#141a20f5"), 18, Color("#9a6547")))
	button.pressed.connect(_show_page.bind("transactions"))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("margin_left", 22)
	column.add_theme_constant_override("margin_right", 22)
	column.add_theme_constant_override("margin_top", 18)
	column.add_theme_constant_override("margin_bottom", 18)
	column.add_theme_constant_override("separation", 8)
	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "▣  Diese Woche"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("#d7c2ab"))
	header.add_child(title)
	var arrow := Label.new()
	arrow.text = "›"
	arrow.add_theme_font_size_override("font_size", 36)
	arrow.add_theme_color_override("font_color", Color("#f0d3ae"))
	header.add_child(arrow)
	column.add_child(header)
	var value_row := HBoxContainer.new()
	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_override("font", display_font)
	value.add_theme_font_size_override("font_size", 42)
	value.add_theme_color_override("font_color", Color("#d98a5c"))
	mobile_dashboard_values["weekly_remaining"] = value
	value_row.add_child(value)
	var suffix := Label.new()
	suffix.text = "übrig"
	suffix.size_flags_vertical = Control.SIZE_SHRINK_END
	suffix.add_theme_font_size_override("font_size", 18)
	suffix.add_theme_color_override("font_color", Color("#c1b8b2"))
	value_row.add_child(suffix)
	column.add_child(value_row)
	var progress := ProgressBar.new()
	progress.show_percentage = false
	progress.custom_minimum_size.y = 8
	progress.add_theme_stylebox_override("background", _style(Color("#25282a"), 4))
	progress.add_theme_stylebox_override("fill", _style(Color("#b8799c"), 4))
	mobile_dashboard_values["weekly_remaining_progress"] = progress
	column.add_child(progress)
	var captions := BoxContainer.new()
	mobile_dashboard_captions = captions
	var spent := Label.new()
	spent.text = "Verbraucht: 0,00 €"
	spent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spent.add_theme_color_override("font_color", Color("#aaa4a4"))
	mobile_dashboard_values["weekly_spent_caption"] = spent
	captions.add_child(spent)
	var budget := Label.new()
	budget.text = "Wochenbudget: 0,00 €"
	budget.add_theme_color_override("font_color", Color("#aaa4a4"))
	mobile_dashboard_values["weekly_budget_caption"] = budget
	captions.add_child(budget)
	column.add_child(captions)
	button.add_child(column)
	return button

func _mobile_navigation_button_style(
	background: Color,
	border: Color = Color.TRANSPARENT
) -> StyleBoxFlat:
	var style := _style(background, 14, border)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_size = 0
	return style


func _build_mobile_navigation() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 108
	var panel_style := _style(Color("#090d12fa"), 0, Color("#5a3d2d"))
	panel_style.border_width_left = 0
	panel_style.border_width_right = 0
	panel_style.border_width_bottom = 0
	panel_style.border_width_top = 1
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 6
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	for item: Array in [
		["res://assets/icons/home.svg", "Budget", "dashboard"],
		["res://assets/icons/fixed-costs.svg", "Fixkosten", "fixed_costs"],
		["res://assets/icons/bookings.svg", "Buchungen", "transactions"],
		["res://assets/icons/meal-plan.svg", "Planung", "weekly_planning"],
		["res://assets/icons/orbit.svg", "Mehr", "settings"],
	]:
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size.y = 88
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.flat = true
		button.add_theme_stylebox_override(
			"normal", _mobile_navigation_button_style(Color.TRANSPARENT)
		)
		button.add_theme_stylebox_override(
			"hover",
			_mobile_navigation_button_style(Color("#241a15aa"), Color("#7a5038"))
		)
		button.add_theme_stylebox_override(
			"pressed",
			_mobile_navigation_button_style(Color("#3a291ee6"), Color("#6f4935"))
		)
		button.add_theme_stylebox_override(
			"hover_pressed",
			_mobile_navigation_button_style(Color("#3a291ee6"), Color("#6f4935"))
		)
		button.add_theme_stylebox_override(
			"focus", _mobile_navigation_button_style(Color.TRANSPARENT)
		)
		button.add_theme_stylebox_override(
			"disabled", _mobile_navigation_button_style(Color.TRANSPARENT)
		)
		button.pressed.connect(_show_page.bind(str(item[2])))
		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.texture = load(str(item[0]))
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)
		var label := Label.new()
		label.text = str(item[1])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color("#aaa4a4"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)
		button.add_child(content)
		button.set_meta("mobile_icon", icon)
		button.set_meta("mobile_label", label)
		mobile_nav_buttons[str(item[2])] = button
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
	emblem.add_theme_stylebox_override("panel", _style(Color("#12171c"), 37, COLORS.accent))
	var emblem_icon := TextureRect.new()
	emblem_icon.texture = load("res://assets/icons/orbit.svg")
	emblem_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.add_child(emblem_icon)
	emblem_center.add_child(emblem)
	column.add_child(emblem_center)
	column.add_spacer(false)

	var items := [
		["res://assets/icons/home.svg", "Deine Budgetwelt", "dashboard"],
		["res://assets/icons/fixed-costs.svg", "Fixkosten", "fixed_costs"],
		["res://assets/icons/meal-plan.svg", "Wochenplanung", "weekly_planning"],
		["res://assets/icons/savings.svg", "Sparen", "savings"],
		["res://assets/icons/bookings.svg", "Buchungen", "transactions"],
		["", "Einstellungen", "settings"],
	]
	for index in items.size():
		var item: Array = items[index]
		var button := Button.new()
		button.text = "⚙  Einstellungen" if str(item[2]) == "settings" else str(item[1])
		if not str(item[0]).is_empty():
			button.icon = load(str(item[0]))
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", COLORS.text)
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#171b20") if index == 0 else Color.TRANSPARENT, 12)
		)
		button.add_theme_stylebox_override("hover", _style(Color("#1d2228"), 12))
		button.pressed.connect(_show_page.bind(str(item[2])))
		button.set_meta("navigation_active", index == 0)
		sidebar_nav_buttons[str(item[2])] = button
		column.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var version := Label.new()
	version.text = "Version %s" % UpdateManager.get_current_version()
	version.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(version)

	status_label = Label.new()
	status_label.text = "Lokale Datenspeicherung aktiv"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(status_label)

	return panel


func _build_settings_page() -> Control:
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 28)
	scroll.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	var header := BoxContainer.new()
	header.vertical = false
	settings_header = header
	header.add_theme_constant_override("separation", 12)
	var back := Button.new()
	settings_header_back = back
	back.text = "←  Zurück"
	back.custom_minimum_size = Vector2(132, 46)
	back.pressed.connect(_navigate_back)
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	settings_title = title
	title.text = "Einstellungen"
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", COLORS.gold)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Konto, Synchronisierung, Banking, Daten und Updates"
	subtitle.add_theme_color_override("font_color", COLORS.muted)
	titles.add_child(subtitle)
	header.add_child(titles)
	content.add_child(header)

	content.add_child(_build_settings_account_card())
	content.add_child(_build_settings_banking_card())
	content.add_child(_build_settings_data_card())
	_apply_account_identity(SyncManager.current_user)
	return page


func _settings_card(title_text: String, accent: Color) -> Dictionary:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _glass_relic_style(accent))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COLORS.gold)
	content.add_child(title)
	return {"card": card, "content": content}


func _build_settings_account_card() -> Control:
	var parts := _settings_card("Konto & Synchronisierung", COLORS.accent)
	var content := parts.content as VBoxContainer
	settings_account_label = Label.new()
	settings_account_label.text = "Angemeldetes Konto wird geladen …"
	settings_account_label.add_theme_font_size_override("font_size", 17)
	content.add_child(settings_account_label)
	settings_sync_label = Label.new()
	settings_sync_label.text = "Die Synchronisierung wird nach der Anmeldung automatisch geprüft."
	settings_sync_label.add_theme_color_override("font_color", COLORS.muted)
	settings_sync_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(settings_sync_label)
	var logout := Button.new()
	logout.text = "Sicher abmelden"
	logout.custom_minimum_size.y = 46
	logout.pressed.connect(_logout_account)
	content.add_child(logout)
	return parts.card


func _build_settings_banking_card() -> Control:
	var parts := _settings_card("Bankkonto", COLORS.gold)
	var content := parts.content as VBoxContainer
	var hint := Label.new()
	hint.text = "Enable Banking ist ausschließlich lesend. Abrufe erfolgen nur auf Knopfdruck; Überweisungen, PIN und TAN sind ausgeschlossen."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	content.add_child(hint)
	var button := Button.new()
	button.text = "Bankkonto verbinden oder verwalten"
	button.custom_minimum_size.y = 48
	button.add_theme_color_override("font_color", Color("#1a1117"))
	button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	button.pressed.connect(_open_banking_settings)
	content.add_child(button)
	return parts.card


func _open_banking_settings() -> void:
	_show_page("transactions")
	_show_bank_import()


func _build_settings_data_card() -> Control:
	var parts := _settings_card("Daten & Updates", Color("#b8799c"))
	var content := parts.content as VBoxContainer
	var hint := Label.new()
	hint.text = "Sicherungen, Wiederherstellung und die manuelle Updateprüfung sind hier zentral erreichbar."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", COLORS.muted)
	content.add_child(hint)
	var backup := Button.new()
	backup.text = "▣  Daten sichern"
	backup.custom_minimum_size.y = 46
	backup.pressed.connect(_create_data_backup)
	content.add_child(backup)
	var restore := Button.new()
	restore.text = "↶  Daten wiederherstellen"
	restore.custom_minimum_size.y = 46
	restore.pressed.connect(_open_restore_dialog)
	content.add_child(restore)
	var update := Button.new()
	update.text = "↻  Nach Updates suchen"
	update.custom_minimum_size.y = 46
	update.pressed.connect(_request_manual_update_check)
	content.add_child(update)
	return parts.card


func _build_header() -> Control:
	var row := BoxContainer.new()
	row.vertical = false
	dashboard_header = row
	row.custom_minimum_size.y = 126
	row.add_theme_constant_override("separation", 20)

	var titles := VBoxContainer.new()
	titles.custom_minimum_size.x = 470
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "Guten Abend, Alex"
	dashboard_title = title
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 0
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#f0d3ae"))
	titles.add_child(title)
	var ornament := Label.new()
	ornament.text = "----------------"
	ornament.add_theme_font_size_override("font_size", 12)
	ornament.add_theme_color_override("font_color", Color("#d58b5e"))
	titles.add_child(ornament)
	var subtitle := Label.new()
	subtitle.text = "Alles Wichtige auf einen Blick"
	subtitle.visible = false
	dashboard_month_label = subtitle
	titles.add_child(subtitle)
	row.add_child(titles)

	month_controls = HBoxContainer.new()
	month_controls.visible = false
	month_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var month_button := Button.new()
	month_edit_button = month_button
	month_button.text = ""
	month_button.custom_minimum_size.y = 66
	month_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	month_button.add_theme_stylebox_override("normal", _style(Color("#0d1218f4"), 15, Color("#6f4935")))
	month_button.pressed.connect(_open_setup)
	var month_content := HBoxContainer.new()
	month_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	month_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	month_content.add_theme_constant_override("margin_left", 18)
	month_content.add_theme_constant_override("margin_right", 18)
	var month_icon := TextureRect.new()
	month_icon.texture = load("res://assets/icons/meal-plan.svg")
	month_icon.custom_minimum_size = Vector2(48, 48)
	month_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	month_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	month_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	month_content.add_child(month_icon)
	month_selector_label = Label.new()
	month_selector_label.text = "August 2026"
	month_selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	month_selector_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	month_selector_label.add_theme_font_size_override("font_size", 22)
	month_selector_label.add_theme_color_override("font_color", Color("#f0d3ae"))
	month_content.add_child(month_selector_label)
	var chevron := Label.new()
	chevron.text = "v"
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.add_theme_font_size_override("font_size", 28)
	chevron.add_theme_color_override("font_color", Color("#f0d3ae"))
	month_content.add_child(chevron)
	month_button.add_child(month_content)
	month_controls.add_child(month_button)
	row.add_child(month_controls)

	var metrics := HBoxContainer.new()
	desktop_metric_row = metrics
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.alignment = BoxContainer.ALIGNMENT_END
	metrics.add_theme_constant_override("separation", 12)
	metrics.add_child(_build_dashboard_metric_card("balance", "Kontostand", "◉", Color("#d8a35f")))
	metrics.add_child(_build_dashboard_metric_card("fixed_costs_total", "Fixkosten reserviert", "◯", Color("#d58b5e")))
	metrics.add_child(_build_dashboard_metric_card("freely_available", "Frei verfügbar", "✷", Color("#d58b5e")))
	metrics.add_child(_build_dashboard_metric_card("weekly_free_budget", "Wochenbudget", "◌", Color("#d8a35f")))
	row.add_child(metrics)
	return row


func _build_dashboard_metric_card(key: String, title_text: String, symbol: String, accent: Color) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 98)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _style(Color("#0d1218f2"), 15, Color("#47352c")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("margin_left", 14)
	column.add_theme_constant_override("margin_right", 14)
	column.add_theme_constant_override("margin_top", 12)
	column.add_theme_constant_override("margin_bottom", 10)
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var icon := Label.new()
	icon.text = symbol
	icon.custom_minimum_size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 30)
	icon.add_theme_color_override("font_color", accent)
	row.add_child(icon)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var caption := Label.new()
	caption.text = title_text
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color("#b9b1ac"))
	labels.add_child(caption)
	var value := Label.new()
	value.text = "0,00 €"
	value.add_theme_font_override("font", display_font)
	value.add_theme_font_size_override("font_size", 23)
	value.add_theme_color_override("font_color", Color("#f0d3ae") if key != "freely_available" else Color("#d98a5c"))
	labels.add_child(value)
	summary_values[key] = value
	row.add_child(labels)
	var progress := ProgressBar.new()
	progress.value = 58.0 if key != "freely_available" else 82.0
	progress.show_percentage = false
	progress.custom_minimum_size.y = 4
	progress.add_theme_stylebox_override("background", _style(Color("#24272a"), 2))
	progress.add_theme_stylebox_override("fill", _style(Color("#e3c09f"), 2))
	column.add_child(progress)
	return card

func _build_summary() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 345
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#5b4031")))

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
	change_balance.add_theme_color_override("font_color", Color("#1a1117"))
	change_balance.add_theme_stylebox_override("normal", _style(COLORS.accent, 11))
	change_balance.add_theme_stylebox_override("hover", _style(Color("#f0d8ad"), 11))
	change_balance.pressed.connect(_open_balance_dialog)
	column.add_child(change_balance)

	var definitions := [
		["balance", "Kontostand", COLORS.accent],
		["fixed_costs_total", "Für Fixkosten reserviert", COLORS.warning],
		["available_now", "Aktuell verfügbar", COLORS.success],
		["freely_available", "Nach allen Fixkosten frei", COLORS.accent],
		["weekly_free_budget", "Wochenbudget", Color("#9aa7c8")],
		["weekly_expenses", "Diese Woche ausgegeben", COLORS.warning],
		["weekly_budget_remaining", "Diese Woche noch übrig", Color("#9aa7c8")],
		["after_savings", "Nach Sparziel verfügbar", Color("#b99ac3")],
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
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 16, Color("#5b4031")))

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
			_style(Color("#211d2d"), 14, Color("#5b4031"))
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
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(page)

	var art := TextureRect.new()
	fixed_page_art = art
	art.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(1.0, 1.0, 1.0, 0.52)
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
	subtitle.add_theme_color_override("font_color", Color("#c8b7a6"))
	fixed_cost_month_label = subtitle
	titles.add_child(subtitle)
	header.add_child(titles)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var back_button := Button.new()
	back_button.text = "←  Zurück"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#161522d8")))
	back_button.pressed.connect(_navigate_back)
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Fixkosten hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#f0d3ae")))
	add_button.pressed.connect(_open_add_cost)
	header.add_child(add_button)

	fixed_summary_row = BoxContainer.new()
	fixed_summary_row.vertical = false
	fixed_summary_row.add_theme_constant_override("separation", 44)
	fixed_summary_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	fixed_summary_row.anchor_left = 0.132
	fixed_summary_row.anchor_top = 0.155
	fixed_summary_row.anchor_right = 0.826
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
	list_panel.add_theme_stylebox_override("panel", _glass_relic_style(COLORS.accent))
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
		label.add_theme_color_override("font_color", Color("#e5ca88"))
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
	hint.add_theme_color_override("font_color", COLORS.muted)
	list_column.add_child(hint)

	_build_book_navigation(page, "fixed_costs")
	return page_scroll


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
			Color("#f0d3ae") if item[1] == active_page else Color("#aaa4a4")
		)
		button.add_theme_stylebox_override(
			"normal",
			_style(Color("#15131e22"), 12, Color.TRANSPARENT)
		)
		button.add_theme_stylebox_override(
			"hover",
			_style(Color("#2c2333bb"), 12, Color("#5b4031"))
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
	save_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#121321d9")))
	save_button.pressed.connect(_create_data_backup)
	utilities.add_child(save_button)
	var restore_button := Button.new()
	restore_button.text = "↶  Wiederherstellen"
	restore_button.add_theme_color_override("font_color", Color("#dfc98f"))
	restore_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#121321d9")))
	restore_button.pressed.connect(_open_restore_dialog)
	utilities.add_child(restore_button)
	var update_button := Button.new()
	update_button.text = "◌  Updates suchen"
	update_button.add_theme_color_override("font_color", Color("#dfc98f"))
	update_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#121321d9")))
	update_button.pressed.connect(_request_manual_update_check)
	utilities.add_child(update_button)


func _fixed_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 112
	panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#0d1218e8"), 18, Color(accent, 0.55))
	)

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
		_style(Color("#181725cc"), 31, Color(accent, 0.75))
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
	title.add_theme_color_override("font_color", Color("#aaa4a4"))
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
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.y = 54 if _compact_layout else 0
		_style_mobile_section_label(empty, _compact_layout)
		fixed_cost_list.add_child(empty)
		return

	for cost: Dictionary in costs:
		fixed_cost_list.add_child(_build_fixed_cost_row(cost))


func _build_fixed_cost_row(cost: Dictionary) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size.y = 205 if _compact_layout else 76
	row_panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#17131ef2"), 18, Color("#d58b5e"))
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
		_style(Color("#221d2b"), 24, Color("#a57b65"))
	)
	var category_emblem := TextureRect.new()
	category_emblem.texture = load("res://assets/icons/fixed-costs.svg")
	category_emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	category_emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	category_emblem.custom_minimum_size = Vector2(30, 30)
	category_emblem.modulate = Color("#f0d3ae")
	category_emblem_panel.add_child(category_emblem)
	identity.add_child(category_emblem_panel)
	var identity_text := VBoxContainer.new()
	identity_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := Label.new()
	name.text = str(cost.name)
	name.add_theme_font_override("font", display_font)
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", Color("#f0d796"))
	identity_text.add_child(name)
	var recurring := Label.new()
	recurring.text = {
		"monthly": "Monatlich",
		"quarterly": "Quartalsweise",
		"yearly": "Jährlich",
	}.get(str(cost.get("frequency", "monthly")), "Monatlich")
	if not bool(cost.get("due_this_month", true)):
		recurring.text += " · diesen Monat nicht fällig"
	recurring.add_theme_color_override("font_color", Color("#aaa4a4"))
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
	category.add_theme_color_override("font_color", COLORS.muted)
	category.visible = not _compact_layout
	row.add_child(category)

	var due := Label.new()
	due.text = "%02d. des Monats" % int(cost.due_day)
	due.custom_minimum_size.x = 0 if _compact_layout else 130
	due.add_theme_color_override("font_color", Color("#d4c18e"))
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
	amount.add_theme_color_override("font_color", Color("#f6ead0"))
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
	paid.add_theme_color_override("font_color", Color("#e9dbb7"))
	paid.add_theme_color_override("font_hover_color", Color.WHITE)
	paid.add_theme_color_override("font_pressed_color", Color.WHITE)
	var paid_status_style := _style(Color("#201a29ef"), 9, Color("#5b4031"))
	paid_status_style.content_margin_top = 6
	paid_status_style.content_margin_bottom = 6
	paid.add_theme_stylebox_override("normal", paid_status_style)
	paid.add_theme_stylebox_override("hover", _style(Color("#2d2232"), 9, Color("#9a7480")))
	paid.add_theme_stylebox_override("pressed", _style(Color("#3a2736"), 9, COLORS.accent))
	paid.toggled.connect(_toggle_fixed_cost.bind(str(cost.id)))
	payment_status.add_child(paid)
	var progress := ProgressBar.new()
	progress.show_percentage = true
	progress.max_value = maxf(float(cost.amount), 0.01)
	progress.value = paid_amount
	progress.custom_minimum_size.y = 13
	progress.add_theme_font_size_override("font_size", 10)
	progress.add_theme_color_override("font_color", COLORS.text)
	progress.add_theme_stylebox_override("background", _style(Color("#5f526d70"), 6))
	progress.add_theme_stylebox_override("fill", _style(Color("#d58b5e"), 6))
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
	payment.add_theme_stylebox_override("normal", _ornament_button_style(Color("#261c25")))
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
	edit.add_theme_stylebox_override("normal", _ornament_button_style(Color("#261c25")))
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
		more.add_theme_stylebox_override("normal", _ornament_button_style(Color("#261c25")))
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
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(page)

	var art := TextureRect.new()
	savings_page_art = art
	art.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(1.0, 1.0, 1.0, 0.52)
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
	subtitle.add_theme_color_override("font_color", Color("#c8b7a6"))
	titles.add_child(subtitle)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var back_button := Button.new()
	back_button.text = "←  Zurück"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#161522d8")))
	back_button.pressed.connect(_navigate_back)
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Sparziel hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#f0d3ae")))
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
		_savings_summary_card("remaining", "Bis zu allen Zielen", Color("#b99ac3"))
	)
	savings_summary_row.add_child(
		_savings_summary_card("monthly", "Monatlich reserviert", COLORS.accent)
	)
	page.add_child(savings_summary_row)

	var list_panel := PanelContainer.new()
	savings_list_panel = list_panel
	list_panel.add_theme_stylebox_override("panel", _glass_relic_style(Color("#b8799c")))
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
	list_title.add_theme_color_override("font_color", Color("#e5ca88"))
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
	return page_scroll


func _savings_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 112
	var plaque_content_style := _style(Color("#0d1218e8"), 18, Color(accent, 0.55))
	plaque_content_style.content_margin_left = 18
	plaque_content_style.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", plaque_content_style)

	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color("#aaa4a4"))
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
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size.y = 54 if _compact_layout else 0
		_style_mobile_section_label(empty, _compact_layout)
		savings_list.add_child(empty)
		return

	for goal: Dictionary in goals:
		savings_list.add_child(_build_savings_goal_card(goal))


func _build_savings_goal_card(goal: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 190 if _compact_layout else 0
	var card_style := _style(Color("#17131ef2"), 18, Color("#d58b5e"))
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 14
	card_style.content_margin_bottom = 14
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
	name.add_theme_color_override("font_color", Color("#f0d796"))
	header.add_child(name)

	var percentage := Label.new()
	percentage.text = "%d %%" % roundi(
		float(goal.saved_amount) / float(goal.target_amount) * 100.0
	)
	percentage.add_theme_color_override("font_color", COLORS.accent)
	percentage.add_theme_font_size_override("font_size", 18 if _compact_layout else 15)
	header.add_child(percentage)
	column.add_child(header)

	var progress := ProgressBar.new()
	progress.min_value = 0.0
	progress.max_value = float(goal.target_amount)
	progress.value = float(goal.saved_amount)
	progress.show_percentage = false
	progress.custom_minimum_size.y = 18
	progress.add_theme_stylebox_override("background", _style(Color("#5f526d70"), 8))
	progress.add_theme_stylebox_override("fill", _style(Color("#d58b5e"), 8))
	column.add_child(progress)

	var details := Label.new()
	details.text = "%s von %s  ·  monatlich %s" % [
		_money(float(goal.saved_amount)),
		_money(float(goal.target_amount)),
		_money(float(goal.monthly_contribution)),
	]
	details.add_theme_color_override("font_color", Color("#aaa4a4"))
	details.add_theme_font_size_override("font_size", 16 if _compact_layout else 15)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(details)

	var actions := HBoxContainer.new()
	var deposit := Button.new()
	deposit.text = "+ Einzahlung eintragen"
	deposit.custom_minimum_size.y = 46 if _compact_layout else 0
	deposit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deposit.add_theme_color_override("font_color", Color("#e8cf8d"))
	deposit.add_theme_stylebox_override("normal", _ornament_button_style(Color("#261c25")))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_deposit)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_transactions_page() -> Control:
	var page_scroll := ScrollContainer.new()
	page_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var page := Control.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_scroll.add_child(page)

	var art := TextureRect.new()
	transactions_page_art = art
	art.texture = load("res://assets/space/cosmic-star-atlas-background.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(1.0, 1.0, 1.0, 0.52)
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
	subtitle.add_theme_color_override("font_color", Color("#c8b7a6"))
	titles.add_child(subtitle)
	header.add_child(titles)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var back_button := Button.new()
	back_button.text = "←  Zurück"
	back_button.custom_minimum_size = Vector2(150, 42)
	back_button.add_theme_color_override("font_color", Color("#e4ca8c"))
	back_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#161522d8")))
	back_button.pressed.connect(_navigate_back)
	header.add_child(back_button)
	var add_button := Button.new()
	add_button.text = "＋  Buchung hinzufügen"
	add_button.custom_minimum_size = Vector2(195, 42)
	add_button.add_theme_color_override("font_color", Color("#20150a"))
	add_button.add_theme_stylebox_override("normal", _ornament_button_style(Color("#f0d3ae")))
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
		_transaction_summary_card("savings", "Sparzahlungen", Color("#b99ac3"))
	)
	transaction_summary_row.add_child(
		_transaction_summary_card("available", "Aktuell verfügbar", COLORS.accent)
	)
	page.add_child(transaction_summary_row)

	var list_panel := PanelContainer.new()
	transactions_list_panel = list_panel
	list_panel.add_theme_stylebox_override("panel", _glass_relic_style(COLORS.gold))
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
	column.add_child(_build_transaction_mode_tabs())
	var list_header := BoxContainer.new()
	list_header.vertical = false
	transaction_list_header = list_header
	list_header.add_theme_constant_override("separation", 10)
	var list_title := Label.new()
	list_title.text = "Verlauf"
	transaction_list_title = list_title
	list_title.add_theme_font_override("font", display_font)
	list_title.add_theme_font_size_override("font_size", 21)
	list_title.add_theme_color_override("font_color", Color("#e5ca88"))
	list_header.add_child(list_title)
	var list_spacer := Control.new()
	list_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_header.add_child(list_spacer)
	transaction_filter_summary = Label.new()
	transaction_filter_summary.add_theme_color_override("font_color", COLORS.muted)
	list_header.add_child(transaction_filter_summary)
	transaction_weekly_filter_button = Button.new()
	transaction_weekly_filter_button.text = "Nur Wochenbudget"
	transaction_weekly_filter_button.toggle_mode = true
	transaction_weekly_filter_button.custom_minimum_size = Vector2(180, 42)
	transaction_weekly_filter_button.add_theme_color_override("font_color", Color("#e8cf8d"))
	transaction_weekly_filter_button.add_theme_stylebox_override(
		"normal",
		_ornament_button_style(Color("#261c25"))
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

	banking_panel = BankingPanel.new()
	banking_panel.visible = false
	banking_panel.manual_view_requested.connect(_show_manual_transactions)
	banking_panel.refresh_requested.connect(_refresh_bank_connection)
	banking_panel.import_requested.connect(_import_selected_bank_transactions)
	banking_panel.disconnect_requested.connect(_request_disconnect_bank)
	banking_panel.connect_requested.connect(_open_bank_selection)
	page.add_child(banking_panel)
	return page_scroll


func _build_transaction_mode_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_style(Color("#0d1218dd"), 12, Color("#5b4031"))
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var manual := Button.new()
	manual.text = "Manuell"
	manual.disabled = true
	manual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual.custom_minimum_size.y = 42
	manual.add_theme_color_override("font_color", Color("#20150a"))
	manual.add_theme_stylebox_override(
		"normal",
		_style(Color("#f0d3ae"), 11, Color("#f2d78d"))
	)
	row.add_child(manual)
	var banking := Button.new()
	banking.text = "Bankimport"
	banking.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banking.custom_minimum_size.y = 42
	banking.pressed.connect(_show_bank_import)
	row.add_child(banking)
	return panel


func _show_manual_transactions() -> void:
	if is_instance_valid(banking_panel):
		banking_panel.visible = false
	_rebuild_transaction_rows()


func _show_bank_import() -> void:
	if not is_instance_valid(banking_panel):
		return
	if not transactions_page.visible:
		_show_page("transactions")
	banking_panel.visible = true
	banking_panel.move_to_front()
	banking_panel.set_compact(_compact_layout)
	banking_panel.set_busy(true, "Bankstatus wird sicher geprüft.")
	var status_result := await BankingManager.reload_status()
	if not bool(status_result.get("success", false)):
		banking_panel.set_message(str(status_result.get(
			"message",
			"Der Bankstatus konnte nicht geladen werden."
		)), "error")
		return
	var banking_status: Dictionary = status_result.get("status", {})
	banking_panel.set_status(banking_status)
	if not bool(banking_status.get("enabled", false)):
		banking_panel.set_message(
			"Die Bankanbindung ist auf diesem Server noch nicht eingerichtet.",
			"info"
		)
		return
	var connections_result := await BankingManager.reload_connections()
	if not bool(connections_result.get("success", false)):
		banking_panel.set_message(str(connections_result.get(
			"message",
			"Die Bankverbindungen konnten nicht geladen werden."
		)), "error")
		return
	banking_panel.set_connections(connections_result.get("connections", []))
	banking_panel.set_message(
		"Bankverbindungen wurden geprüft. Ein Bankabruf erfolgt weiterhin nur auf Knopfdruck.",
		"success"
	)


func _refresh_bank_connection(connection_id: String) -> void:
	if connection_id.is_empty() or not is_instance_valid(banking_panel):
		return
	banking_panel.set_busy(true, "Kontostand und Buchungen werden ausschließlich lesend abgerufen.")
	var result := await BankingManager.refresh_connection(connection_id)
	if not bool(result.get("success", false)):
		banking_panel.set_message(str(result.get(
			"message",
			"Die Bankdaten konnten nicht geladen werden."
		)), "error")
		return
	var connections_result := await BankingManager.reload_connections()
	if bool(connections_result.get("success", false)):
		banking_panel.set_connections(connections_result.get("connections", []))
	banking_panel.set_data(result.get("preview", {}))
	banking_panel.set_message(
		"Aktuelle Bankdaten geladen. Es wurde noch keine Buchung übernommen.",
		"success"
	)


func _import_selected_bank_transactions(import_ids: Array[String]) -> void:
	var result := BankingManager.import_transactions(import_ids)
	if not bool(result.get("success", false)):
		banking_panel.set_message(str(result.get(
			"message",
			"Die ausgewählten Buchungen konnten nicht übernommen werden."
		)), "error")
		return
	banking_panel.set_data(BankingManager.get_preview())
	banking_panel.set_message(
		"%d Buchung(en) übernommen; %d Dublette(n) übersprungen." % [
			int(result.get("imported", 0)),
			int(result.get("duplicates", 0)),
		],
		"success"
	)


func _request_disconnect_bank(connection_id: String) -> void:
	if connection_id.is_empty():
		return
	_request_confirmation(
		"Die Bankfreigabe wird widerrufen. Bereits bestätigte und importierte Buchungen bleiben erhalten.",
		Callable(self, "_disconnect_bank").bind(connection_id)
	)


func _disconnect_bank(connection_id: String) -> void:
	banking_panel.set_busy(true, "Bankverbindung wird sicher getrennt.")
	var result := await BankingManager.disconnect_connection(connection_id)
	if not bool(result.get("success", false)):
		banking_panel.set_message(str(result.get(
			"message",
			"Die Bankverbindung konnte nicht getrennt werden."
		)), "error")
		return
	banking_panel.set_connections(BankingManager.get_connections())
	banking_panel.set_message("Bankverbindung wurde getrennt.", "success")


func _open_bank_selection() -> void:
	if not is_instance_valid(banking_panel):
		return
	banking_panel.set_busy(true, "Verfügbare Banken werden geladen.")
	var result := await BankingManager.load_institutions("DE")
	if not bool(result.get("success", false)):
		banking_panel.set_message(str(result.get(
			"message",
			"Die Bankenliste konnte nicht geladen werden."
		)), "error")
		return
	_bank_institutions = result.get("institutions", [])
	_ensure_bank_institution_dialog()
	bank_institution_input.clear()
	for raw_institution: Variant in _bank_institutions:
		if raw_institution is Dictionary:
			bank_institution_input.add_item(str(raw_institution.get("name", "Bank")))
	bank_institution_dialog.get_ok_button().disabled = _bank_institutions.is_empty()
	bank_institution_status.text = (
		"Keine Bank für Deutschland gefunden."
		if _bank_institutions.is_empty()
		else "Die Anmeldung erfolgt anschließend direkt bei deiner Bank im Browser."
	)
	banking_panel.set_message("Bankenliste geladen.", "success")
	bank_institution_dialog.popup_centered(Vector2i(
		mini(560, maxi(int(size.x) - 28, 300)),
		260
	))


func _ensure_bank_institution_dialog() -> void:
	if is_instance_valid(bank_institution_dialog):
		return
	bank_institution_dialog = ConfirmationDialog.new()
	bank_institution_dialog.title = "Bank sicher verbinden"
	bank_institution_dialog.ok_button_text = "Bei der Bank freigeben"
	bank_institution_dialog.cancel_button_text = "Abbrechen"
	bank_institution_dialog.confirmed.connect(_connect_selected_bank)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var explanation := Label.new()
	explanation.text = "Budgetwelt erhält ausschließlich Lesezugriff. PIN, TAN und Kennwort werden nur auf der Seite deiner Bank eingegeben."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(explanation)
	bank_institution_input = OptionButton.new()
	bank_institution_input.custom_minimum_size.y = 46
	column.add_child(bank_institution_input)
	bank_institution_status = Label.new()
	bank_institution_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bank_institution_status.add_theme_color_override("font_color", COLORS.muted)
	column.add_child(bank_institution_status)
	bank_institution_dialog.add_child(column)
	add_child(bank_institution_dialog)


func _connect_selected_bank() -> void:
	var index := bank_institution_input.selected
	if index < 0 or index >= _bank_institutions.size():
		banking_panel.set_message("Bitte eine Bank auswählen.", "error")
		return
	var institution: Variant = _bank_institutions[index]
	if not institution is Dictionary:
		banking_panel.set_message("Die ausgewählte Bank ist ungültig.", "error")
		return
	banking_panel.set_busy(true, "Sichere Bankfreigabe wird vorbereitet.")
	var result := await BankingManager.prepare_connection(str(institution.get("id", "")))
	if not bool(result.get("success", false)):
		banking_panel.set_message(str(result.get(
			"message",
			"Die Bankfreigabe konnte nicht vorbereitet werden."
		)), "error")
		return
	var open_result := BankingManager.open_authorization(str(result.get(
		"authorization_url",
		""
	)))
	if not bool(open_result.get("success", false)):
		banking_panel.set_message(str(open_result.get("message", "Browser konnte nicht geöffnet werden.")), "error")
		return
	bank_institution_dialog.hide()
	var connections_result := await BankingManager.reload_connections()
	if bool(connections_result.get("success", false)):
		banking_panel.set_connections(connections_result.get("connections", []))
	banking_panel.set_message(
		"Bankfreigabe im Browser geöffnet. Kehre danach zurück und wähle ‚Freigabe prüfen‘.",
		"success"
	)


func _transaction_summary_card(key: String, title_text: String, accent: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size.y = 105
	var plaque_content_style := _style(Color("#0d1218e8"), 18, Color(accent, 0.55))
	plaque_content_style.content_margin_left = 18
	plaque_content_style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", plaque_content_style)

	var column := VBoxContainer.new()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_override("font", display_font)
	title.add_theme_color_override("font_color", Color("#aaa4a4"))
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
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.custom_minimum_size.x = 0
		empty.custom_minimum_size.y = 62 if _compact_layout else 0
		_style_mobile_section_label(empty, _compact_layout)
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
	var transaction_style := _style(Color("#17131ef2"), 14, Color("#d58b5e"))
	transaction_style.content_margin_left = 8
	transaction_style.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", transaction_style)

	var row := HBoxContainer.new()
	panel.add_child(row)

	var day := Label.new()
	day.text = "%02d." % int(transaction.day)
	day.custom_minimum_size.x = 42 if _compact_layout else 68
	day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day.add_theme_font_size_override("font_size", 18)
	day.add_theme_color_override("font_color", Color("#d6bb78"))
	row.add_child(day)

	var description_column := VBoxContainer.new()
	description_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var description := Label.new()
	description.text = str(transaction.description)
	description.clip_text = _compact_layout
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_size_override("font_size", 17 if _compact_layout else 18)
	description.add_theme_font_override("font", display_font)
	description.add_theme_color_override("font_color", Color("#f0d796"))
	description_column.add_child(description)

	var category := Label.new()
	category.text = str(transaction.category)
	if str(transaction.category) == "Wochenbudget":
		var week_number := mini(
			floori(float(clampi(int(transaction.day), 1, 31) - 1) / 7.0),
			3
		) + 1
		category.text = "Wochenbudget · Woche %d" % week_number
	category.add_theme_color_override("font_color", Color("#aaa4a4"))
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
		Color("#d99a68") if kind == "weekly_credit"
		else Color("#9fbe9a") if kind == "income"
		else Color("#b99ac3") if kind == "saving"
		else Color("#d99a68")
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
	add.add_theme_color_override("font_color", Color("#1a1117"))
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
	list_panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#5b4031")))
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
	shopping_book_button.add_theme_color_override("font_color", Color("#1a1117"))
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
	panel.add_theme_stylebox_override("panel", _style(Color("#10161c"), 12))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))
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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
	weekly_list.add_theme_color_override("font_color", Color("#1a1117"))
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
	panel.add_theme_stylebox_override("panel", _style(COLORS.panel, 18, Color("#5b4031")))
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
	panel.add_theme_stylebox_override("panel", _style(Color("#10161c"), 12))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610f0"), 0))

	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(620, 520)
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, Color("#5b4031")))
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
	recipe_add_button.add_theme_color_override("font_color", Color("#1a1117"))
	recipe_add_button.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	recipe_add_button.pressed.connect(_add_open_recipe_to_shopping)
	buttons.add_child(recipe_add_button)
	column.add_child(buttons)
	return overlay


func _build_custom_recipe_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610f5"), 0))
	var center := CenterContainer.new()
	overlay.add_child(center)
	var dialog := PanelContainer.new()
	dialog.custom_minimum_size = Vector2(780, 720)
	dialog.add_theme_stylebox_override("panel", _style(COLORS.panel, 20, Color("#5b4031")))
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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
		panel.add_theme_stylebox_override("panel", _style(Color("#10161c"), 10))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_balance)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_fixed_payment_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))
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
	save.add_theme_color_override("font_color", Color("#1a1117"))
	save.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	save.pressed.connect(_save_fixed_payment)
	buttons.add_child(save)
	column.add_child(buttons)
	return overlay


func _build_confirmation_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	create.add_theme_color_override("font_color", Color("#1a1117"))
	create.add_theme_stylebox_override("normal", _style(COLORS.accent, 12))
	create.pressed.connect(_confirm_new_month)
	buttons.add_child(create)
	column.add_child(buttons)
	return overlay


func _build_setup_panel() -> PanelContainer:
	var overlay := PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _style(Color("#050610eb"), 0))

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
	save.add_theme_color_override("font_color", Color("#1a1117"))
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
	if is_instance_valid(desktop_month_selector_label):
		desktop_month_selector_label.text = "%s  ⌄" % month_name
	if is_instance_valid(dashboard_month_label):
		dashboard_month_label.text = "%s · Alles Wichtige auf einen Blick" % month_name
	if is_instance_valid(fixed_cost_month_label):
		fixed_cost_month_label.text = "Wiederkehrende Kosten für %s" % month_name
static func _should_use_compact_layout(view_size: Vector2, is_web: bool) -> bool:
	return view_size.x < 900.0 or (is_web and view_size.y > view_size.x)


static func _should_stack_dashboard(view_size: Vector2, is_web: bool) -> bool:
	return view_size.x < 1180.0 or (is_web and view_size.y > view_size.x)


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	_configure_touch_scrolling()

	var is_web := OS.has_feature("web")
	var responsive_size := _responsive_view_size()
	if is_web:
		var target_scale_size := Vector2i(
			maxi(roundi(responsive_size.x), 280),
			maxi(roundi(responsive_size.y), 320)
		)
		if get_window().content_scale_size != target_scale_size:
			get_window().content_scale_size = target_scale_size
	var compact := _should_use_compact_layout(responsive_size, is_web)
	var stacked_content := _should_stack_dashboard(responsive_size, is_web)
	var layout_changed := compact != _compact_layout
	_compact_layout = compact

	sidebar_panel.visible = false
	desktop_backdrop.visible = true
	mobile_navigation.visible = compact
	if compact and app_shell.get_child(app_shell.get_child_count() - 1) != mobile_navigation:
		app_shell.move_child(mobile_navigation, app_shell.get_child_count() - 1)
	if is_instance_valid(app_bar):
		app_bar.visible = true
	_update_app_bar_layout(compact)
	if is_instance_valid(settings_margin):
		for side in ["margin_left", "margin_right"]:
			settings_margin.add_theme_constant_override(side, 18 if compact else 28)
		settings_margin.add_theme_constant_override("margin_top", 14 if compact else 24)
	if is_instance_valid(settings_header):
		settings_header.vertical = compact
	if is_instance_valid(settings_header_back):
		settings_header_back.visible = not compact
	if is_instance_valid(settings_title):
		settings_title.add_theme_font_size_override("font_size", 32 if compact else 38)

	var dashboard_margin := dashboard_page.get_parent() as MarginContainer
	if is_instance_valid(dashboard_margin):
		dashboard_margin.add_theme_constant_override("margin_left", 18 if compact else 24)
		dashboard_margin.add_theme_constant_override("margin_right", 18 if compact else 24)
		dashboard_margin.add_theme_constant_override("margin_top", 16 if compact else 14)
		dashboard_margin.add_theme_constant_override("margin_bottom", 24 if compact else 18)
	dashboard_header.vertical = compact
	dashboard_header.add_theme_constant_override("separation", 18 if compact else 20)
	var dashboard_titles := dashboard_header.get_child(0) as VBoxContainer
	dashboard_titles.custom_minimum_size.x = 0 if compact else 470
	dashboard_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	dashboard_titles.alignment = BoxContainer.ALIGNMENT_BEGIN if compact else BoxContainer.ALIGNMENT_CENTER
	for heading: Label in dashboard_titles.get_children():
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if is_instance_valid(dashboard_title):
		_update_account_greeting()
		dashboard_title.add_theme_font_size_override("font_size", 48 if compact else 52)
	if is_instance_valid(month_controls):
		month_controls.visible = compact
		month_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_instance_valid(month_edit_button):
		month_edit_button.custom_minimum_size = Vector2(0, 66)
	if is_instance_valid(month_selector_label):
		month_selector_label.add_theme_font_override("font", interface_font)
		month_selector_label.add_theme_font_size_override("font_size", 22)
	if is_instance_valid(desktop_metric_row):
		desktop_metric_row.visible = not compact

	dashboard_body.vertical = compact or stacked_content
	mobile_dashboard_metrics.visible = compact
	if mobile_dashboard_metrics is GridContainer:
		(mobile_dashboard_metrics as GridContainer).columns = (
			1 if compact and responsive_size.x < 380.0 else 2
		)
	mobile_dashboard_actions.visible = compact
	if is_instance_valid(mobile_dashboard_captions):
		mobile_dashboard_captions.vertical = compact and responsive_size.x < 380.0
	summary_panel.visible = true
	month_flow_panel.visible = not compact
	if compact:
		dashboard_body.move_child(mobile_dashboard_metrics, 0)
		dashboard_body.move_child(world_view, 1)
		dashboard_body.move_child(mobile_dashboard_actions, 2)
		dashboard_body.move_child(summary_panel, 3)
	else:
		dashboard_body.move_child(world_view, 0)
		dashboard_body.move_child(summary_panel, 1)
	if world_view.has_method("set_compact_mode"):
		world_view.set_compact_mode(compact)
	if is_instance_valid(weekly_planning_page):
		weekly_planning_page.set_compact_mode(compact or responsive_size.x < 1180.0)
	if is_instance_valid(banking_panel):
		banking_panel.set_compact(compact)
	fixed_header.vertical = false
	fixed_summary_row.vertical = false
	fixed_list_header.visible = not compact

	world_view.custom_minimum_size = (
		Vector2(0, clampf(responsive_size.x * 1.38, 520.0, 610.0))
		if compact
		else Vector2(0, 520.0)
		if stacked_content
		else Vector2(760, 520)
	)
	summary_panel.custom_minimum_size = Vector2(0, 600) if compact else Vector2(385, 520)
	if is_instance_valid(upcoming_cost_header):
		upcoming_cost_header.vertical = compact and responsive_size.x < 380.0
	if is_instance_valid(upcoming_cost_filter):
		upcoming_cost_filter.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
			if compact and responsive_size.x < 380.0
			else Control.SIZE_SHRINK_END
		)
	dashboard_header.custom_minimum_size.y = 220 if compact else 126
	fixed_header.custom_minimum_size.y = 0 if compact else 82
	_apply_login_layout()
	var dialog_width := maxf(responsive_size.x - 32.0, 280.0)
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
		custom_recipe_dialog.custom_minimum_size.y = minf(
			720.0,
			maxf(responsive_size.y - 32.0, 520.0)
		)
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


func _queue_responsive_layout() -> void:
	if _responsive_layout_queued or not is_inside_tree():
		return
	_responsive_layout_queued = true
	call_deferred("_apply_queued_responsive_layout")


func _apply_queued_responsive_layout() -> void:
	_responsive_layout_queued = false
	_apply_responsive_layout()


func _responsive_view_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if not OS.has_feature("web"):
		return size
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if browser_window == null:
		return viewport_size
	var visual_viewport: JavaScriptObject = browser_window.visualViewport
	if visual_viewport != null:
		var visual_size := Vector2(
			float(visual_viewport.width),
			float(visual_viewport.height)
		)
		if visual_size.x > 0.0 and visual_size.y > 0.0:
			return visual_size
	var window_size := Vector2(
		float(browser_window.innerWidth),
		float(browser_window.innerHeight)
	)
	return window_size if window_size.x > 0.0 and window_size.y > 0.0 else viewport_size


func _apply_mobile_book_layout(compact: bool) -> void:
	for control: Control in book_navigation_controls:
		control.visible = false
	for header: Control in [fixed_header, savings_header, transactions_header]:
		if not is_instance_valid(header):
			continue
		var page := header.get_parent() as Control
		if page != null:
			page.custom_minimum_size = Vector2(
				0.0,
				1120.0 if compact else 0.0
			)
	var mobile_art := load("res://assets/space/cosmic-star-atlas-background.png")
	if is_instance_valid(fixed_page_art):
		fixed_page_art.texture = mobile_art
	if is_instance_valid(savings_page_art):
		savings_page_art.texture = mobile_art
	if is_instance_valid(transactions_page_art):
		transactions_page_art.texture = mobile_art
	if is_instance_valid(savings_list_title):
		_style_mobile_section_label(savings_list_title, compact)
	if is_instance_valid(transaction_list_title):
		_style_mobile_section_label(transaction_list_title, compact)

	_configure_book_region(
		fixed_header, fixed_summary_row, fixed_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.03, 0.145, 0.97, 0.285),
		Vector4(0.035, 0.325, 0.965, 0.985)
	)
	_configure_book_region(
		savings_header, savings_summary_row, savings_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.03, 0.145, 0.97, 0.285),
		Vector4(0.035, 0.325, 0.965, 0.985)
	)
	_configure_book_region(
		transactions_header, transaction_summary_row, transactions_list_panel, compact,
		Vector4(0.04, 0.015, 0.96, 0.135),
		Vector4(0.04, 0.145, 0.96, 0.275),
		Vector4(0.035, 0.315, 0.965, 0.985)
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
	var header_region := mobile_header if compact else Vector4(0.035, 0.025, 0.965, 0.15)
	var summary_region := mobile_summary if compact else Vector4(0.035, 0.165, 0.965, 0.31)
	var list_region := mobile_list if compact else Vector4(0.035, 0.33, 0.965, 0.975)
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


func _set_book_art_region(control: Control, region: Vector4) -> void:
	var page := control.get_parent() as Control
	if page == null:
		_set_anchor_region(control, region)
		return
	var page_size := page.size
	if page_size.x <= 0.0 or page_size.y <= 0.0:
		page_size = size
	if page_size.x <= 0.0 or page_size.y <= 0.0:
		_set_anchor_region(control, region)
		return
	var art_scale := maxf(
		page_size.x / BOOK_ART_SIZE.x,
		page_size.y / BOOK_ART_SIZE.y
	)
	var art_size := BOOK_ART_SIZE * art_scale
	var art_origin := (page_size - art_size) * 0.5
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = art_origin.x + region.x * art_size.x
	control.offset_top = art_origin.y + region.y * art_size.y
	control.offset_right = art_origin.x + region.z * art_size.x
	control.offset_bottom = art_origin.y + region.w * art_size.y


func _is_wide_book_layout(page_size: Vector2) -> bool:
	return page_size.y > 0.0 and page_size.x / page_size.y >= 1.95


func _desktop_book_ui_scale(page_size: Vector2) -> float:
	if page_size.x <= 0.0 or page_size.y <= 0.0:
		return 1.0
	return clampf(
		minf(page_size.x / BOOK_ART_SIZE.x, page_size.y / BOOK_ART_SIZE.y),
		0.78,
		1.08
	)


func _book_art_cover_scale(page_size: Vector2) -> float:
	if page_size.x <= 0.0 or page_size.y <= 0.0:
		return 1.0
	return maxf(page_size.x / BOOK_ART_SIZE.x, page_size.y / BOOK_ART_SIZE.y)


func _style_mobile_section_label(label: Label, compact: bool) -> void:
	label.add_theme_color_override("font_color", Color("#f0d99b"))
	label.add_theme_color_override(
		"font_outline_color", Color("#090a13e8") if compact else Color.TRANSPARENT
	)
	label.add_theme_constant_override("outline_size", 4 if compact else 0)
	var label_style := _style(Color("#11121ecc"), 10, Color("#5b4031"))
	label_style.content_margin_left = 10
	label_style.content_margin_right = 10
	label_style.content_margin_top = 5
	label_style.content_margin_bottom = 5
	label.add_theme_stylebox_override("normal", label_style)


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
	var header_page := header.get_parent() as Control
	var header_page_size := header_page.size if header_page != null else size
	if header_page_size.x <= 0.0 or header_page_size.y <= 0.0:
		header_page_size = size
	var wide_desktop := not compact and _is_wide_book_layout(header_page_size)
	var desktop_scale := 1.0 if compact else _desktop_book_ui_scale(header_page_size)
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
	title.add_theme_font_size_override(
		"font_size",
		34 if compact else roundi((30 if wide_desktop else 46) * desktop_scale)
	)
	subtitle.visible = not wide_desktop
	subtitle.add_theme_font_size_override(
		"font_size", 16 if compact else roundi(17 * desktop_scale)
	)
	title.add_theme_color_override(
		"font_outline_color", Color("#090a13f2") if compact else Color.TRANSPARENT
	)
	title.add_theme_constant_override("outline_size", 5 if compact else 0)
	subtitle.add_theme_color_override(
		"font_outline_color", Color("#090a13f2") if compact else Color.TRANSPARENT
	)
	subtitle.add_theme_constant_override("outline_size", 4 if compact else 0)
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
	back_button.text = "‹" if compact else "←  Zurück"
	back_button.custom_minimum_size = (
		Vector2(54, 54) if compact
		else Vector2(150, 42) * desktop_scale
	)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override(
		"font_size", 34 if compact else roundi(15 * desktop_scale)
	)
	if compact:
		back_button.add_theme_stylebox_override(
			"normal", _style(Color("#0d1218ef"), 27, Color("#d58b5e"))
		)
	add_button.text = "+" if compact else (
		"＋  Fixkosten hinzufügen" if header == fixed_header
		else "＋  Sparziel hinzufügen" if header == savings_header
		else "＋  Buchung hinzufügen"
	)
	add_button.custom_minimum_size = (
		Vector2(54, 54) if compact
		else Vector2(195, 42) * desktop_scale
	)
	add_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_button.add_theme_font_size_override(
		"font_size", 30 if compact else roundi(15 * desktop_scale)
	)
	if compact:
		add_button.add_theme_stylebox_override(
			"normal", _style(Color("#f0d3ae"), 27, Color("#f2d78d"))
		)


func _style_mobile_fixed_summaries(compact: bool) -> void:
	if not is_instance_valid(fixed_summary_row):
		return
	var summary_page := fixed_summary_row.get_parent() as Control
	var summary_page_size := summary_page.size if summary_page != null else size
	if summary_page_size.x <= 0.0 or summary_page_size.y <= 0.0:
		summary_page_size = size
	var desktop_scale := 1.0 if compact else _desktop_book_ui_scale(summary_page_size)
	fixed_summary_row.add_theme_constant_override(
		"separation",
		6 if compact else roundi(61 * _book_art_cover_scale(summary_page_size))
	)
	for card: Control in fixed_summary_row.get_children():
		card.custom_minimum_size.y = 92 if compact else 112.0 * desktop_scale
		card.clip_contents = compact
		card.add_theme_stylebox_override(
			"panel", _style(Color("#0d1218e8"), 16, Color("#d58b5e"))
		)
		var row := card.get_child(0) as HBoxContainer
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(
			"separation", 4 if compact else roundi(14 * desktop_scale)
		)
		var plaque_inset := row.get_child(0) as Control
		plaque_inset.visible = false
		plaque_inset.custom_minimum_size.x = 30.0 * desktop_scale
		var emblem_panel := row.get_child(1) as Control
		emblem_panel.visible = not compact
		emblem_panel.custom_minimum_size = (
			Vector2(34, 34) if compact else Vector2(62, 62) * desktop_scale
		)
		var emblem := emblem_panel.get_child(0) as Label
		emblem.custom_minimum_size = (
			Vector2(34, 34) if compact else Vector2(62, 62) * desktop_scale
		)
		emblem.add_theme_font_size_override(
			"font_size", 30 if compact else roundi(30 * desktop_scale)
		)
		var labels := row.get_child(2) as VBoxContainer
		labels.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_CENTER
		)
		labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		labels.alignment = BoxContainer.ALIGNMENT_CENTER
		labels.custom_minimum_size.x = 0
		var title := labels.get_child(0) as Label
		var value := labels.get_child(1) as Label
		if compact:
			title.text = (
				"Bezahlt" if card == fixed_summary_row.get_child(0)
				else "Noch offen" if card == fixed_summary_row.get_child(1)
				else "Danach frei"
			)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override(
			"font_size", 13 if compact else roundi(17 * desktop_scale)
		)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if compact else TextServer.AUTOWRAP_OFF
		value.add_theme_font_size_override(
			"font_size", 20 if compact else roundi(30 * desktop_scale)
		)


func _style_mobile_simple_summaries(row: BoxContainer, compact: bool) -> void:
	if not is_instance_valid(row):
		return
	var summary_page := row.get_parent() as Control
	var summary_page_size := summary_page.size if summary_page != null else size
	if summary_page_size.x <= 0.0 or summary_page_size.y <= 0.0:
		summary_page_size = size
	var desktop_scale := 1.0 if compact else _desktop_book_ui_scale(summary_page_size)
	row.add_theme_constant_override(
		"separation",
		6 if compact else roundi(61 * _book_art_cover_scale(summary_page_size))
	)
	for index in row.get_child_count():
		var card := row.get_child(index) as Control
		card.clip_contents = compact
		var style := _style(Color("#0d1218e8"), 16, Color("#d58b5e"))
		style.content_margin_left = 8 if compact else 18
		style.content_margin_right = 8 if compact else 18
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		var labels := card.get_child(0) as VBoxContainer
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		labels.alignment = BoxContainer.ALIGNMENT_CENTER
		labels.custom_minimum_size.x = 0
		var title := labels.get_child(0) as Label
		var value := labels.get_child(1) as Label
		if compact and row == savings_summary_row:
			title.text = ["Gespart", "Noch bis Ziel", "Monatlich"][index]
		title.clip_text = compact
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override(
			"font_size", 13 if compact else roundi(17 * desktop_scale)
		)
		value.add_theme_font_size_override(
			"font_size", 20 if compact else roundi(30 * desktop_scale)
		)


func _update_mobile_navigation(active_page: String = "") -> void:
	if active_page.is_empty():
		active_page = _current_page
	for key: String in mobile_nav_buttons:
		var button: Button = mobile_nav_buttons[key]
		var active := key == active_page
		var label := button.get_meta("mobile_label") as Label
		var icon := button.get_meta("mobile_icon") as TextureRect
		label.add_theme_color_override(
			"font_color", Color("#f0d3ae") if active else Color("#aaa4a4")
		)
		icon.modulate = Color(1, 1, 1, 1.0 if active else 0.68)
		button.add_theme_stylebox_override(
			"normal",
			_mobile_navigation_button_style(
				Color("#3a291ee6"), Color("#6f4935")
			) if active
			else _mobile_navigation_button_style(Color.TRANSPARENT)
		)

func _update_sidebar_navigation(active_page: String) -> void:
	for key: String in sidebar_nav_buttons:
		var sidebar_button: Button = sidebar_nav_buttons[key]
		sidebar_button.set_meta("navigation_active", key == active_page)
	for key: String in desktop_nav_buttons:
		var button: Button = desktop_nav_buttons[key]
		var active := key == active_page
		button.set_meta("navigation_active", active)
		button.add_theme_color_override(
			"font_color", Color("#f0d3ae") if active else Color("#aaa4a4")
		)
		var nav_style := StyleBoxFlat.new()
		nav_style.bg_color = Color("#15191dcc") if active else Color.TRANSPARENT
		nav_style.border_color = Color("#d58b5e") if active else Color.TRANSPARENT
		nav_style.border_width_bottom = 2 if active else 0
		nav_style.corner_radius_top_left = 10
		nav_style.corner_radius_top_right = 10
		button.add_theme_stylebox_override("normal", nav_style)

func _page_title(page: String) -> String:
	return {
		"dashboard": "Meine Budgetwelt",
		"fixed_costs": "Fixkosten",
		"weekly_planning": "Wochenplanung",
		"savings": "Sparziele",
		"transactions": "Buchungen",
		"settings": "Einstellungen",
	}.get(page, "Meine Budgetwelt")


func _update_app_bar_layout(compact: bool = _compact_layout) -> void:
	if is_instance_valid(app_bar):
		app_bar.custom_minimum_size.y = 90 if compact else 62
	if is_instance_valid(app_bar_back_button):
		app_bar_back_button.visible = compact and _current_page != "dashboard"
	if is_instance_valid(app_bar_title):
		app_bar_title.text = (
			_page_title(_current_page)
			if compact and _current_page != "dashboard"
			else "Meine Budgetwelt"
		)
		app_bar_title.custom_minimum_size.x = 0 if compact else 310
		var compact_width := _responsive_view_size().x
		app_bar_title.add_theme_font_size_override(
			"font_size",
			22 if compact and compact_width < 430.0 else 27 if compact else 26
		)
	if is_instance_valid(app_bar_row):
		app_bar_row.add_theme_constant_override("margin_left", 14 if compact else 32)
		app_bar_row.add_theme_constant_override("margin_right", 14 if compact else 24)
		app_bar_row.add_theme_constant_override("separation", 8 if compact else 12)
	if is_instance_valid(desktop_nav_container):
		desktop_nav_container.visible = not compact
	if is_instance_valid(desktop_month_control):
		desktop_month_control.visible = not compact
	if is_instance_valid(app_local_status):
		app_local_status.visible = compact and _current_page == "dashboard"
		_update_compact_sync_status()
	if is_instance_valid(account_button):
		account_button.visible = false
	if is_instance_valid(app_bar_settings_button):
		app_bar_settings_button.visible = false
	_update_sidebar_navigation(_current_page)

func _update_compact_sync_status() -> void:
	if not is_instance_valid(app_local_status):
		return
	app_local_status.text = {
		"synced": "Aktuell",
		"syncing": "Sync ...",
		"conflict": "Prüfen",
		"offline": "Offline",
		"error": "Fehler",
	}.get(_sync_status_code, "Status")
	app_local_status.tooltip_text = _sync_status_message
	app_local_status.custom_minimum_size.x = (
		58.0 if _responsive_view_size().x < 430.0 else 76.0
	)
	app_local_status.size_flags_horizontal = Control.SIZE_SHRINK_END
	app_local_status.add_theme_font_size_override(
		"font_size",
		13 if _responsive_view_size().x < 430.0 else 15
	)


func _navigate_back() -> void:
	if _page_history.is_empty():
		_show_page("dashboard", false)
		return
	var previous: String = _page_history.pop_back()
	_show_page(previous, false)


func _show_page(page: String, remember_history: bool = true) -> void:
	if remember_history and page != _current_page:
		if _page_history.is_empty() or _page_history.back() != _current_page:
			_page_history.append(_current_page)
	_current_page = page
	dashboard_scroll.visible = page == "dashboard"
	fixed_costs_page.visible = page == "fixed_costs"
	savings_page.visible = page == "savings"
	transactions_page.visible = page == "transactions"
	weekly_planning_page.visible = page == "weekly_planning"
	settings_page.visible = page == "settings"
	if is_instance_valid(app_bar):
		app_bar.visible = true
	if is_instance_valid(sidebar_panel):
		sidebar_panel.visible = false
	if is_instance_valid(mobile_navigation):
		mobile_navigation.visible = _compact_layout
	if is_instance_valid(shopping_page):
		shopping_page.visible = false
	if is_instance_valid(meal_plan_page):
		meal_plan_page.visible = false
	if is_instance_valid(desktop_backdrop):
		desktop_backdrop.visible = true
	_update_app_bar_layout()
	_update_mobile_navigation(page)
	_update_sidebar_navigation(page)
	if page == "fixed_costs":
		_rebuild_fixed_cost_rows()
	elif page == "savings":
		_rebuild_savings_rows()
	elif page == "transactions":
		_rebuild_transaction_rows()
	call_deferred("_configure_touch_scrolling")

func _show_not_ready(page_name: String) -> void:
	status_label.text = "%s folgt in einem späteren Entwicklungsschritt." % page_name


func _on_weekly_planning_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message


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


func _remove_weekly_recipe(recipe_id: String) -> void:
	var recipe := CustomRecipeManager.get_recipe(recipe_id)
	if recipe.is_empty():
		return
	_request_confirmation(
		"Das Rezept „%s“ wird dauerhaft aus deiner synchronisierten Sammlung gelöscht." % str(recipe.get("title", "")),
		Callable(weekly_planning_page, "remove_recipe_confirmed").bind(recipe_id)
	)


func _remove_personal_price(price_id: String) -> void:
	var price := ShoppingManager.get_personal_price(price_id)
	if price.is_empty():
		return
	_request_confirmation(
		"Der persönliche Preis für „%s“ wird dauerhaft gelöscht." % str(price.get("name", "")),
		Callable(weekly_planning_page, "remove_personal_price_confirmed").bind(price_id)
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
		empty.add_theme_color_override("font_color", Color("#aaa4a4"))
		upcoming_cost_list.add_child(empty)
		return

	var day_names := ["MO", "DI", "MI", "DO", "FR", "SA", "SO"]
	for index in mini(costs.size(), 6):
		var cost: Dictionary = costs[index]
		var paid := bool(cost.get("paid", false))
		var due_day := int(cost.get("due_day", 1))
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 68
		row.add_theme_constant_override("separation", 6)
		var date := VBoxContainer.new()
		date.custom_minimum_size.x = 38
		var weekday := Label.new()
		weekday.text = day_names[(due_day - 1) % 7]
		weekday.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		weekday.add_theme_font_size_override("font_size", 10)
		weekday.add_theme_color_override("font_color", Color("#aaa4a4"))
		date.add_child(weekday)
		var day := Label.new()
		day.text = "%02d" % due_day
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day.add_theme_font_override("font", display_font)
		day.add_theme_font_size_override("font_size", 23)
		day.add_theme_color_override("font_color", Color("#f0d3ae"))
		date.add_child(day)
		row.add_child(date)
		var state := Label.new()
		state.text = "●"
		state.custom_minimum_size.x = 12
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state.add_theme_color_override("font_color", Color("#73b883") if paid else Color("#d87b75"))
		row.add_child(state)
		var emblem := Label.new()
		emblem.text = _fixed_cost_icon(str(cost.get("category", "Fixkosten")))
		emblem.custom_minimum_size = Vector2(34, 40)
		emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emblem.add_theme_font_size_override("font_size", 21)
		emblem.add_theme_color_override("font_color", Color("#d58b5e"))
		row.add_child(emblem)
		var labels := VBoxContainer.new()
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.alignment = BoxContainer.ALIGNMENT_CENTER
		var name := Label.new()
		name.text = str(cost.get("name", "Fixkosten"))
		name.clip_text = true
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name.add_theme_color_override("font_color", Color("#e7d4bf"))
		labels.add_child(name)
		var category := Label.new()
		category.text = str(cost.get("category", "Fixkosten"))
		category.add_theme_font_size_override("font_size", 11)
		category.add_theme_color_override("font_color", Color("#858489"))
		labels.add_child(category)
		row.add_child(labels)
		var amount_labels := VBoxContainer.new()
		amount_labels.custom_minimum_size.x = 78
		amount_labels.alignment = BoxContainer.ALIGNMENT_CENTER
		var amount := Label.new()
		amount.text = _money(float(cost.get("amount", 0.0)))
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount.add_theme_color_override("font_color", Color("#e7d4bf"))
		amount_labels.add_child(amount)
		var status := Label.new()
		status.text = "Bezahlt" if paid else "Geplant"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.add_theme_font_size_override("font_size", 11)
		status.add_theme_color_override("font_color", Color("#d58b5e") if paid else Color("#858489"))
		amount_labels.add_child(status)
		row.add_child(amount_labels)
		upcoming_cost_list.add_child(row)
		if index < mini(costs.size(), 6) - 1:
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
			else float(snapshot.get(key, 0.0))
		)
		var value_label: Label = summary_values[key]
		value_label.text = _money(display_value)

	var current_balance := float(snapshot.current_balance)
	var free := float(snapshot.freely_available)
	var weekly_budget := float(snapshot.weekly_free_budget)
	var weekly_spent := float(snapshot.weekly_expenses)
	var weekly_remaining := float(snapshot.get("weekly_budget_remaining", maxf(weekly_budget - weekly_spent, 0.0)))
	if mobile_dashboard_values.has("balance"):
		(mobile_dashboard_values.balance as Label).text = _money(current_balance)
		(mobile_dashboard_values.free as Label).text = _money(free)
		(mobile_dashboard_values.weekly as Label).text = _money(weekly_budget)
		(mobile_dashboard_values.weekly_remaining as Label).text = _money(weekly_remaining)
		(mobile_dashboard_values.weekly_spent_caption as Label).text = "Verbraucht: %s" % _money(weekly_spent)
		(mobile_dashboard_values.weekly_budget_caption as Label).text = "Wochenbudget: %s" % _money(weekly_budget)
		var balance_progress := mobile_dashboard_values.balance_progress as ProgressBar
		balance_progress.value = clampf(free / current_balance * 100.0 if current_balance > 0.0 else 0.0, 0.0, 100.0)
		var free_progress := mobile_dashboard_values.free_progress as ProgressBar
		free_progress.value = clampf(free / current_balance * 100.0 if current_balance > 0.0 else 0.0, 0.0, 100.0)
		var weekly_progress := mobile_dashboard_values.weekly_progress as ProgressBar
		weekly_progress.value = clampf(weekly_remaining / weekly_budget * 100.0 if weekly_budget > 0.0 else 0.0, 0.0, 100.0)
		var remaining_progress := mobile_dashboard_values.weekly_remaining_progress as ProgressBar
		remaining_progress.value = clampf(weekly_spent / weekly_budget * 100.0 if weekly_budget > 0.0 else 0.0, 0.0, 100.0)
	if is_instance_valid(weekly_budget_chart):
		weekly_budget_chart.set_data(weekly_budget, weekly_spent, "Diese Woche")
	if fixed_summary_values.has("free"):
		fixed_summary_values.free.text = _money(free)
	if transaction_summary_values.has("available"):
		transaction_summary_values.available.text = _money(float(snapshot.available_now))
	_apply_shopping_state()

func _on_update_check_finished(result: Dictionary) -> void:
	var message := str(result.get("message", "Update-Prüfung abgeschlossen."))
	var status := str(result.get("status", ""))
	status_label.text = message
	_pending_update_url = ""
	_pending_update_sha256_url = ""
	_pending_update_version = ""
	var was_startup_check := _startup_update_check_active
	_startup_update_check_active = false
	if status != "update_available":
		_automatic_update_active = false
		if was_startup_check:
			startup_update_status.text = message
			startup_update_action.text = "Zur App"
			startup_update_action.disabled = false
		return
	var version := str(result.get("version", "")).strip_edges()
	var download_url := str(result.get("download_url", "")).strip_edges()
	var sha256_url := str(result.get("sha256_url", "")).strip_edges()
	if UpdateManager.is_valid_release_urls(version, download_url, sha256_url):
		_pending_update_version = version
		_pending_update_url = download_url
		_pending_update_sha256_url = sha256_url
		var available_message := "Neue Version %s ist verfügbar." % str(
			version
		)
		status_label.text = available_message
		if was_startup_check and UpdateManager.can_install_automatically():
			_automatic_update_active = true
			startup_update_status.text = (
				"Version %s wird automatisch heruntergeladen und sicher geprüft …" % version
			)
			startup_update_action.text = "Automatisches Update läuft …"
			startup_update_action.disabled = true
			UpdateManager.download_update(version, download_url, sha256_url)
		elif was_startup_check:
			startup_update_status.text = available_message
			startup_update_action.text = "Update herunterladen"
			startup_update_action.disabled = false
		else:
			update_confirmation.popup_centered(Vector2i(mini(520, int(size.x) - 24), 230))
	else:
		status_label.text = "Neue Version gefunden, aber der Download-Link ist ungültig."
		if was_startup_check:
			startup_update_status.text = status_label.text
			startup_update_action.text = "Zur App"
			startup_update_action.disabled = false


func _on_update_download_status(result: Dictionary) -> void:
	var status := str(result.get("status", ""))
	var message := str(result.get("message", "Der Update-Vorgang wurde beendet."))
	status_label.text = message
	startup_status_panel.visible = true
	startup_status_panel.move_to_front()
	startup_update_status.text = message

	if status in ["checking_checksum", "downloading", "busy"]:
		startup_update_action.text = "Bitte warten …"
		startup_update_action.disabled = true
		return

	if status != "ready":
		_automatic_update_active = false
		startup_update_action.text = "Erneut versuchen"
		startup_update_action.disabled = false
		return

	var backup := StorageManager.create_backup()
	var backup_ready := (
		bool(backup.get("success", false))
		or bool(backup.get("nothing_to_backup", false))
	)
	if not backup_ready:
		_automatic_update_active = false
		status_label.text = "Das Update wurde nicht gestartet: %s" % str(
			backup.get("message", "Die Datensicherung ist fehlgeschlagen.")
		)
		startup_update_status.text = status_label.text
		startup_update_action.text = "Zur App"
		startup_update_action.disabled = false
		return

	var installer_path := str(result.get("installer_path", ""))
	var automatic_install := (
		_automatic_update_active and UpdateManager.can_install_automatically()
	)
	if not UpdateManager.launch_verified_installer(installer_path, automatic_install):
		_automatic_update_active = false
		status_label.text = "Der geprüfte Installer konnte nicht gestartet werden."
		startup_update_status.text = status_label.text
		startup_update_action.text = "Zur App"
		startup_update_action.disabled = false
		return

	_automatic_update_active = false
	status_label.text = "Das geprüfte Update wurde gestartet."
	startup_update_status.text = (
		"Das Update wird automatisch installiert. "
		+ "Meine Budgetwelt startet danach selbstständig neu."
		if automatic_install
		else "Der geprüfte Installer wurde gestartet. Die App wird jetzt geschlossen."
	)
	get_tree().quit()


func _style(
	background: Color,
	radius: int,
	border: Color = Color.TRANSPARENT
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	if background.a > 0.15 and radius >= 12:
		style.shadow_color = Color("#00000066")
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 3)
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _parchment_style() -> StyleBoxFlat:
	var style := _style(Color("#0d1218f2"), 20, Color("#5b4031aa"))
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color("#00000088")
	style.shadow_size = 12
	return style


func _parchment_row_style() -> StyleBoxFlat:
	var style := _style(Color("#10161caa"), 12, Color("#5b403144"))
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _glass_relic_style(accent: Color) -> StyleBoxFlat:
	var border := Color("#5b4031").lerp(accent, 0.22)
	var style := _style(Color("#0d1218e8"), 20, Color(border, 0.82))
	style.shadow_color = Color("#00000088")
	style.shadow_size = 12
	return style


func _ornament_button_style(background: Color) -> StyleBoxFlat:
	var style := _style(background, 12, Color("#5b4031aa"))
	style.shadow_color = Color("#00000066")
	style.shadow_size = 6
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
