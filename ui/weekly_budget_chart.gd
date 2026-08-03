extends Control

const PANEL := Color("#0c1116f2")
const BORDER := Color("#6f4935")
const CHAMPAGNE := Color("#f0d3ae")
const COPPER := Color("#d58b5e")
const ROSE := Color("#c77f92")
const MUTED := Color("#afa8a7")

var weekly_budget := 0.0
var weekly_spent := 0.0
var date_range := "Diese Woche"
var _display_font: Font
var _interface_font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if DisplayServer.get_name() == "headless":
		return
	_display_font = SystemFont.new()
	_interface_font = SystemFont.new()
	(_display_font as SystemFont).font_names = PackedStringArray(["Georgia", "Palatino Linotype"])
	(_interface_font as SystemFont).font_names = PackedStringArray(["Segoe UI Variable Text", "Segoe UI"])
	queue_redraw()


func _exit_tree() -> void:
	_display_font = null
	_interface_font = null

func set_data(budget: float, spent: float, range_text: String = "Diese Woche") -> void:
	weekly_budget = maxf(budget, 0.0)
	weekly_spent = maxf(spent, 0.0)
	date_range = range_text
	queue_redraw()


func _draw() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if size.x < 20.0 or size.y < 20.0:
		return
	var rect := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	draw_style_box(_panel_style(), rect)
	var remaining := maxf(weekly_budget - weekly_spent, 0.0)
	var usage := clampf(weekly_spent / weekly_budget if weekly_budget > 0.0 else 0.0, 0.0, 1.0)
	_draw_text(Vector2(24, 32), "Wochenplanung · %s  ⓘ" % date_range, 18, CHAMPAGNE, _display_font)
	_draw_text(Vector2(24, 65), "Ziel", 11, MUTED, _interface_font)
	_draw_text(Vector2(24, 84), _money(weekly_budget), 15, CHAMPAGNE, _display_font)
	_draw_text(Vector2(24, 112), "Verbleibend", 11, MUTED, _interface_font)
	_draw_text(Vector2(24, 136), _money(remaining), 19, COPPER, _display_font)
	var graph_left := 145.0
	var graph_right := size.x - 250.0
	var baseline := size.y - 36.0
	var top := 68.0
	if graph_right > graph_left + 80.0:
		_draw_week_curve(Rect2(graph_left, top, graph_right - graph_left, baseline - top), usage)
	_draw_usage(Vector2(size.x - 128.0, size.y * 0.56), usage)


func _draw_week_curve(rect: Rect2, usage: float) -> void:
	var weights := [0.11, 0.18, 0.10, 0.14, 0.0, 0.24, 0.0]
	var points := PackedVector2Array()
	var labels := ["MO 17", "DI 18", "MI 19", "DO 20", "FR 21", "SA 22", "SO 23"]
	for index in range(7):
		var x := rect.position.x + rect.size.x * float(index) / 6.0
		var y := rect.end.y - rect.size.y * (0.18 + float(weights[index]) * 2.2)
		points.append(Vector2(x, y))
		draw_line(Vector2(x, y - 17), Vector2(x, y + 16), Color(CHAMPAGNE, 0.42), 1.0, true)
		draw_circle(Vector2(x, y), 5.0, Color("#8d5d78"))
		draw_circle(Vector2(x, y), 2.8, CHAMPAGNE if index != 3 else Color("#86b88c"))
		_draw_centered(Vector2(x, rect.end.y + 20), labels[index], 10, MUTED, _interface_font)
	var area := PackedVector2Array([Vector2(points[0].x, rect.end.y)])
	for point in points:
		area.append(point)
	area.append(Vector2(points[-1].x, rect.end.y))
	draw_colored_polygon(area, Color("#79506a55"))
	draw_polyline(points, Color("#c77f92"), 1.6, true)
	draw_dashed_line(Vector2(rect.position.x, rect.position.y + 18), Vector2(rect.end.x, rect.position.y + 18), Color(COPPER, 0.48), 1.0, 5.0, true)


func _draw_usage(center: Vector2, usage: float) -> void:
	draw_arc(center, 36.0, 0.0, TAU, 64, Color("#4a393a"), 5.0, true)
	draw_arc(center, 36.0, -PI * 0.5, -PI * 0.5 + TAU * usage, 64, ROSE, 5.0, true)
	_draw_text(center + Vector2(53, -4), "%d %%" % roundi(usage * 100.0), 27, COPPER, _display_font)
	_draw_text(center + Vector2(53, 20), "des Wochenbudgets", 11, MUTED, _interface_font)
	_draw_text(center + Vector2(53, 37), "verwendet", 11, COPPER, _interface_font)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(BORDER, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color("#00000088")
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
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