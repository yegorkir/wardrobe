@tool
class_name LightSwitch
extends Node2D

const LightServiceScript := preload("res://scripts/app/light/light_service.gd")

@export var row_index: int = 0
@export var source_id: StringName = &"bulb_row0"
@export var rotation_on_degrees: float = 90.0
@export var rotation_off_degrees: float = 0.0
@export var animation_duration: float = 0.1

@onready var _handle: Node2D = $HandleSprite

var _is_on: bool = false
var _tween: Tween
var _light_service: LightService

func _ready() -> void:
	# Ensure initial state is applied immediately without animation if needed
	if _handle:
		_handle.rotation_degrees = rotation_on_degrees if _is_on else rotation_off_degrees

func setup(service: LightService) -> void:
	_light_service = service
	if _light_service:
		if not _light_service.bulb_changed.is_connected(_on_bulb_changed):
			_light_service.bulb_changed.connect(_on_bulb_changed)
		set_is_on(_light_service.is_bulb_on(row_index))

func set_is_on(value: bool) -> void:
	if _is_on == value:
		return
	_is_on = value
	_animate()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not visible or not _light_service:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_event := make_input_local(event) as InputEventMouseButton
			var local_pos := mouse_event.position
			var hit_radius := 40.0
			var hit_pos := Vector2.ZERO
			if _handle:
				hit_pos = _handle.position
			if local_pos.distance_to(hit_pos) < hit_radius:
				_light_service.toggle_bulb(row_index, source_id)
				get_viewport().set_input_as_handled()

func _animate() -> void:
	if not is_inside_tree() or not _handle:
		return
	
	if _tween:
		_tween.kill()
	
	var target_rot = rotation_on_degrees if _is_on else rotation_off_degrees
	
	_tween = create_tween()
	_tween.tween_property(_handle, "rotation_degrees", target_rot, animation_duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_bulb_changed(changed_row: int, is_on: bool) -> void:
	if changed_row != row_index:
		return
	set_is_on(is_on)
