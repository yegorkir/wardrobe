@tool
class_name LightZonesAdapter
extends Node2D

const LightServiceScript := preload("res://scripts/app/light/light_service.gd")
const CurtainLightAdapterScript := preload("res://scripts/wardrobe/lights/curtain_light_adapter.gd")

@export var curtain_zone_path: NodePath
@export var bulb_row0_zone_path: NodePath
@export var bulb_row1_zone_path: NodePath
@export var service_zone_path: NodePath
@export var service_row_index: int = -1
@export var curtain_adapter_path: NodePath
@export var debug_draw: bool = true
@export var debug_color_curtain: Color = Color(1, 1, 0, 0.2)
@export var debug_color_bulb: Color = Color(1, 0.5, 0, 0.2)
@export var debug_color_service: Color = Color(0.8, 0.8, 1.0, 0.2)

# Optional slider for editor preview
@export var preview_slider: Slider

var _light_service: LightService
var _curtain_zone: CollisionShape2D
var _bulb_row0_zone: CollisionShape2D
var _bulb_row1_zone: CollisionShape2D
var _service_zone: CollisionShape2D
var _curtain_adapter: CurtainLightAdapter

# Rects in global space.
# We cache base rects and compute active rects on query.
var _curtain_base_rect: Rect2
var _bulb_row0_rect: Rect2
var _bulb_row1_rect: Rect2
var _service_rect: Rect2

# Config
const CURTAIN_SOURCE_ID := StringName("curtain_main")
const BULB_SOURCE_ID_ROW0 := StringName("bulb_row0")
const BULB_SOURCE_ID_ROW1 := StringName("bulb_row1")
const SERVICE_SOURCE_ID := StringName("service_light")

func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_zones()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if preview_slider:
			_update_curtain_shape(preview_slider.value)
			queue_redraw()

func setup(service: LightService) -> void:
	_light_service = service
	_refresh_zones()
	
	if _light_service:
		if not _light_service.curtain_changed.is_connected(_on_curtain_changed):
			_light_service.curtain_changed.connect(_on_curtain_changed)
		if not _light_service.bulb_changed.is_connected(_on_bulb_changed):
			_light_service.bulb_changed.connect(_on_bulb_changed)
		
		# Initial update to sync shapes
		_on_curtain_changed(_light_service.get_curtain_open_ratio())
		_update_bulb_visuals()

func _on_curtain_changed(ratio: float) -> void:
	if debug_draw:
		queue_redraw()
	_update_curtain_shape(ratio)

func _update_curtain_shape(_ratio: float) -> void:
	if not _curtain_zone or not (_curtain_zone.shape is RectangleShape2D):
		return

	# Update LightVisual - Search in children of the zone
	var visual := _curtain_zone.find_child("LightVisual", true, false) as Control
	if visual:
		var active_rect := _get_curtain_active_rect()
		visual.size = active_rect.size
		visual.position = -active_rect.size * 0.5
		visual.visible = active_rect.has_area()

func _on_bulb_changed(_row: int, _is_on: bool) -> void:
	if debug_draw:
		queue_redraw()
	_update_bulb_visuals()

func _update_bulb_visuals() -> void:
	if not _light_service:
		return
		
	if _bulb_row0_zone:
		var v0 := _bulb_row0_zone.find_child("LightVisual", true, false) as Control
		if v0:
			v0.visible = _light_service.is_bulb_on(0)
			
	if _bulb_row1_zone:
		var v1 := _bulb_row1_zone.find_child("LightVisual", true, false) as Control
		if v1:
			v1.visible = _light_service.is_bulb_on(1)

func _draw() -> void:
	if not debug_draw:
		return

	# Debug drawing is disabled to prefer shader visuals.
	# Uncomment to debug zone rects.
	# var curtain_rect := _get_curtain_active_rect()
	# if curtain_rect.has_area():
	# 	var local_rect := Rect2(to_local(curtain_rect.position), curtain_rect.size)
	# 	draw_rect(local_rect, debug_color_curtain)
		
	# if (_light_service and _light_service.is_bulb_on(0)):
	# 	var local_r0 := Rect2(to_local(_bulb_row0_rect.position), _bulb_row0_rect.size)
	# 	draw_rect(local_r0, debug_color_bulb)
		
	# if (_light_service and _light_service.is_bulb_on(1)):
	# 	var local_r1 := Rect2(to_local(_bulb_row1_rect.position), _bulb_row1_rect.size)
	# 	draw_rect(local_r1, debug_color_bulb)

