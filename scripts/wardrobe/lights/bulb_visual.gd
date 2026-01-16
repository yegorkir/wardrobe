@tool

extends Node2D

var _external_visual_node: CanvasItem

@export var external_visual_path: NodePath:
	set(value):
		external_visual_path = value
		_update_visual_source()

var is_on := false

func _update_visual_source() -> void:
	if not is_inside_tree(): return
	
	_external_visual_node = null
	if not external_visual_path.is_empty():
		var node = get_node_or_null(external_visual_path)
		if node is CanvasItem:
			_external_visual_node = node
			

	if _external_visual_node and is_instance_valid(_external_visual_node):
		if _external_visual_node.has_method("set_is_on"):
			_external_visual_node.call("set_is_on", is_on)
