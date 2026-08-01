extends Control


func _ready() -> void:
	var output_path := OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_PATH")
	if output_path.is_empty():
		push_error("Pfad fuer die visuelle Vorschau fehlt.")
		get_tree().quit(1)
		return

	var preview_width := int(OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_WIDTH"))
	var preview_height := int(OS.get_environment("BUDGETWELT_VISUAL_PREVIEW_HEIGHT"))
	if preview_width <= 0:
		preview_width = 390
	if preview_height <= 0:
		preview_height = 844
	get_window().size = Vector2i(preview_width, preview_height)
	get_window().content_scale_size = Vector2i(preview_width, preview_height)
	var app := preload("res://app/Main.tscn").instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	app.login_panel.visible = false
	app.startup_status_panel.visible = false
	app._show_page("fixed_costs")
	app._apply_responsive_layout()
	await get_tree().process_frame
	print(
		"VISUAL_LAYOUT:page=%s:summary_position=%s:summary_size=%s" % [
			str(app.fixed_costs_page.size),
			str(app.fixed_summary_row.position),
			str(app.fixed_summary_row.size),
		]
	)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.is_empty() or image.save_png(output_path) != OK:
		push_error("Mobile Vorschau konnte nicht gespeichert werden.")
		get_tree().quit(1)
		return
	print("VISUAL_PREVIEW_OK:%dx%d:%s" % [image.get_width(), image.get_height(), output_path])
	get_tree().quit(0)