func _refresh_zones() -> void:
	_curtain_zone = _get_shape_node(curtain_zone_path)
	_bulb_row0_zone = _get_shape_node(bulb_row0_zone_path)
	_bulb_row1_zone = _get_shape_node(bulb_row1_zone_path)
	_service_zone = _get_shape_node(service_zone_path)
	if not curtain_adapter_path.is_empty():
		_curtain_adapter = get_node_or_null(curtain_adapter_path) as CurtainLightAdapter
	
	# Ensure the curtain shape is unique to this instance so we can modify it freely
	_curtain_base_rect = _get_global_rect(_curtain_zone)
	_bulb_row0_rect = _get_global_rect(_bulb_row0_zone)
	_bulb_row1_rect = _get_global_rect(_bulb_row1_zone)
	_service_rect = _get_global_rect(_service_zone)

func is_item_in_light(item: ItemNode) -> bool:
	if not is_instance_valid(item) or item.is_dragging():
		return false
		
	var point := item.global_position
	
	# Check Curtain
	var curtain_active_rect := _get_curtain_active_rect()
	if curtain_active_rect.has_area() and curtain_active_rect.has_point(point):
		return true
		
	# Check Service Zone (Always On)
	if _service_rect.has_area() and _service_rect.has_point(point):
		if service_row_index < 0:
			return true
		if _light_service and _light_service.is_bulb_on(service_row_index):
			return true
		
	# Check Bulbs
	if _light_service:
		if _light_service.is_bulb_on(0) and _bulb_row0_rect.has_point(point):
			return true
		if _light_service.is_bulb_on(1) and _bulb_row1_rect.has_point(point):
			return true
		
	return false

func which_sources_affect(item: ItemNode) -> Array[StringName]:
	var sources: Array[StringName] = []
	if not is_instance_valid(item) or item.is_dragging():
		return sources
		
	var point := item.global_position
	
	var curtain_active_rect := _get_curtain_active_rect()
	if curtain_active_rect.has_area() and curtain_active_rect.has_point(point):
		sources.append(CURTAIN_SOURCE_ID)
		
	if _service_rect.has_area() and _service_rect.has_point(point):
		if service_row_index < 0:
			sources.append(SERVICE_SOURCE_ID)
		elif _light_service and _light_service.is_bulb_on(service_row_index):
			sources.append(SERVICE_SOURCE_ID)
		
	if _light_service:
		if _light_service.is_bulb_on(0) and _bulb_row0_rect.has_point(point):
			sources.append(BULB_SOURCE_ID_ROW0)
		if _light_service.is_bulb_on(1) and _bulb_row1_rect.has_point(point):
			sources.append(BULB_SOURCE_ID_ROW1)
		
	return sources

func _get_curtain_active_rect() -> Rect2:
	if _curtain_adapter and _curtain_adapter.has_method("get_gap_rect_global"):
		var gap_rect := _curtain_adapter.get_gap_rect_global()
		if gap_rect.has_area():
			return gap_rect.intersection(_curtain_base_rect)
		return Rect2()
	var ratio := 0.0
	if _light_service:
		ratio = _light_service.get_curtain_open_ratio()
	elif Engine.is_editor_hint() and preview_slider:
		ratio = preview_slider.value
		
	if ratio <= 0.001:
		return Rect2()
		
	var h := _curtain_base_rect.size.y * ratio
	var center := _curtain_base_rect.get_center()
	var new_size := Vector2(_curtain_base_rect.size.x, h)
	var new_pos := center - new_size * 0.5
	return Rect2(new_pos, new_size)

func _get_shape_node(path: NodePath) -> CollisionShape2D:
	if path.is_empty():
		return null
	var area = get_node_or_null(path)
	if area and area is Area2D:
		for child in area.get_children():
			if child is CollisionShape2D:
				return child
	return null
	
func _get_global_rect(shape_node: CollisionShape2D) -> Rect2:
	if not shape_node or not shape_node.shape or not (shape_node.shape is RectangleShape2D):
		return Rect2()
	var rect_size = (shape_node.shape as RectangleShape2D).size
	var pos = shape_node.global_position - rect_size * 0.5
	return Rect2(pos, rect_size)
