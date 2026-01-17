@tool
extends Node2D

@export var external_visual_path: NodePath:
	set(value):
		external_visual_path = value
		_sync_external_visual()

@onready var _bulb_on: CanvasItem = $BulbOn
@onready var _bulb_off: CanvasItem = $BulbOff

var _external_visual_node: CanvasItem
var is_on := false

func _ready() -> void:
	_sync_external_visual()

func set_is_on(value: bool) -> void:
	if is_on == value:
		return
	is_on = value
	_update_bulb_sprites()
	_sync_external_visual()

func _update_bulb_sprites() -> void:
	if _bulb_on:
		_bulb_on.visible = is_on
	if _bulb_off:
		_bulb_off.visible = not is_on

func _sync_external_visual() -> void:
	if not is_inside_tree():
		return
	_external_visual_node = null
	if not external_visual_path.is_empty():
		var node := get_node_or_null(external_visual_path)
		if node is CanvasItem:
			_external_visual_node = node
	_update_bulb_sprites()
	if _external_visual_node and is_instance_valid(_external_visual_node):
		if _external_visual_node.has_method("set_is_on"):
			_external_visual_node.call("set_is_on", is_on)
