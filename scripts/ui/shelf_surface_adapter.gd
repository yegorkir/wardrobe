@tool
extends "res://scripts/wardrobe/surface/wardrobe_surface_2d.gd"
class_name ShelfSurfaceAdapter

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const SurfaceRegistry := preload("res://scripts/wardrobe/surface/surface_registry.gd")
const WardrobeSurface2DScript := preload("res://scripts/wardrobe/surface/wardrobe_surface_2d.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const SHELF_GROUP := PhysicsLayers.GROUP_SHELVES

@export var shelf_id: StringName = &"Shelf_1"
@export var shelf_length_px: float = 240.0:
	set(value):
		_shelf_length_px = value
		_sync_from_editor()
	get:
		return _shelf_length_px
@export var drop_area_height_px: float = 64.0:
	set(value):
		_drop_area_height_px = value
		_sync_from_editor()
	get:
		return _drop_area_height_px
@export var auto_from_cabinet: bool = true
@export var visual_bar_height_px: float = 4.0
@export var drop_y_offset_px: float = 0.0
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value

@onready var _drop_area: Area2D = $DropArea
@onready var _drop_shape: CollisionShape2D = $DropArea/CollisionShape2D
@onready var _surface_ref: Node2D = get_node_or_null("SurfaceRef") as Node2D
var _items_root: Node2D
var _drop_line: Node2D
var _visual_bar: ColorRect
var _surface_body: StaticBody2D
var _surface_shape: CollisionShape2D
var _surface_left: Node2D
var _surface_right: Node2D

var _items_by_id: Dictionary = {}
var _warned_missing_surface_ref := false
var _warned_missing_surface_shape := false
var _syncing_from_editor := false
var _shelf_length_px: float = 240.0
var _drop_area_height_px: float = 64.0

func _ready() -> void:
	if not enabled:
		visible = false
		_disable_completely()
		return
	add_to_group(SHELF_GROUP)
	_resolve_children()
	_apply_physics_layers()
	_pull_drop_area_height()
	_sync_from_editor()
	_debug_validate_alignment()
	if _items_root:
		_items_root.y_sort_enabled = true
	_register_surface()

func _disable_completely() -> void:
	_resolve_children()
	if _drop_area:
		_drop_area.monitorable = false
		_drop_area.monitoring = false
	if _surface_body:
		_surface_body.process_mode = Node.PROCESS_MODE_DISABLED
	# We intentionally do not register or add to group

func _exit_tree() -> void:
	_unregister_surface()

func contains_item(item: ItemNode) -> bool:
	if not enabled:
		return false
	if item == null:
		return false
	return _items_by_id.has(StringName(item.item_id))

func register_item(item: ItemNode) -> void:
	if not enabled:
		return
	if item == null:
		return
	_items_by_id[StringName(item.item_id)] = item
	item.set_current_surface(self)

func remove_item(item: ItemNode) -> void:
	if item == null:
		return
	_items_by_id.erase(StringName(item.item_id))
	item.clear_current_surface()

func is_point_inside(global_point: Vector2) -> bool:
	if not enabled:
		return false
	var rect := _get_drop_rect_local()
	if rect.size == Vector2.ZERO:
		return false
	var local := to_local(global_point)
	return rect.has_point(local)

func get_drop_rect_global() -> Rect2:
	var rect := _get_drop_rect_local()
	if rect.size == Vector2.ZERO:
		return Rect2()
	var top_left := to_global(rect.position)
	var bottom_right := to_global(rect.position + rect.size)
	var min_x := minf(top_left.x, bottom_right.x)
	var min_y := minf(top_left.y, bottom_right.y)
	var max_x := maxf(top_left.x, bottom_right.x)
	var max_y := maxf(top_left.y, bottom_right.y)
	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

func place_item(item: ItemNode, drop_global_pos: Vector2) -> void:
	if not enabled:
		return
	if item == null:
		return
	if not item.can_register_on_surface():
		return
	remove_item(item)
	_items_by_id[StringName(item.item_id)] = item
	if _items_root == null:
		push_warning("ShelfSurface ItemsRoot missing; cannot place item.")
		return
	if item.get_parent():
		item.reparent(_items_root, true)
	else:
		_items_root.add_child(item)
	item.global_rotation = 0.0
	item.global_scale = Vector2.ONE
	var target_x := _clamp_item_x(item, drop_global_pos.x)
	log_debug(
		"clamp item=%s cursor_x=%.1f target_x=%.1f cog_offset_x=%.2f",
		[
			item.item_id,
			drop_global_pos.x,
			target_x,
			item.get_global_cog().x - item.global_position.x,
		]
	)
	item.global_position = Vector2(target_x, item.global_position.y)
	item.snap_bottom_to_y(get_surface_y_global())
	item.z_index = int(item.global_position.y)
	item.set_current_surface(self)
	item.apply_collision_profile_shelfed()
	_debug_validate_item_alignment(item)
	log_debug("place item=%s pos=%.1f,%.1f", [item.item_id, item.global_position.x, item.global_position.y])

func get_surface_bounds_global() -> Rect2:
	if _surface_left and _surface_right:
		var left_x := _surface_left.global_position.x
		var right_x := _surface_right.global_position.x
		if left_x < right_x:
			var span_width := right_x - left_x
			var center_y := get_surface_y_global()
			return Rect2(Vector2(left_x, center_y - 0.5), Vector2(span_width, 1.0))
	var center := _resolve_surface_center_global()
	var shelf_width := shelf_length_px
	if shelf_width <= 0.0:
		var fallback_rect := _resolve_surface_rect_global()
		return fallback_rect
	return Rect2(
		Vector2(center.x - shelf_width * 0.5, center.y - 0.5),
		Vector2(shelf_width, 1.0)
	)

func _get_drop_rect_local() -> Rect2:
	if _drop_shape == null:
		return Rect2()
	var shape := _drop_shape.shape
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		return Rect2(_drop_shape.position - rect_shape.size * 0.5, rect_shape.size)
	return Rect2()

func _sync_drop_area() -> void:
	if _drop_shape == null:
		return
	var rect_shape := _drop_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	var original_size := rect_shape.size
	var original_bottom := _drop_shape.position.y + original_size.y * 0.5
	var target_width := shelf_length_px
	if target_width <= 0.0 and auto_from_cabinet:
		var sprite := _find_cabinet_sprite()
		if sprite and sprite.texture:
			target_width = sprite.texture.get_size().x * sprite.scale.x
	if target_width > 0.0:
		shelf_length_px = target_width
		rect_shape.size = Vector2(target_width, rect_shape.size.y)
	if drop_area_height_px > 0.0:
		rect_shape.size = Vector2(rect_shape.size.x, drop_area_height_px)
		_drop_shape.position.y = original_bottom - rect_shape.size.y * 0.5
		_sync_surface_shape_width(target_width)
		if _surface_left and _surface_right:
			var marker_y := 0.0
			if _surface_ref:
				marker_y = _surface_ref.position.y
			_surface_left.position = Vector2(-target_width * 0.5, marker_y)
			_surface_right.position = Vector2(target_width * 0.5, marker_y)

func _sync_surface_shape_width(target_width: float) -> void:
	if _surface_shape == null:
		return
	var shape := _surface_shape.shape
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		rect.size = Vector2(target_width, rect.size.y)

func _sync_visual_bar() -> void:
	if _visual_bar == null or _drop_shape == null:
		return
	var rect_shape := _drop_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	var rect_size := rect_shape.size
	_visual_bar.size = Vector2(rect_size.x, visual_bar_height_px)
	var surface_y := get_surface_y_global()
	var bar_left_x := _drop_shape.global_position.x - rect_size.x * 0.5
	_visual_bar.global_position = Vector2(bar_left_x, surface_y)
	_visual_bar.color = Color(0, 0, 0, 1)
	if _drop_line:
		var line_x := _drop_shape.global_position.x
		if _surface_ref:
			line_x = _surface_ref.global_position.x
		_drop_line.global_position = Vector2(line_x, surface_y)

func _find_cabinet_sprite() -> Sprite2D:
	var node: Node = get_parent()
	while node != null:
		if node.has_node("CabinetSprite"):
			return node.get_node("CabinetSprite") as Sprite2D
		node = node.get_parent()
	return null

func _resolve_children() -> void:
	_items_root = get_node_or_null("ItemsRoot") as Node2D
	_drop_line = get_node_or_null("DropLine") as Node2D
	_visual_bar = get_node_or_null("VisualBar") as ColorRect
	_surface_body = get_node_or_null("SurfaceBody") as StaticBody2D
	_surface_left = get_node_or_null("SurfaceLeft") as Node2D
	_surface_right = get_node_or_null("SurfaceRight") as Node2D
	if _surface_body:
		_surface_shape = _surface_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _items_root == null and _drop_area:
		_items_root = _drop_area.find_child("ItemsRoot", true, false) as Node2D
	if _drop_line == null and _drop_area:
		_drop_line = _drop_area.find_child("DropLine", true, false) as Node2D
	if _visual_bar == null and _drop_area:
		_visual_bar = _drop_area.find_child("VisualBar", true, false) as ColorRect

func _apply_physics_layers() -> void:
	if _surface_body:
		_surface_body.collision_layer = PhysicsLayers.LAYER_SHELF_BIT
		_surface_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT
	if _drop_area:
		_drop_area.collision_layer = PhysicsLayers.LAYER_PICK_AREA_BIT
		_drop_area.collision_mask = 0

func _register_surface() -> void:
	var registry = _resolve_surface_registry()
	if registry == null:
		return
	registry.register_shelf(self)

func _unregister_surface() -> void:
	var registry = _resolve_surface_registry()
	if registry == null:
		return
	registry.unregister_shelf(self)

func _resolve_surface_registry() -> SurfaceRegistry:
	return SurfaceRegistry.get_autoload()

func _pull_drop_area_height() -> void:
	if _drop_shape == null:
		return
	var rect_shape := _drop_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	if drop_area_height_px <= 0.0:
		drop_area_height_px = rect_shape.size.y

func _sync_from_editor() -> void:
	if _syncing_from_editor:
		return
	if not is_inside_tree():
		return
	_syncing_from_editor = true
	_resolve_children()
	_sync_drop_area()
	_sync_visual_bar()
	_syncing_from_editor = false

func _debug_validate_alignment() -> void:
	if not DebugLog.enabled():
		return
	if _drop_line:
		var surface_y: float = get_surface_y_global()
		var delta: float = abs(_drop_line.global_position.y - surface_y)
		if delta > 0.5:
			push_warning("ShelfSurface %s DropLine misaligned dy=%.2f surface_y=%.2f" % [shelf_id, delta, surface_y])

func _debug_validate_item_alignment(item: ItemNode) -> void:
	if not DebugLog.enabled() or item == null:
		return
	var surface_y: float = get_surface_y_global()
	var delta: float = abs(item.get_bottom_y_global() - surface_y)
	if delta > 0.5:
		push_warning("ShelfSurface %s item=%s bottom misaligned dy=%.2f surface_y=%.2f" % [shelf_id, item.item_id, delta, surface_y])

func get_surface_y_global() -> float:
	if _surface_ref:
		return _surface_ref.global_position.y + drop_y_offset_px
	if not _warned_missing_surface_ref:
		_warned_missing_surface_ref = true
		push_warning("ShelfSurface %s missing SurfaceRef; falling back to surface shape." % shelf_id)
	var fallback_y := _resolve_surface_top_global()
	return fallback_y + drop_y_offset_px

func get_surface_collision_y_global() -> float:
	return _resolve_surface_top_global()

func get_surface_kind() -> StringName:
	return EventSchema.SURFACE_KIND_SHELF

func _resolve_surface_top_global() -> float:
	if _surface_shape == null or _surface_shape.shape == null:
		if not _warned_missing_surface_shape:
			_warned_missing_surface_shape = true
			push_warning("ShelfSurface %s missing SurfaceBody/CollisionShape2D; using node Y." % shelf_id)
		return global_position.y
	if _surface_shape.shape is RectangleShape2D:
		var rect := _surface_shape.shape as RectangleShape2D
		var local_top := Vector2(0.0, -rect.size.y * 0.5)
		return (_surface_shape.global_transform * local_top).y
	if not _warned_missing_surface_shape:
		_warned_missing_surface_shape = true
		push_warning("ShelfSurface %s unsupported surface shape; using node Y." % shelf_id)
	return global_position.y

func _resolve_surface_center_global() -> Vector2:
	if _surface_ref:
		return _surface_ref.global_position
	var rect := _resolve_surface_rect_global()
	if rect.size != Vector2.ZERO:
		return rect.position + rect.size * 0.5
	return global_position

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

func _clamp_item_x(item: ItemNode, target_x: float) -> float:
	if item == null:
		return target_x
	var cog_offset_x := item.get_global_cog().x - item.global_position.x
	if _surface_left and _surface_right:
		var limit_min_x := _surface_left.global_position.x
		var limit_max_x := _surface_right.global_position.x
		if limit_min_x < limit_max_x:
			var target_cog_x := target_x + cog_offset_x
			var clamped_cog_x := clampf(target_cog_x, limit_min_x, limit_max_x)
			return clamped_cog_x - cog_offset_x
		return target_x
	var center_x := _resolve_surface_center_global().x
	if shelf_length_px <= 0.0:
		return target_x
	var shelf_min_x := center_x - shelf_length_px * 0.5
	var shelf_max_x := center_x + shelf_length_px * 0.5
	if shelf_min_x < shelf_max_x:
		var target_cog_x := target_x + cog_offset_x
		var clamped_cog_x := clampf(target_cog_x, shelf_min_x, shelf_max_x)
		return clamped_cog_x - cog_offset_x
	return target_x

func log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("ShelfSurface %s %s" % [shelf_id, format])
		return
	DebugLog.logf("ShelfSurface %s " % shelf_id + format, args)
