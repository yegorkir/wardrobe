@tool
class_name CurtainLightAdapter
extends Node

const LightService := preload("res://scripts/app/light/light_service.gd")

@export var slider_path: NodePath
@export var curtain_top_root_path: NodePath
@export var curtain_bottom_root_path: NodePath
@export var curtain_zone_shape_path: NodePath
@export var segment_prefix: String = "Segment"
@export var travel_pixels: float = -1.0
@export var speed_power: float = 1.6

var slider: Slider
var _light_service: LightService
var _source_id: StringName
var _curtain_top_root: Node2D
var _curtain_bottom_root: Node2D
var _curtain_zone_shape: CollisionShape2D

var _top_segments: Array[Control] = []
var _bottom_segments: Array[Control] = []
var _top_base_positions: Array[Vector2] = []
var _bottom_base_positions: Array[Vector2] = []
var _segment_height: float = 0.0
var _top_travel: float = 0.0
var _bottom_travel: float = 0.0
var _top_midline_local: float = 0.0
var _bottom_midline_local: float = 0.0

func get_gap_rect_global() -> Rect2:
	if _curtain_zone_shape == null:
		return Rect2()
	var zone_rect := _get_global_rect(_curtain_zone_shape)
	if zone_rect.size == Vector2.ZERO:
		return Rect2()
	var top_bottom := _get_top_bottom_global()
	var bottom_top := _get_bottom_top_global()
	if top_bottom >= bottom_top:
		return Rect2()
	return Rect2(Vector2(zone_rect.position.x, top_bottom), Vector2(zone_rect.size.x, bottom_top - top_bottom))

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_ensure_editor_bindings()
		if slider:
			_update_visuals(slider.value)

func setup(service: LightService, source_id: StringName) -> void:
	_light_service = service
	_source_id = source_id
	
	if not slider_path.is_empty():
		slider = get_node_or_null(slider_path) as Slider
	if not curtain_top_root_path.is_empty():
		_curtain_top_root = get_node_or_null(curtain_top_root_path) as Node2D
	if not curtain_bottom_root_path.is_empty():
		_curtain_bottom_root = get_node_or_null(curtain_bottom_root_path) as Node2D
	if not curtain_zone_shape_path.is_empty():
		_curtain_zone_shape = get_node_or_null(curtain_zone_shape_path) as CollisionShape2D
	_collect_segments()
	_refresh_layout()
	
	if slider:
		if not slider.value_changed.is_connected(_on_slider_value_changed):
			slider.value_changed.connect(_on_slider_value_changed)
		slider.value = _light_service.get_curtain_open_ratio()
		_update_visuals(_light_service.get_curtain_open_ratio())
		print("[CurtainLightAdapter] Slider connected successfully in setup.")
	else:
		push_error("[CurtainLightAdapter] Slider node is missing at path: " + str(slider_path))

func _on_slider_value_changed(value: float) -> void:
	print("[CurtainLightAdapter] Slider value changed to: ", value)
	if _light_service:
		_light_service.set_curtain_open_ratio(value, _source_id)
		_update_visuals(value)

func _update_visuals(ratio: float) -> void:
	_refresh_layout()
	_apply_motion(_top_segments, _top_base_positions, ratio, -1.0, _top_travel, _top_midline_local, true)
	_apply_motion(_bottom_segments, _bottom_base_positions, ratio, 1.0, _bottom_travel, _bottom_midline_local, false)

func _ensure_editor_bindings() -> void:
	var refreshed := false
	if slider == null and not slider_path.is_empty():
		slider = get_node_or_null(slider_path) as Slider
	if _curtain_top_root == null and not curtain_top_root_path.is_empty():
		_curtain_top_root = get_node_or_null(curtain_top_root_path) as Node2D
		refreshed = true
	if _curtain_bottom_root == null and not curtain_bottom_root_path.is_empty():
		_curtain_bottom_root = get_node_or_null(curtain_bottom_root_path) as Node2D
		refreshed = true
	if _curtain_zone_shape == null and not curtain_zone_shape_path.is_empty():
		_curtain_zone_shape = get_node_or_null(curtain_zone_shape_path) as CollisionShape2D
		refreshed = true
	if refreshed:
		_collect_segments()
		_refresh_layout()

func _collect_segments() -> void:
	_top_segments = _find_segments(_curtain_top_root)
	_bottom_segments = _find_segments(_curtain_bottom_root)
	_segment_height = 0.0
	if not _top_segments.is_empty():
		_segment_height = _top_segments[0].size.y
	elif not _bottom_segments.is_empty():
		_segment_height = _bottom_segments[0].size.y

func _find_segments(root: Node) -> Array[Control]:
	var result: Array[Control] = []
	if root == null:
		return result
	var segments := root.find_children("%s*" % segment_prefix, "Control", true, false)
	for segment in segments:
		var control := segment as Control
		if control:
			result.append(control)
	result.sort_custom(func(a: Control, b: Control) -> bool:
		return _segment_index(a.name) < _segment_index(b.name)
	)
	return result

