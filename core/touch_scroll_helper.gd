class_name TouchScrollHelper
extends RefCounted

const TOUCH_DEADZONE := 4


static func configure(root: Node) -> void:
	_configure_node(root, false)


static func configure_added_descendant(node: Node) -> void:
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			_configure_node(node, true)
			return
		ancestor = ancestor.get_parent()


static func _configure_node(node: Node, inside_scroll: bool) -> void:
	var is_scroll := node is ScrollContainer
	if is_scroll:
		var scroll := node as ScrollContainer
		scroll.scroll_deadzone = TOUCH_DEADZONE
		scroll.mouse_force_pass_scroll_events = true
	elif inside_scroll and node is Control:
		var control := node as Control
		if control.mouse_filter == Control.MOUSE_FILTER_STOP:
			control.mouse_filter = Control.MOUSE_FILTER_PASS

	var descendants_are_inside_scroll := inside_scroll or is_scroll
	for child in node.get_children():
		_configure_node(child, descendants_are_inside_scroll)