@tool
class_name LightSwitch
extends Node2D

@export var rotation_on_degrees: float = 90.0
@export var rotation_off_degrees: float = 0.0
@export var animation_duration: float = 0.1

@onready var _handle: Node2D = $HandleSprite

var _is_on: bool = false
var _tween: Tween

func _ready() -> void:
	# Ensure initial state is applied immediately without animation if needed
	if _handle:
		_handle.rotation_degrees = rotation_on_degrees if _is_on else rotation_off_degrees

func set_is_on(value: bool) -> void:
	if _is_on == value:
		return
	_is_on = value
	_animate()

func _animate() -> void:
	if not is_inside_tree() or not _handle:
		return
	
	if _tween:
		_tween.kill()
	
	var target_rot = rotation_on_degrees if _is_on else rotation_off_degrees
	
	_tween = create_tween()
	_tween.tween_property(_handle, "rotation_degrees", target_rot, animation_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