func _segment_index(segment_name: String) -> int:
	var digits := ""
	for i in range(segment_name.length() - 1, -1, -1):
		var ch := segment_name[i]
		if ch >= "0" and ch <= "9":
			digits = String(ch) + digits
		else:
			break
	if digits.is_empty():
		return 0
	return int(digits)

func _refresh_layout() -> void:
	if _curtain_zone_shape == null:
		return
	var zone_rect := _get_global_rect(_curtain_zone_shape)
	if zone_rect.size == Vector2.ZERO:
		return
	var mid_y := zone_rect.position.y + zone_rect.size.y * 0.5
	if not _top_segments.is_empty():
		_top_base_positions = _layout_segments(_curtain_top_root, _top_segments, zone_rect.position.y, true)
		_top_travel = _compute_travel(_curtain_top_root, _top_base_positions, mid_y, true)
		_top_midline_local = _curtain_top_root.to_local(Vector2(_curtain_top_root.global_position.x, mid_y)).y
	if not _bottom_segments.is_empty():
		var bottom_y := zone_rect.position.y + zone_rect.size.y
		_bottom_base_positions = _layout_segments(_curtain_bottom_root, _bottom_segments, bottom_y, false)
		_bottom_travel = _compute_travel(_curtain_bottom_root, _bottom_base_positions, mid_y, false)
		_bottom_midline_local = _curtain_bottom_root.to_local(Vector2(_curtain_bottom_root.global_position.x, mid_y)).y

func _layout_segments(root: Node2D, segments: Array[Control], anchor_y_global: float, is_top: bool) -> Array[Vector2]:
	var base_positions: Array[Vector2] = []
	if root == null or segments.is_empty():
		return base_positions
	var height := _segment_height
	if height <= 0.0:
		height = segments[0].size.y
	var anchor_local := root.to_local(Vector2(root.global_position.x, anchor_y_global)).y
	if not is_top:
		anchor_local -= height
	for i in range(segments.size()):
		var segment := segments[i]
		var base_pos := segment.position
		var offset := height * float(i)
		base_pos.y = anchor_local + (offset if is_top else -offset)
		segment.position = base_pos
		base_positions.append(base_pos)
	return base_positions

func _apply_motion(
		segments: Array[Control],
		base_positions: Array[Vector2],
		ratio: float,
		direction: float,
		travel_override: float,
		midline_local: float,
		is_top: bool
	) -> void:
	if segments.is_empty() or base_positions.is_empty():
		return
	var travel := travel_pixels
	if travel <= 0.0:
		travel = travel_override
	if travel <= 0.0:
		travel = _segment_height * float(segments.size() - 1)
	if segments.size() == 1:
		return
	for i in range(1, segments.size()):
		var t := float(i) / float(segments.size() - 1)
		var weight := pow(t, speed_power)
		var shift := travel * ratio * weight * direction
		var base_pos := base_positions[i]
		var new_y := base_pos.y + shift
		if is_top:
			var new_bottom := new_y + _segment_height
			if new_bottom > midline_local:
				new_y = midline_local - _segment_height
		else:
			if new_y < midline_local:
				new_y = midline_local
		segments[i].position = Vector2(base_pos.x, new_y)

func _compute_travel(root: Node2D, base_positions: Array[Vector2], mid_y_global: float, is_top: bool) -> float:
	if root == null or base_positions.is_empty():
		return 0.0
	var mid_local := root.to_local(Vector2(root.global_position.x, mid_y_global)).y
	var last_index := base_positions.size() - 1
	var last_pos := base_positions[last_index]
	if is_top:
		var last_bottom := last_pos.y + _segment_height
		return maxf(0.0, last_bottom - mid_local)
	var last_top := last_pos.y
	return maxf(0.0, mid_local - last_top)

func _get_global_rect(shape_node: CollisionShape2D) -> Rect2:
	if shape_node == null or shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
		return Rect2()
	var rect_size := (shape_node.shape as RectangleShape2D).size
	var pos := shape_node.global_position - rect_size * 0.5
	return Rect2(pos, rect_size)

func _get_top_bottom_global() -> float:
	if _top_segments.is_empty():
		return 0.0
	var max_bottom := -INF
	for segment in _top_segments:
		var rect := segment.get_global_rect()
		max_bottom = maxf(max_bottom, rect.position.y + rect.size.y)
	return max_bottom

func _get_bottom_top_global() -> float:
	if _bottom_segments.is_empty():
		return 0.0
	var min_top := INF
	for segment in _bottom_segments:
		var rect := segment.get_global_rect()
		min_top = minf(min_top, rect.position.y)
	return min_top
