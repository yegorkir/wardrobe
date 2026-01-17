@tool
class_name BulbLightRig
extends Node2D

const LightServiceScript := preload("res://scripts/app/light/light_service.gd")

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

@export var external_visual_path: NodePath:
	set(value):
		external_visual_path = value
		_update_visual_source()

@export var extra_visual_path: NodePath:
	set(value):
		extra_visual_path = value
		_update_visual_source()

@export var control_light_visual: bool = false

@export_group("Visuals")
@export var on_color: Color = Color(1.0, 1.0, 0.4, 1.0)
@export var off_color: Color = Color(0.3, 0.3, 0.3, 1.0)

@onready var _visual_node: CanvasItem = $Visual
@onready var _light_collision: CollisionShape2D = $LightZone/CollisionShape2D
@onready var _light_visual: ColorRect = $LightZone/CollisionShape2D/LightVisual

var _light_service: LightService
var _external_visual_node: CanvasItem
var _extra_visual_node: CanvasItem

func _ready() -> void:
	if _light_collision and _light_collision.shape:
		_light_collision.shape = _light_collision.shape.duplicate()
	
	if _visual_node and _visual_node.material:
		_visual_node.material = _visual_node.material.duplicate()
		
	if _light_visual and _light_visual.material:
		_light_visual.material = _light_visual.material.duplicate()

	_update_visual_source()
	_update_zone_geometry()
	_update_visual_params()
	_update_visual_layout()
	if Engine.is_editor_hint():
		_update_editor_visibility()

func _update_visual_source() -> void:
	if not is_inside_tree(): return
	
	_external_visual_node = null
	if not external_visual_path.is_empty():
		var node = get_node_or_null(external_visual_path)
		if node is CanvasItem:
			_external_visual_node = node

	_extra_visual_node = null
	if not extra_visual_path.is_empty():
		var extra_node = get_node_or_null(extra_visual_path)
		if extra_node is CanvasItem:
			_extra_visual_node = extra_node
	
	if _visual_node:
		_visual_node.visible = (_external_visual_node == null and _extra_visual_node == null)
	
	_update_visuals()

func _update_zone_geometry() -> void:
	if not is_inside_tree(): return
	if _light_collision and _light_collision.shape is RectangleShape2D:
		var rect := _light_collision.shape as RectangleShape2D
		rect.size = Vector2(zone_width, zone_height)
		_light_collision.position = rect.size * 0.5
		
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
	if _light_service:
		if not _light_service.bulb_changed.is_connected(_on_bulb_changed):
			_light_service.bulb_changed.connect(_on_bulb_changed)
	_update_visuals()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not visible or not _light_service:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_event := make_input_local(event) as InputEventMouseButton
			var local_pos := mouse_event.position
			
			var hit_radius := 40.0
			var handled := false
			if _external_visual_node and is_instance_valid(_external_visual_node) and _external_visual_node.visible:
				var ext_local := to_local(_external_visual_node.global_position)
				if local_pos.distance_to(ext_local) < hit_radius:
					handled = true
			if not handled and _extra_visual_node and is_instance_valid(_extra_visual_node) and _extra_visual_node.visible:
				var extra_local := to_local(_extra_visual_node.global_position)
				if local_pos.distance_to(extra_local) < hit_radius:
					handled = true
			if handled:
				_toggle()
				get_viewport().set_input_as_handled()
			else:
				var has_external := (_external_visual_node and is_instance_valid(_external_visual_node) and _external_visual_node.visible)
				var has_extra := (_extra_visual_node and is_instance_valid(_extra_visual_node) and _extra_visual_node.visible)
				if not has_external and not has_extra and local_pos.distance_to(bulb_offset) < hit_radius:
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
	var color := on_color if is_on else off_color
	
	if _external_visual_node and is_instance_valid(_external_visual_node):
		if _external_visual_node.has_method("set_is_on"):
			_external_visual_node.call("set_is_on", is_on)
	if _extra_visual_node and is_instance_valid(_extra_visual_node):
		if _extra_visual_node.has_method("set_is_on"):
			_extra_visual_node.call("set_is_on", is_on)
	
	if _visual_node:
		_visual_node.modulate = color
	if control_light_visual and _light_visual:
		_light_visual.visible = is_on

func _on_bulb_changed(changed_row: int, _is_on: bool) -> void:
	if changed_row != row_index:
		return
	_update_visuals()

func _update_editor_visibility() -> void:
	if not Engine.is_editor_hint():
		return
	if _light_visual:
		_light_visual.visible = show_zone_in_editor
