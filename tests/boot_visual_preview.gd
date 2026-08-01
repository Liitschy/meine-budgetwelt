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
		preview_width = 1440
	if preview_height <= 0:
		preview_height = 900
	get_window().size = Vector2i(preview_width, preview_height)
	get_window().content_scale_size = Vector2i(preview_width, preview_height)
	var boot := preload("res://app/Boot.tscn").instantiate()
	add_child(boot)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	print("BOOT_PANEL_QA:root=%s:size=%s:min=%s:position=%s:anchors=%s" % [
		str(boot.size),
		str(boot.glass_panel.size),
		str(boot.glass_panel.get_combined_minimum_size()),
		str(boot.glass_panel.position),
		str(Vector4(boot.glass_panel.anchor_left, boot.glass_panel.anchor_top, boot.glass_panel.anchor_right, boot.glass_panel.anchor_bottom)),
	])
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	if screenshot.is_empty() or screenshot.save_png(output_path) != OK:
		push_error("Startbildschirm-Vorschau konnte nicht gespeichert werden.")
		get_tree().quit(1)
		return
	print("BOOT_VISUAL_PREVIEW_OK:%dx%d:%s" % [screenshot.get_width(), screenshot.get_height(), output_path])
	get_tree().quit(0)
