class_name CursorHand
extends Node2D

@export var small_scale: Vector2 = Vector2(0.7, 0.7)
@export var big_scale: Vector2 = Vector2.ONE
@export var preview_duration: float = 0.1
@export var follow_offset: Vector2 = Vector2.ZERO

var _hand_item: ItemNode
var _scale_tween: Tween

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position() + follow_offset

func hold_item(node: ItemNode) -> void:
	if node == null:
		return
	_hand_item = node
	if node.get_parent():
		node.reparent(self)
	else:
		add_child(node)
	node.position = Vector2.ZERO
	node.rotation = 0.0
	node.scale = big_scale
	node.z_index = 0

func take_item_from_hand() -> ItemNode:
	var item := _hand_item
	_hand_item = null
	return item

func get_active_hand_item() -> ItemNode:
	return _hand_item

func set_preview_small(enabled: bool) -> void:
	if _hand_item == null:
		return
	var target := small_scale if enabled else big_scale
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(_hand_item, "scale", target, preview_duration)
	_scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
