@tool
class_name BulbLightRig
extends Node2D

const LightService := preload("res://scripts/app/light/light_service.gd")

@export var row_index: int = 0
@export var source_id: StringName = &"bulb_row0"
@export var show_zone_in_editor: bool = false:
	set(value):
		show_zone_in_editor = value
		_update_editor_visibility()

@export_group("Light Zone Settings")
@export var zone_width: float = 358.0:
	set(value):
		zone_width = value
		_update_zone_geometry()

@export var zone_height: float = 498.0:
	set(value):
		zone_height = value
		_update_zone_geometry()

@export_range(0.0, 1.0) var light_intensity: float = 0.35:
	set(value):
		light_intensity = value
		_update_visual_params()

@export var bulb_offset: Vector2 = Vector2.ZERO:
	set(value):
		bulb_offset = value
		_update_visual_layout()

@export_group("Visuals")
@export var on_color: Color = Color(1.0, 1.0, 0.4, 1.0)
@export var off_color: Color = Color(0.3, 0.3, 0.3, 1.0)

@onready var _visual_node: CanvasItem = $Visual
@onready var _light_zone: Area2D = $LightZone
@onready var _light_collision: CollisionShape2D = $LightZone/CollisionShape2D
@onready var _light_visual: ColorRect = $LightZone/CollisionShape2D/LightVisual

var _light_service: LightService

func _ready() -> void:
	if _light_collision and _light_collision.shape:
		_light_collision.shape = _light_collision.shape.duplicate()
	
	if _visual_node and _visual_node.material:
		_visual_node.material = _visual_node.material.duplicate()
		
	if _light_visual and _light_visual.material:
		_light_visual.material = _light_visual.material.duplicate()

	if Engine.is_editor_hint():
		_update_editor_visibility()
		_update_zone_geometry()
		_update_visual_params()
		_update_visual_layout()
	else:
		# In game, light zone visual is controlled by LightZonesAdapter/LightService logic
		# But we ensure it starts hidden/shown correctly if needed?
		# Actually LightZonesAdapter manages the visibility of the "LightVisual" rect based on state.
		# But the CollisionShape/Zone debug visibility is handled by Godot.
		pass

func _update_zone_geometry() -> void:
	if not is_inside_tree(): return
	if _light_collision and _light_collision.shape is RectangleShape2D:
		var rect := _light_collision.shape as RectangleShape2D
		rect.size = Vector2(zone_width, zone_height)
		
		if _light_visual:
			_light_visual.size = rect.size
			_light_visual.position = -rect.size * 0.5

func _update_visual_params() -> void:
	if not is_inside_tree(): return
	if _light_visual:
		var mat := _light_visual.material as ShaderMaterial
		if mat:
			var col := mat.get_shader_parameter("color") as Color
			col.a = light_intensity
			mat.set_shader_parameter("color", col)

func _update_visual_layout() -> void:
	if not is_inside_tree(): return
	if _visual_node:
		_visual_node.position = bulb_offset

func setup(service: LightService) -> void:
	_light_service = service
	_update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not visible or not _light_service:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_event := make_input_local(event) as InputEventMouseButton
			var local_pos := mouse_event.position
			# Check against visual bulb radius (approx 40px)
			if local_pos.length() < 40.0:
				_toggle()
				get_viewport().set_input_as_handled()

func _toggle() -> void:
	if _light_service:
		_light_service.toggle_bulb(row_index, source_id)
		_update_visuals()

func _update_visuals() -> void:
	if not _light_service:
		return
	var is_on := _light_service.is_bulb_on(row_index)
	if _visual_node:
		_visual_node.modulate = on_color if is_on else off_color

func _update_editor_visibility() -> void:
	if not Engine.is_editor_hint():
		return
	if _light_visual:
		_light_visual.visible = show_zone_in_editor
