extends Control

const WORLD_ART := preload("res://assets/space/cosmic-star-atlas-background.png")

var snapshot: Dictionary = {}
var _time := 0.0
var _compact_mode := false

const WATER := Color("#0a817e")
const WATER_LIGHT := Color("#43e0cc")
const LAND := Color("#264b3d")
const GRASS := Color("#4c7445")
const STONE := Color("#40514b")
const GOLD := Color("#ffc56f")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)


func set_snapshot(value: Dictionary) -> void:
	snapshot = value
	queue_redraw()


func set_compact_mode(value: bool) -> void:
	if _compact_mode == value:
		return
	_compact_mode = value
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if snapshot.is_empty():
		return

	var art_size := WORLD_ART.get_size()
	var view_ratio := size.x / maxf(size.y, 1.0)
	var art_ratio := art_size.x / art_size.y
	var contain_scale := minf(size.x / art_size.x, size.y / art_size.y)
	var cover_scale := maxf(size.x / art_size.x, size.y / art_size.y)
	var scale_factor := (
		contain_scale
		if view_ratio >= art_ratio
		else lerpf(contain_scale, cover_scale, 0.38)
	)
	var rendered_size := art_size * scale_factor
	var art_rect := Rect2((size - rendered_size) * 0.5, rendered_size)
	draw_texture_rect(WORLD_ART, art_rect, false)

	if _compact_mode:
		return

	var shimmer := 0.92 + sin(_time * 1.5) * 0.06
	_draw_income_badge(_art_point(art_rect, Vector2(0.50, 0.105)), shimmer)
	_draw_fixed_cost_badge(_art_point(art_rect, Vector2(0.315, 0.405)))
	_draw_savings_badge(_art_point(art_rect, Vector2(0.665, 0.315)))
	if size.x >= 520.0:
		_draw_cost_labels(art_rect)
	_draw_available_badge(_art_point(art_rect, Vector2(0.54, 0.635)), shimmer)


func _art_point(rect: Rect2, relative: Vector2) -> Vector2:
	return rect.position + rect.size * relative


func _draw_income_badge(position: Vector2, shimmer: float) -> void:
	var box := Rect2(position - Vector2(116, 43), Vector2(232, 86))
	draw_style_box(
		_panel_style(Color("#17131ef0"), 42, Color("#e4c99a") * shimmer),
		box
	)
	_draw_centered_text(position + Vector2(0, -8), "KONTOSTAND", 12, Color("#e4c99a"))
	_draw_centered_text(position + Vector2(0, 25), _money(float(snapshot.balance)), 25, Color.WHITE)


func _draw_fixed_cost_badge(position: Vector2) -> void:
	var box := Rect2(position - Vector2(91, 34), Vector2(182, 68))
	draw_style_box(_panel_style(Color("#1a1319ed"), 15, Color("#b8734b")), box)
	_draw_centered_text(position + Vector2(0, -6), "FIXKOSTEN RESERVIERT", 10, Color("#d8a27f"))
	_draw_centered_text(position + Vector2(0, 20), _money(float(snapshot.fixed_costs_total)), 19, Color.WHITE)


func _draw_savings_badge(position: Vector2) -> void:
	var box := Rect2(position - Vector2(82, 31), Vector2(164, 62))
	draw_style_box(_panel_style(Color("#211720ed"), 15, Color("#9a6474")), box)
	_draw_centered_text(position + Vector2(0, -5), "SPARZIEL", 11, Color("#d6a8b6"))
	_draw_centered_text(position + Vector2(0, 19), _money(float(snapshot.savings_goal)), 18, Color.WHITE)


func _draw_available_badge(position: Vector2, shimmer: float) -> void:
	var box := Rect2(position - Vector2(116, 36), Vector2(232, 72))
	draw_style_box(
		_panel_style(Color("#24151ced"), 17, Color("#e4c99a") * shimmer),
		box
	)
	_draw_centered_text(position + Vector2(0, -8), "NACH ALLEN FIXKOSTEN FREI", 10, Color("#e4c99a"))
	_draw_centered_text(position + Vector2(0, 21), _money(float(snapshot.freely_available)), 24, Color.WHITE)


