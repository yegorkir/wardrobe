@tool
class_name CurtainRig
extends Node2D

@export_group("Light Beam")
@export var beam_width: float = 363.0:
	set(value):
		beam_width = value
		_update_beam_visuals()

@export_range(0.0, 1.0) var intensity: float = 0.5:
	set(value):
		intensity = value
		_update_beam_visuals()

@export var editor_light_visible: bool = true:
	set(value):
		editor_light_visible = value
		_update_editor_visibility()

@export_group("Curtain Animation")
@export var travel_pixels: float = -1.0:
	set(value):
		travel_pixels = value
		_update_adapter_settings()

@export var speed_power: float = 1.6:
	set(value):
		speed_power = value
		_update_adapter_settings()

@export var slider_path: NodePath = NodePath(""):
	set(value):
		slider_path = value
		_update_adapter_settings()

@onready var _light_collision: CollisionShape2D = $CurtainZone/CollisionShape2D
@onready var _light_visual: ColorRect = $CurtainZone/CollisionShape2D/LightVisual
@onready var _adapter: CurtainLightAdapter = $CurtainsColumn/CurtainLightAdapter

func _ready() -> void:
	if _light_collision and _light_collision.shape:
		_light_collision.shape = _light_collision.shape.duplicate()
		
	if _light_visual and _light_visual.material:
		_light_visual.material = _light_visual.material.duplicate()

	_update_adapter_settings()

	if Engine.is_editor_hint():
		_update_beam_visuals()
		_update_editor_visibility()

func _update_adapter_settings() -> void:
	if not _adapter: return
	_adapter.travel_pixels = travel_pixels
	_adapter.speed_power = speed_power
	if not slider_path.is_empty():
		if slider_path.is_absolute():
			_adapter.slider_path = slider_path
		else:
			# Adapter is nested 2 levels deep (CurtainsColumn -> Adapter), so we need to step up 2 levels
			# before applying the path relative to the Rig root.
			_adapter.slider_path = NodePath("../../" + str(slider_path))
		
		# Trigger adapter update/re-setup if needed?
		# CurtainLightAdapter uses _process for editor updates, so it should pick up changes or we might need to nudge it.
		if Engine.is_editor_hint():
			_adapter._ensure_editor_bindings()

func _update_beam_visuals() -> void:
	if not is_inside_tree(): return
	
	if _light_collision and _light_collision.shape is RectangleShape2D:
		var rect_shape := _light_collision.shape as RectangleShape2D
		if rect_shape.size.x != beam_width:
			rect_shape.size.x = beam_width
		
		# Anchor to left side: X = Anchor + Width / 2
		# Anchor calculated from original scene: -44.5 - (363 / 2) = -226.0
		_light_collision.position.x = -226.0 + (beam_width * 0.5)
	
	if _light_visual:
		# Update visual size to match shape
		if _light_collision and _light_collision.shape is RectangleShape2D:
			var shape_size = (_light_collision.shape as RectangleShape2D).size
			_light_visual.size = shape_size
			_light_visual.position = -shape_size * 0.5
		
		# Update intensity
		var mat := _light_visual.material as ShaderMaterial
		if mat:
			var col := mat.get_shader_parameter("color") as Color
			col.a = intensity
			mat.set_shader_parameter("color", col)

func _update_editor_visibility() -> void:
	if not Engine.is_editor_hint(): return
	if _light_visual:
		_light_visual.visible = editor_light_visible
