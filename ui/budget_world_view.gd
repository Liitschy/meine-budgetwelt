extends Control

const ORBIT_ART := preload("res://assets/space/financial-orbit-system-v1.png")
const BACKDROP := Color("#080a0f")
const PANEL := Color("#0c1116f2")
const BORDER := Color("#6f4935")
const CHAMPAGNE := Color("#f0d3ae")
const COPPER := Color("#d58b5e")
const MUTED := Color("#afa8a7")
const ROSE := Color("#c77f82")

var snapshot: Dictionary = {}
var _compact_mode := false
var _display_font: Font
var _interface_font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if DisplayServer.get_name() == "headless":
		return
	clip_contents = true
	_display_font = SystemFont.new()
	_interface_font = SystemFont.new()
	(_display_font as SystemFont).font_names = PackedStringArray(["Georgia", "Palatino Linotype"])
	(_interface_font as SystemFont).font_names = PackedStringArray(["Segoe UI Variable Text", "Segoe UI"])
	queue_redraw()


func _exit_tree() -> void:
	_display_font = null
	_interface_font = null

func set_snapshot(value: Dictionary) -> void:
	snapshot = value.duplicate(true)
	queue_redraw()


func set_compact_mode(value: bool) -> void:
	if _compact_mode == value:
		return
	_compact_mode = value
	queue_redraw()


func _draw() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if size.x < 8.0 or size.y < 8.0:
		return
	var outer := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	draw_style_box(_panel_style(), outer)
	var title_size := 25 if _compact_mode else 20
	_draw_text(Vector2(24, 40 if _compact_mode else 35), "Finanzielle Umlaufbahn  ⓘ", title_size, CHAMPAGNE, _display_font)
	var art_rect := _art_rect()
	draw_texture_rect(ORBIT_ART, art_rect, false, Color(1, 1, 1, 0.98))
	_draw_month_markers(art_rect)
	_draw_budget_labels(art_rect)
	if not _compact_mode:
		_draw_legend()


func _art_rect() -> Rect2:
	var top := 50.0 if _compact_mode else 42.0
	var bottom := 18.0 if _compact_mode else 38.0
	var available := Rect2(12, top, size.x - 24.0, size.y - top - bottom)
	if not _compact_mode:
		return available
	var edge := minf(available.size.x, available.size.y)
	return Rect2(
		available.position + Vector2((available.size.x - edge) * 0.5, 0),
		Vector2(edge, edge)
	)


func _draw_budget_labels(art_rect: Rect2) -> void:
	var free_amount := float(snapshot.get("freely_available", snapshot.get("available_now", 0.0)))
	var total := maxf(float(snapshot.get("fixed_costs_total", 0.0)), 0.01)
	var categories := _category_totals()
	var positions: Array[Vector2] = [
		Vector2(0.245, 0.255),
		Vector2(0.755, 0.365),
		Vector2(0.285, 0.690),
		Vector2(0.685, 0.710),
	]
	var center := art_rect.position + art_rect.size * Vector2(0.5, 0.505)
	_draw_centered(center + Vector2(0, -3), _money(free_amount), 32 if _compact_mode else 34, Color("#17100d"), _display_font)
	_draw_centered(center + Vector2(0, 31), "frei", 28 if _compact_mode else 30, Color("#17100d"), _display_font)
	for index in mini(categories.size(), positions.size()):
		var category: Dictionary = categories[index]
		var point := art_rect.position + art_rect.size * positions[index]
		var font_size := 16 if _compact_mode else 17
		_draw_centered(point + Vector2(0, -12), str(category.name), font_size, CHAMPAGNE, _display_font)
		_draw_centered(point + Vector2(0, 11), _money(float(category.amount)), font_size, CHAMPAGNE, _display_font)
		_draw_centered(
			point + Vector2(0, 32),
			"%d %%" % roundi(float(category.amount) / total * 100.0),
			13,
			CHAMPAGNE,
			_interface_font
		)


func _category_totals() -> Array[Dictionary]:
	var grouped: Dictionary = {}
	for raw_cost: Variant in snapshot.get("fixed_costs", []):
		if raw_cost is not Dictionary:
			continue
		var cost := raw_cost as Dictionary
		var category := str(cost.get("category", "Sonstiges"))
		grouped[category] = float(grouped.get(category, 0.0)) + float(cost.get("amount", 0.0))
	var result: Array[Dictionary] = []
	for category: String in grouped:
		result.append({"name": category, "amount": float(grouped[category])})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.amount) > float(b.amount))
	if result.is_empty():
		result = [
			{"name": "Wohnen", "amount": 0.0},
			{"name": "Freizeit", "amount": 0.0},
			{"name": "Mobilität", "amount": 0.0},
			{"name": "Lebensmittel", "amount": 0.0},
		]
	return result.slice(0, 4)


func _draw_month_markers(rect: Rect2) -> void:
	var markers := [
		[Vector2(0.50, 0.045), "APR"], [Vector2(0.79, 0.18), "JUN"],
		[Vector2(0.93, 0.72), "SEP"], [Vector2(0.50, 0.955), "AUG"],
		[Vector2(0.15, 0.86), "OKT"], [Vector2(0.055, 0.60), "JAN"],
		[Vector2(0.10, 0.27), "DEZ"],
	]
	for marker: Array in markers:
		var position := rect.position + rect.size * (marker[0] as Vector2)
		draw_circle(position, 3.4, COPPER)
		_draw_centered(position + Vector2(0, -10 if position.y > rect.get_center().y else 18), str(marker[1]), 11, COPPER, _interface_font)


func _draw_legend() -> void:
	var y := size.y - 20.0
	draw_line(Vector2(24, y), Vector2(46, y), CHAMPAGNE, 2.0, true)
	_draw_text(Vector2(54, y + 5), "Geplant", 11, MUTED, _interface_font)
	draw_dashed_line(Vector2(120, y), Vector2(144, y), Color(COPPER, 0.65), 1.0, 5.0, true)
	_draw_text(Vector2(151, y + 5), "Ausgegeben", 11, MUTED, _interface_font)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(BORDER, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color("#00000088")
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 5)
	return style


func _draw_centered(position: Vector2, text: String, font_size: int, color: Color, font: Font) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, position - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_text(position: Vector2, text: String, font_size: int, color: Color, font: Font) -> void:
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _money(value: float) -> String:
	var raw := "%.2f" % value
	var parts := raw.split(".")
	var integer_part := parts[0]
	var grouped := ""
	while integer_part.length() > 3:
		grouped = "." + integer_part.right(3) + grouped
		integer_part = integer_part.left(integer_part.length() - 3)
	return "%s%s,%s €" % [integer_part, grouped, parts[1]]