func _draw_cost_labels(art_rect: Rect2) -> void:
	var costs: Array = snapshot.get("fixed_costs", [])
	var positions := [
		Vector2(0.315, 0.485),
		Vector2(0.325, 0.565),
		Vector2(0.335, 0.645),
		Vector2(0.355, 0.725),
	]
	for index in mini(costs.size(), positions.size()):
		var cost: Dictionary = costs[index]
		var position := _art_point(art_rect, positions[index])
		var paid := bool(cost.get("paid", false))
		var status := "✓ bezahlt" if paid else "• offen"
		var status_color := Color("#a9c493") if paid else Color("#d18a65")
		var box := Rect2(position - Vector2(78, 18), Vector2(156, 36))
		draw_style_box(_panel_style(Color("#15111bc2"), 18, Color("#b8734b59")), box)
		_draw_centered_text(position + Vector2(0, -2), str(cost.get("name", "Fixkosten")), 11, Color.WHITE)
		_draw_centered_text(position + Vector2(0, 12), status, 9, status_color)


func _draw_sky(center: Vector2, radius: float) -> void:
	for layer in range(6, 0, -1):
		draw_circle(
			center,
			radius * 1.28 + layer * 18.0,
			Color(0.10, 0.90, 0.82, 0.012 * float(7 - layer))
		)
	for index in range(22):
		var angle := float(index) * 2.399
		var distance := radius * (0.72 + float((index * 17) % 55) / 42.0)
		var star := center + Vector2(cos(angle), sin(angle) * 0.70) * distance
		var shimmer := 0.35 + 0.35 * sin(_time * 1.4 + float(index))
		draw_circle(star, 1.2 + float(index % 3) * 0.45, Color(0.29, 0.95, 0.88, shimmer))


func _draw_island(center: Vector2, radius: float) -> void:
	var island := PackedVector2Array()
	for index in range(64):
		var angle := TAU * float(index) / 64.0
		var roughness := 1.0 + sin(angle * 5.0) * 0.035 + cos(angle * 9.0) * 0.025
		island.append(
			center + Vector2(cos(angle) * radius * roughness, sin(angle) * radius * 0.64 * roughness)
		)
	var shadow := PackedVector2Array()
	for point in island:
		shadow.append(point + Vector2(0, 24))
	draw_colored_polygon(shadow, Color(0.01, 0.04, 0.05, 0.72))
	draw_colored_polygon(island, LAND)
	draw_polyline(island + PackedVector2Array([island[0]]), Color("#66805c"), 6.0, true)

	draw_circle(center + Vector2(0, 12), radius * 0.60, Color("#123e3c"))
	draw_circle(center + Vector2(0, 12), radius * 0.49, WATER)
	for ring in range(4):
		var wave_radius := radius * (0.22 + ring * 0.085) + sin(_time * 1.5 + ring) * 3.0
		draw_arc(
			center + Vector2(0, 17),
			wave_radius,
			0.12,
			PI - 0.12,
			44,
			Color(0.35, 1.0, 0.89, 0.14),
			2.0,
			true
		)


func _draw_waterfall(center: Vector2, radius: float) -> void:
	var top := center + Vector2(0, -radius * 0.96)
	var stream := PackedVector2Array([
		top + Vector2(-radius * 0.19, -radius * 0.16),
		top + Vector2(radius * 0.19, -radius * 0.16),
		center + Vector2(radius * 0.10, -radius * 0.18),
		center + Vector2(-radius * 0.10, -radius * 0.18),
	])
	draw_colored_polygon(stream, Color("#159b91"))
	for line in range(5):
		var x := lerpf(-0.13, 0.13, float(line) / 4.0) * radius
		var drift := sin(_time * 2.0 + line) * 2.5
		draw_line(
			top + Vector2(x + drift, -radius * 0.12),
			center + Vector2(x * 0.55, -radius * 0.20),
			Color(0.48, 1.0, 0.91, 0.55),
			2.0
		)
	draw_circle(top + Vector2(0, -radius * 0.15), radius * 0.23, Color("#315b46"))
	draw_circle(top + Vector2(0, -radius * 0.14), radius * 0.17, Color("#1d7566"))


func _draw_fixed_cost_home(center: Vector2, radius: float) -> void:
	var position := center + Vector2(-radius * 0.58, -radius * 0.28)
	var house := Rect2(position - Vector2(radius * 0.16, radius * 0.08), Vector2(radius * 0.32, radius * 0.24))
	draw_rect(house, Color("#513b31"), true)
	draw_colored_polygon(
		PackedVector2Array([
			position + Vector2(-radius * 0.21, -radius * 0.08),
			position + Vector2(0, -radius * 0.27),
			position + Vector2(radius * 0.21, -radius * 0.08),
		]),
		Color("#283837")
	)
	draw_rect(
		Rect2(position + Vector2(-radius * 0.045, radius * 0.055), Vector2(radius * 0.09, radius * 0.105)),
		Color("#251f1b"),
		true
	)
	for side in [-1.0, 1.0]:
		var window := position + Vector2(side * radius * 0.105, 0)
		draw_rect(
			Rect2(window - Vector2(radius * 0.035, radius * 0.035), Vector2(radius * 0.07, radius * 0.07)),
			Color(1.0, 0.65, 0.22, 0.88),
			true
		)
	draw_circle(position + Vector2(0, radius * 0.19), radius * 0.22, Color(0.02, 0.08, 0.08, 0.28))
	_draw_caption(
		position + Vector2(0, radius * 0.27),
		"FIXKOSTEN",
		_money(float(snapshot.fixed_costs_total)),
		Color("#ffae63")
	)


