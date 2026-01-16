class_name BulbLightAdapter
extends Node2D

const LightServiceScript := preload("res://scripts/app/light/light_service.gd")

@export var row_index: int = 0
@export var visual_node: Node2D
@export var on_color: Color = Color(1.0, 1.0, 0.4, 1.0) # Yellowish
@export var off_color: Color = Color(0.3, 0.3, 0.3, 1.0) # Dark Gray

var _light_service: LightService
var _source_id: StringName

func setup(service: LightService, source_id: StringName) -> void:
	_light_service = service
	_source_id = source_id
	_update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _light_service:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_event := make_input_local(event) as InputEventMouseButton
			var local_pos := mouse_event.position
			# Simple radius check. Assume bulb is centered at (0,0).
			if local_pos.length() < 40.0:
				_toggle()
				get_viewport().set_input_as_handled()

func _toggle() -> void:
	_light_service.toggle_bulb(row_index, _source_id)
	_update_visuals()

func _update_visuals() -> void:
	var is_on := _light_service.is_bulb_on(row_index)
	if visual_node:
		visual_node.modulate = on_color if is_on else off_color
