extends "res://scripts/wardrobe/surface/wardrobe_surface_2d.gd"
class_name FloorZoneAdapter

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const SurfaceRegistry := preload("res://scripts/wardrobe/surface/surface_registry.gd")
const WardrobeSurface2DScript := preload("res://scripts/wardrobe/surface/wardrobe_surface_2d.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const FLOOR_GROUP := PhysicsLayers.GROUP_FLOORS
@export var scatter_step_px: int = 2
@export var scatter_bucket: int = 17
@export var scatter_range: int = 8
@export var edge_margin_px: float = 8.0

@onready var _drop_area: Area2D = $DropArea
@onready var _drop_shape: CollisionShape2D = $DropArea/CollisionShape2D
@onready var _surface_ref: Node2D = get_node_or_null("SurfaceRef") as Node2D
var _items_root: Node2D
var _drop_line: Node2D
var _surface_body: StaticBody2D
var _surface_shape: CollisionShape2D
var _surface_left: Node2D
var _surface_right: Node2D

var _items_by_id: Dictionary = {}
var _warned_missing_surface_ref := false
var _warned_missing_surface_shape := false

func _ready() -> void:
	add_to_group(FLOOR_GROUP)
	_resolve_children()
	_apply_physics_layers()
	if _items_root:
		_items_root.y_sort_enabled = true
	_register_surface()

func _exit_tree() -> void:
	_unregister_surface()

func contains_item(item: ItemNode) -> bool:
	if item == null:
		return false
	return _items_by_id.has(StringName(item.item_id))

func remove_item(item: ItemNode) -> void:
	if item == null:
		return
	_items_by_id.erase(StringName(item.item_id))
	item.clear_current_surface()

func register_item(item: ItemNode) -> void:
	if item == null:
		return
	_items_by_id[StringName(item.item_id)] = item
	item.set_current_surface(self)

func is_point_inside(global_point: Vector2) -> bool:
	var rect := _get_drop_rect_local()
	if rect.size == Vector2.ZERO:
		return false
	var local := to_local(global_point)
	return rect.has_point(local)

func drop_item(item: ItemNode, drop_global_pos: Vector2) -> Vector2:
	return drop_item_with_fall(item, drop_global_pos)

func drop_item_with_fall(item: ItemNode, drop_global_pos: Vector2) -> Vector2:
	if _items_root == null:
		push_warning("FloorZone ItemsRoot missing; cannot drop item.")
		return drop_global_pos
	var rect := _get_drop_rect_local()
	var target_global := drop_global_pos
	if rect.size != Vector2.ZERO:
		var local := to_local(drop_global_pos)
		var x_offset := _compute_scatter_offset(item)
		var target_local_x := local.x + x_offset
		var half_width := item.get_visual_half_width()
		var margin := maxf(edge_margin_px, half_width)
		var min_x := rect.position.x + margin
		var max_x := rect.position.x + rect.size.x - margin
		if min_x < max_x:
			target_local_x = clampf(target_local_x, min_x, max_x)
		var target_global_x := to_global(Vector2(target_local_x, 0.0)).x
		target_global = Vector2(target_global_x, drop_global_pos.y)
	_items_by_id[StringName(item.item_id)] = item
	item.set_current_surface(self)
	if item.get_parent():
		item.reparent(_items_root, true)
	else:
		_items_root.add_child(item)
	item.global_position = target_global
	item.global_rotation = 0.0
	item.global_scale = Vector2.ONE
	item.freeze = false
	item.sleeping = false
	if item.linear_velocity.y < 60.0:
		item.linear_velocity = Vector2(item.linear_velocity.x, 60.0)
	item.z_index = int(target_global.y)
	_log_debug("drop fall item=%s pos=%.1f,%.1f", [item.item_id, target_global.x, target_global.y])
	return target_global

func get_surface_bounds_global() -> Rect2:
	var rect := _resolve_surface_bounds_global()
	if rect.size != Vector2.ZERO:
		return rect
	return Rect2()

func _compute_scatter_offset(item: ItemNode) -> float:
	if item == null:
		return 0.0
	var item_id: String = String(item.item_id)
	var hashed: int = int(hash(item_id))
	var safe_hash: int = abs(hashed)
	var bucket: int = safe_hash % scatter_bucket
	var offset_units: int = bucket - scatter_range
	return float(offset_units * scatter_step_px)

func _get_drop_rect_local() -> Rect2:
	if _drop_shape == null:
		return Rect2()
	var shape := _drop_shape.shape
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		return Rect2(_drop_shape.position - rect_shape.size * 0.5, rect_shape.size)
	return Rect2()

func _resolve_children() -> void:
	_items_root = get_node_or_null("ItemsRoot") as Node2D
	_drop_line = get_node_or_null("DropLine") as Node2D
	_surface_body = get_node_or_null("SurfaceBody") as StaticBody2D
	_surface_left = get_node_or_null("SurfaceLeft") as Node2D
	_surface_right = get_node_or_null("SurfaceRight") as Node2D
	if _surface_body:
		_surface_shape = _surface_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _items_root == null and _drop_area:
		_items_root = _drop_area.find_child("ItemsRoot", true, false) as Node2D
	if _drop_line == null and _drop_area:
		_drop_line = _drop_area.find_child("DropLine", true, false) as Node2D

func _apply_physics_layers() -> void:
	if _surface_body:
		_surface_body.collision_layer = PhysicsLayers.LAYER_FLOOR_BIT
		_surface_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT | PhysicsLayers.LAYER_TRANSFER_FALL_BIT
	if _drop_area:
		_drop_area.collision_layer = PhysicsLayers.LAYER_PICK_AREA_BIT
		_drop_area.collision_mask = 0

func _register_surface() -> void:
	var registry = _resolve_surface_registry()
	if registry == null:
		return
	registry.register_floor(self)

func _unregister_surface() -> void:
	var registry = _resolve_surface_registry()
	if registry == null:
		return
	registry.unregister_floor(self)

func _resolve_surface_registry() -> SurfaceRegistry:
	return SurfaceRegistry.get_autoload()

func get_surface_y_global() -> float:
	if _surface_ref:
		return _surface_ref.global_position.y
	if not _warned_missing_surface_ref:
		_warned_missing_surface_ref = true
		push_warning("FloorZone missing SurfaceRef; falling back to surface shape.")
	var fallback_y := _resolve_surface_top_global()
	return fallback_y

func get_surface_collision_y_global() -> float:
	return _resolve_surface_top_global()

func get_surface_kind() -> StringName:
	return EventSchema.SURFACE_KIND_FLOOR

func _resolve_surface_top_global() -> float:
	if _surface_shape == null or _surface_shape.shape == null:
		if not _warned_missing_surface_shape:
			_warned_missing_surface_shape = true
			push_warning("FloorZone missing SurfaceBody/CollisionShape2D; using node Y.")
		return global_position.y
	if _surface_shape.shape is RectangleShape2D:
		var rect := _surface_shape.shape as RectangleShape2D
		var local_top := Vector2(0.0, -rect.size.y * 0.5)
		return (_surface_shape.global_transform * local_top).y
	if not _warned_missing_surface_shape:
		_warned_missing_surface_shape = true
		push_warning("FloorZone unsupported surface shape; using node Y.")
	return global_position.y

func _resolve_surface_rect_global() -> Rect2:
	if _surface_shape == null or _surface_shape.shape == null:
		return Rect2()
	if _surface_shape.shape is RectangleShape2D:
		var rect := _surface_shape.shape as RectangleShape2D
		var center := _surface_shape.global_position
		return Rect2(
			Vector2(center.x - rect.size.x * 0.5, center.y - rect.size.y * 0.5),
			rect.size
		)
	return Rect2()

func _resolve_surface_bounds_global() -> Rect2:
	if _surface_left and _surface_right:
		var left_x := _surface_left.global_position.x
		var right_x := _surface_right.global_position.x
		if left_x < right_x:
			var width := right_x - left_x
			var center_y := get_surface_y_global()
			return Rect2(Vector2(left_x, center_y - 0.5), Vector2(width, 1.0))
	var rect := _resolve_surface_rect_global()
	if rect.size != Vector2.ZERO:
		return rect
	if _surface_ref:
		return Rect2(Vector2(_surface_ref.global_position.x, get_surface_y_global() - 0.5), Vector2(1.0, 1.0))
	return Rect2()

func _log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("FloorZone %s" % format)
		return
	DebugLog.logf("FloorZone " + format, args)