func _draw_savings_tree(center: Vector2, radius: float) -> void:
	var position := center + Vector2(radius * 0.57, -radius * 0.32)
	var target := maxf(float(snapshot.savings_goal), 1.0)
	var paid := float(snapshot.get("savings_payments", 0.0))
	var progress := clampf(paid / target, 0.0, 1.0)
	draw_line(position + Vector2(0, radius * 0.15), position + Vector2(0, -radius * 0.10), Color("#765238"), 12.0)
	for index in range(9):
		var angle := TAU * float(index) / 9.0
		var crown := position + Vector2(cos(angle) * radius * 0.13, sin(angle) * radius * 0.10 - radius * 0.13)
		var leaf_color := Color("#69a64d").lerp(Color("#b1db57"), progress * 0.75)
		draw_circle(crown, radius * 0.105, leaf_color.darkened(float(index % 3) * 0.07))
	if progress > 0.0:
		for index in range(5):
			var fruit := position + Vector2((index - 2) * radius * 0.055, -radius * (0.11 + float(index % 2) * 0.07))
			draw_circle(fruit, 3.0 + progress * 2.0, GOLD)
	_draw_caption(
		position + Vector2(0, radius * 0.28),
		"SPARZIEL",
		_money(float(snapshot.savings_goal)),
		Color("#8de56f")
	)


func _draw_fixed_cost_path(center: Vector2, radius: float) -> void:
	var total := float(snapshot.fixed_costs_total)
	var paid := float(snapshot.fixed_costs_paid)
	var ratio := 0.0 if total <= 0.0 else clampf(paid / total, 0.0, 1.0)
	for index in range(5):
		var t := float(index) / 4.0
		var position := center + Vector2(
			-radius * (0.74 - t * 0.44),
			radius * (0.07 + t * 0.18)
		)
		var stone_color := Color("#3f514c")
		if t <= ratio:
			stone_color = Color("#28745e")
		draw_ellipse(position, radius * 0.12, radius * 0.055, stone_color)
		var symbol := "✓" if t <= ratio else "•"
		_draw_centered_text(position + Vector2(0, 6), symbol, 16, Color("#9af3bd") if t <= ratio else Color("#d4ded8"))
	var status := "%d%% bezahlt" % roundi(ratio * 100.0)
	_draw_centered_text(center + Vector2(-radius * 0.52, radius * 0.39), status, 13, Color("#a8d9ce"))


func _draw_free_money(center: Vector2, radius: float) -> void:
	var position := center + Vector2(0, radius * 0.29)
	var box := Rect2(position - Vector2(radius * 0.47, 48), Vector2(radius * 0.94, 96))
	draw_style_box(_panel_style(Color(0.02, 0.45, 0.42, 0.91), 20, WATER_LIGHT), box)
	_draw_centered_text(position + Vector2(0, -12), "NACH ALLEN FIXKOSTEN FREI", 13, Color("#c8fff6"))
	_draw_centered_text(position + Vector2(0, 28), _money(float(snapshot.freely_available)), 31, Color.WHITE)


func _draw_income_source(center: Vector2, radius: float) -> void:
	var position := center + Vector2(0, -radius * 1.22)
	var box := Rect2(position - Vector2(116, 42), Vector2(232, 84))
	draw_style_box(_panel_style(Color(0.04, 0.34, 0.32, 0.96), 42, WATER_LIGHT), box)
	_draw_centered_text(position + Vector2(0, -8), "KONTOSTAND", 12, Color("#e4c99a"))
	_draw_centered_text(position + Vector2(0, 25), _money(float(snapshot.balance)), 25, Color.WHITE)


func _draw_caption(position: Vector2, title: String, value: String, accent: Color) -> void:
	var box := Rect2(position - Vector2(83, 30), Vector2(166, 60))
	draw_style_box(_panel_style(Color(0.03, 0.13, 0.14, 0.90), 14, accent), box)
	_draw_centered_text(position + Vector2(0, -5), title, 11, accent)
	_draw_centered_text(position + Vector2(0, 19), value, 17, Color.WHITE)


func _draw_centered_text(position: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		position + Vector2(-width * 0.5, 0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)


func _panel_style(color: Color, radius: int, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


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
