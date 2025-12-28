extends Node2D
class_name WardrobePhysicsTickAdapter

const SHELF_LAYER_MASK := 1
const ITEM_LAYER_MASK := 1 << 1

const TORQUE_BASE := 5.0
const Y_SNAP_EPSILON := 2.0
const OVERLAP_PUSH := 30.0
const OVERLAP_TORQUE := 1.5
const OVERLAP_MAX_PUSH_PER_ITEM_PX := 10.0
const OVERLAP_MAX_PUSH_TOTAL_PX := 18.0
const OVERLAP_MAX_AFFECTED := 2
const OVERLAP_MAX_AREA_RATIO := 0.2
const OVERLAP_PUSH_IMPULSE_PER_PX := 2.0
const OVERLAP_MIN_PUSH_PX := 1.0
const OVERLAP_IGNORE_PX := 1.0
const OVERLAP_COOLDOWN_FRAMES := 8
const OUT_OF_BOUNDS_MARGIN := 4.0
const HIGH_SPEED_LOG_THRESHOLD := 900.0
const SHELF_GROUP := "wardrobe_shelves"
const FLOOR_GROUP := "wardrobe_floor_zones"

@export var debug_log: bool = false

var _pending_stability_checks: Array[Dictionary] = []
var _drag_probe_item: ItemNode
var _drag_probe_supported := false
var _overlap_cooldowns: Dictionary = {}

func _ready() -> void:
	add_to_group("wardrobe_physics_tick")

func enqueue_drop_check(item: ItemNode, preferred_surface: Node = null) -> void:
	if item == null:
		return
	_pending_stability_checks.append({
		"item": item,
		"preferred_surface": preferred_surface,
	})

func request_settle_check(item: ItemNode) -> void:
	if item == null:
		return
	_pending_stability_checks.append({
		"item": item,
		"preferred_surface": null,
	})

func _physics_process(_delta: float) -> void:
	if _pending_stability_checks.is_empty():
		_update_drag_probe()
		return
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		_pending_stability_checks.clear()
		_update_drag_probe()
		return
	var checks: Array[Dictionary] = _pending_stability_checks
	_pending_stability_checks = []
	for i in range(checks.size()):
		var entry: Dictionary = checks[i]
		var item: ItemNode = entry.get("item", null) as ItemNode
		if item == null:
			continue
		if not is_instance_valid(item):
			continue
		var preferred_surface: Node = entry.get("preferred_surface", null) as Node
		_run_stability_check(space, item, preferred_surface)
	_update_drag_probe_with_space(space)

func _run_stability_check(
	space: PhysicsDirectSpaceState2D,
	item: ItemNode,
	preferred_surface: Node
) -> void:
	var cog_global := item.get_global_cog()
	var ray_hit: Dictionary = _cast_support_ray(space, item, cog_global)
	var overlap_hits: Array = _get_overlap_hits(space, item)
	var has_overlap := not overlap_hits.is_empty()
	if item.is_settling() and not item.allow_settle():
		_log_debug("skip settle item=%s grace_frames" % item.item_id)
		return
	var bounds := Rect2()
	if not ray_hit.is_empty():
		bounds = _resolve_surface_bounds_from_collider(ray_hit.get("collider", null) as Node)
	_log_out_of_bounds(item, bounds)
	_log_high_speed(item)
	_log_debug(
		"check item=%s cog=%.1f,%.1f ray=%s overlap=%s" % [
			item.item_id,
			cog_global.x,
			cog_global.y,
			_ray_hit_debug(ray_hit),
			str(has_overlap),
		]
	)
	if has_overlap:
		if _is_in_overlap_cooldown(item):
			_wake_overlap_neighbors(overlap_hits)
			var dir := _resolve_overlap_push_dir(item, overlap_hits, bounds)
			var metrics := _compute_overlap_metrics(item, overlap_hits)
			var reject_reason := _resolve_overlap_reject_reason(item, bounds, dir, metrics)
			if reject_reason != "":
				_log_overlap_metrics(item, metrics, reject_reason)
				_reject_big_overlap(item)
				_log_debug("overlap item=%s resolve" % item.item_id)
				return
			_log_debug("overlap skip item=%s cooldown" % item.item_id)
			return
		_resolve_overlap(item, overlap_hits, bounds)
		_log_debug("overlap item=%s resolve" % item.item_id)
		return
	if not ray_hit.is_empty() and bounds != Rect2() and _is_within_surface_bounds(item, bounds):
		var hit_pos: Vector2 = ray_hit.get("position", cog_global) as Vector2
		var bottom_y: float = item.get_global_bottom_y()
		var snap_delta: float = abs(hit_pos.y - bottom_y)
		if snap_delta <= Y_SNAP_EPSILON:
			var before_x := item.global_position.x
			var before_cog_x := item.get_global_cog().x
			item.freeze = true
			item.snap_to_surface(hit_pos, Y_SNAP_EPSILON)
			item.mark_stable()
			_clear_overlap_cooldown(item)
			if debug_log:
				_log_debug(
					"snap item=%s x=%.2f->%.2f cog_x=%.2f->%.2f" % [
						item.item_id,
						before_x,
						item.global_position.x,
						before_cog_x,
						item.get_global_cog().x,
					]
				)
			_log_debug("stable item=%s snap_y=%.2f" % [item.item_id, hit_pos.y])
			return
		item.freeze = false
		item.sleeping = false
		_log_debug("unstable item=%s snap_delta=%.2f" % [item.item_id, snap_delta])
		return
	if not ray_hit.is_empty() and bounds != Rect2():
		item.freeze = false
		item.sleeping = false
		_log_edge_support(item, bounds)
		_log_debug("unstable item=%s out_of_bounds" % item.item_id)
		return
	if not ray_hit.is_empty() and bounds == Rect2():
		_log_debug("unstable item=%s missing surface bounds" % item.item_id)
		item.freeze = false
		item.sleeping = false
		return
	item.freeze = false
	item.sleeping = false
	_apply_overhang_torque(item, preferred_surface, bounds)
	_log_debug("unstable item=%s torque applied" % item.item_id)

func _cast_support_ray(
	space: PhysicsDirectSpaceState2D,
	item: ItemNode,
	cog_global: Vector2
) -> Dictionary:
	var params := PhysicsRayQueryParameters2D.new()
	params.from = cog_global
	params.to = cog_global + Vector2(0.0, item.get_support_ray_length())
	params.collision_mask = SHELF_LAYER_MASK
	params.exclude = [item.get_rid()]
	return space.intersect_ray(params)

func _get_overlap_hits(space: PhysicsDirectSpaceState2D, item: ItemNode) -> Array:
	var shape_data: Dictionary = item.get_physics_shape_query()
	if shape_data.is_empty():
		return []
	var shape := shape_data.get("shape") as Shape2D
	var shape_transform := shape_data.get("transform") as Transform2D
	if shape == null:
		return []
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = shape_transform
	params.collision_mask = ITEM_LAYER_MASK
	params.exclude = [item.get_rid()]
	var hits: Array = space.intersect_shape(params, 4)
	if debug_log and not hits.is_empty():
		for hit in hits:
			var collider: Object = hit.get("collider", null) as Object
			_log_debug("overlap item=%s with=%s" % [item.item_id, _collider_debug(collider)])
	return hits

func _resolve_overlap(item: ItemNode, hits: Array, bounds: Rect2) -> void:
	if hits.is_empty():
		return
	var before_x := item.global_position.x
	var before_cog_x := item.get_global_cog().x
	var dir := _resolve_overlap_push_dir(item, hits, bounds)
	var metrics := _compute_overlap_metrics(item, hits)
	var max_push: float = float(metrics.get("max_push_px", 0.0))
	if max_push < OVERLAP_IGNORE_PX:
		_wake_overlap_neighbors(hits)
		_log_debug("overlap skip item=%s tiny_push=%.2f" % [item.item_id, max_push])
		return
	var reject_reason := _resolve_overlap_reject_reason(item, bounds, dir, metrics)
	_log_overlap_metrics(item, metrics, reject_reason)
	if reject_reason != "":
		_reject_big_overlap(item)
		return
	_apply_small_overlap_push(item, dir, metrics)
	_set_overlap_cooldown(item)
	var after_x := item.global_position.x
	var after_cog_x := item.get_global_cog().x
	if debug_log:
		_log_debug(
			"overlap move item=%s x=%.2f->%.2f cog_x=%.2f->%.2f" % [
				item.item_id,
				before_x,
				after_x,
				before_cog_x,
				after_cog_x,
			]
		)

func _apply_overhang_torque(item: ItemNode, preferred_surface: Node, fallback_bounds: Rect2) -> void:
	var bounds := fallback_bounds
	if bounds == Rect2():
		bounds = _resolve_surface_bounds_from_collider(preferred_surface)
	if bounds == Rect2():
		_log_debug("torque skipped item=%s missing surface bounds" % item.item_id)
		return
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var cog_x := item.get_global_cog().x
	var clamped := clampf(cog_x, left_x, right_x)
	var overhang := cog_x - clamped
	if is_equal_approx(overhang, 0.0):
		_log_debug("torque skipped item=%s overhang=0" % item.item_id)
		return
	var sign_dir := 1.0 if overhang > 0.0 else -1.0
	item.apply_torque_impulse(TORQUE_BASE * item.mass * sign_dir)

func _is_within_surface_bounds(item: ItemNode, bounds: Rect2) -> bool:
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var cog_x := item.get_global_cog().x
	return cog_x >= left_x and cog_x <= right_x

func _resolve_overlap_push_dir(item: ItemNode, hits: Array, bounds: Rect2) -> float:
	var first: Dictionary = {}
	if hits[0] is Dictionary:
		first = hits[0] as Dictionary
	var collider: Object = first.get("collider", null) as Object
	var dir := 0.0
	if collider is Node2D:
		var other := collider as Node2D
		dir = signf(item.get_global_cog().x - other.global_position.x)
	if bounds != Rect2():
		var center_x := bounds.position.x + bounds.size.x * 0.5
		var left_x := bounds.position.x
		var right_x := bounds.position.x + bounds.size.x
		var cog_x := item.get_global_cog().x
		if cog_x < left_x:
			dir = signf(center_x - cog_x)
		elif cog_x > right_x:
			dir = signf(center_x - cog_x)
	if is_equal_approx(dir, 0.0):
		dir = 1.0 if randf() < 0.5 else -1.0
	return dir

func _compute_overlap_metrics(item: ItemNode, hits: Array) -> Dictionary:
	var item_rect := _get_item_aabb(item)
	var item_area := item_rect.size.x * item_rect.size.y
	var total_push := 0.0
	var max_push := 0.0
	var max_area_ratio := 0.0
	var affected := 0
	var entries: Array = []
	for hit in hits:
		if not (hit is Dictionary):
			continue
		var collider: Object = (hit as Dictionary).get("collider", null) as Object
		if collider == null or collider == item:
			continue
		if not (collider is ItemNode):
			continue
		var other := collider as ItemNode
		var other_rect := _get_item_aabb(other)
		if item_rect.size == Vector2.ZERO or other_rect.size == Vector2.ZERO:
			continue
		var overlap := item_rect.intersection(other_rect)
		if overlap.size == Vector2.ZERO:
			continue
		var overlap_x := overlap.size.x
		total_push += overlap_x
		max_push = maxf(max_push, overlap_x)
		if item_area > 0.0:
			var ratio := (overlap.size.x * overlap.size.y) / item_area
			max_area_ratio = maxf(max_area_ratio, ratio)
		affected += 1
		entries.append({
			"other": other,
			"overlap_x": overlap_x,
			"dir": signf(item.get_global_cog().x - other.get_global_cog().x),
		})
	return {
		"total_push_px": total_push,
		"max_push_px": max_push,
		"max_area_ratio": max_area_ratio,
		"affected_count": affected,
		"entries": entries,
	}

func _resolve_overlap_reject_reason(
	item: ItemNode,
	bounds: Rect2,
	dir: float,
	metrics: Dictionary
) -> String:
	var affected: int = int(metrics.get("affected_count", 0))
	var max_push: float = float(metrics.get("max_push_px", 0.0))
	var total_push: float = float(metrics.get("total_push_px", 0.0))
	var max_ratio: float = float(metrics.get("max_area_ratio", 0.0))
	if affected > OVERLAP_MAX_AFFECTED:
		return "reject_big_overlap_affected"
	if max_ratio > OVERLAP_MAX_AREA_RATIO:
		return "reject_big_overlap_area"
	if max_push > OVERLAP_MAX_PUSH_PER_ITEM_PX:
		return "reject_big_overlap_push_item"
	if total_push > OVERLAP_MAX_PUSH_TOTAL_PX:
		return "reject_big_overlap_push_total"
	if _would_push_out_of_bounds(item, bounds, dir, max_push):
		return "reject_big_overlap_bounds"
	return ""

func _would_push_out_of_bounds(item: ItemNode, bounds: Rect2, dir: float, push_px: float) -> bool:
	if bounds == Rect2():
		return false
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var next_x := item.get_global_cog().x + dir * push_px
	return next_x < left_x or next_x > right_x

func _apply_small_overlap_push(item: ItemNode, dir: float, metrics: Dictionary) -> void:
	var total_push: float = float(metrics.get("total_push_px", 0.0))
	var planned_push := clampf(total_push, OVERLAP_MIN_PUSH_PX, OVERLAP_MAX_PUSH_TOTAL_PX)
	_wake_item(item)
	var entries: Array = metrics.get("entries", []) as Array
	if entries.is_empty():
		item.apply_central_impulse(Vector2(dir * planned_push * OVERLAP_PUSH_IMPULSE_PER_PX * item.mass, 0.0))
	item.apply_torque_impulse(randf_range(-1.0, 1.0) * OVERLAP_TORQUE * item.mass)
	_log_debug("overlap allow_small_push item=%s planned_px=%.2f dir=%.0f" % [
		item.item_id,
		planned_push,
		dir,
	])
	if not entries.is_empty():
		_apply_mass_aware_pushes(item, metrics)

func _apply_mass_aware_pushes(item: ItemNode, metrics: Dictionary) -> void:
	var entries: Array = metrics.get("entries", []) as Array
	if entries.is_empty():
		return
	for entry in entries:
		if not (entry is Dictionary):
			continue
		var other: ItemNode = (entry as Dictionary).get("other", null) as ItemNode
		if other == null or not is_instance_valid(other):
			continue
		_wake_item(other)
		var overlap_x := float((entry as Dictionary).get("overlap_x", 0.0))
		if overlap_x <= 0.0:
			continue
		var dir := float((entry as Dictionary).get("dir", 0.0))
		if is_equal_approx(dir, 0.0):
			dir = 1.0 if randf() < 0.5 else -1.0
		var total_mass := maxf(0.1, item.mass + other.mass)
		var self_push := overlap_x * (other.mass / total_mass)
		item.apply_central_impulse(Vector2(dir * self_push * OVERLAP_PUSH_IMPULSE_PER_PX * item.mass, 0.0))
		_log_debug("overlap push item=%s other=%s self_px=%.2f" % [
			item.item_id,
			other.item_id,
			self_push,
		])

func _is_in_overlap_cooldown(item: ItemNode) -> bool:
	if item == null:
		return false
	var item_key := StringName(item.item_id)
	var remaining: int = int(_overlap_cooldowns.get(item_key, 0))
	if remaining <= 0:
		return false
	_overlap_cooldowns[item_key] = remaining - 1
	return true

func _set_overlap_cooldown(item: ItemNode) -> void:
	if item == null:
		return
	var item_key := StringName(item.item_id)
	_overlap_cooldowns[item_key] = OVERLAP_COOLDOWN_FRAMES

func _wake_overlap_neighbors(hits: Array) -> void:
	if hits.is_empty():
		return
	for hit in hits:
		if not (hit is Dictionary):
			continue
		var collider: Object = (hit as Dictionary).get("collider", null) as Object
		if collider is ItemNode:
			_wake_item(collider as ItemNode)

func _wake_item(item: ItemNode) -> void:
	if item == null:
		return
	item.freeze = false
	item.sleeping = false

func _clear_overlap_cooldown(item: ItemNode) -> void:
	if item == null:
		return
	var item_key := StringName(item.item_id)
	_overlap_cooldowns.erase(item_key)

func _reject_big_overlap(item: ItemNode) -> void:
	item.freeze = false
	item.sleeping = false
	_remove_item_from_surface_registries(item)
	var floor_zone := _get_floor_below_item(item.global_position.y)
	if floor_zone != null:
		if floor_zone.has_method("drop_item_with_fall"):
			floor_zone.call("drop_item_with_fall", item, item.global_position)
		elif floor_zone.has_method("drop_item"):
			floor_zone.call("drop_item", item, item.global_position)
	_log_debug("overlap reject_big_overlap item=%s drop=%s" % [
		item.item_id,
		"floor" if floor_zone != null else "none",
	])

func _remove_item_from_surface_registries(item: ItemNode) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for shelf in tree.get_nodes_in_group(SHELF_GROUP):
		if shelf != null and shelf.has_method("remove_item"):
			shelf.call("remove_item", item)
	for zone in tree.get_nodes_in_group(FLOOR_GROUP):
		if zone != null and zone.has_method("remove_item"):
			zone.call("remove_item", item)

func _get_floor_below_item(item_y: float) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node = null
	var best_delta := INF
	for zone in tree.get_nodes_in_group(FLOOR_GROUP):
		if zone == null or not (zone is Node2D):
			continue
		var delta := (zone as Node2D).global_position.y - item_y
		if delta <= 0.0:
			continue
		if delta < best_delta:
			best_delta = delta
			best = zone
	return best

func _get_item_aabb(item: ItemNode) -> Rect2:
	if item == null:
		return Rect2()
	var shape_data: Dictionary = item.get_physics_shape_query()
	if shape_data.is_empty():
		return _get_sprite_aabb(item)
	var shape := shape_data.get("shape") as Shape2D
	var shape_transform := shape_data.get("transform") as Transform2D
	return _get_shape_aabb(shape, shape_transform)

func _get_sprite_aabb(item: ItemNode) -> Rect2:
	if item == null:
		return Rect2()
	var half := Vector2(item.get_visual_half_width(), item.get_visual_half_height())
	return Rect2(item.global_position - half, half * 2.0)

func _get_shape_aabb(shape: Shape2D, shape_transform: Transform2D) -> Rect2:
	if shape == null:
		return Rect2()
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var half := rect.size * 0.5
		var points := PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for point in points:
			var world := shape_transform * point
			min_x = minf(min_x, world.x)
			max_x = maxf(max_x, world.x)
			min_y = minf(min_y, world.y)
			max_y = maxf(max_y, world.y)
		return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var center := shape_transform.origin
		var r := circle.radius
		return Rect2(Vector2(center.x - r, center.y - r), Vector2(r * 2.0, r * 2.0))
	return Rect2()

func _log_overlap_metrics(item: ItemNode, metrics: Dictionary, decision: String) -> void:
	if not debug_log:
		return
	_log_debug(
		"overlap metrics item=%s area_ratio=%.3f max_push=%.2f total_push=%.2f affected=%d decision=%s" % [
			item.item_id,
			float(metrics.get("max_area_ratio", 0.0)),
			float(metrics.get("max_push_px", 0.0)),
			float(metrics.get("total_push_px", 0.0)),
			int(metrics.get("affected_count", 0)),
			"allow_small_push" if decision == "" else decision,
		]
	)

func set_drag_probe(item: ItemNode) -> void:
	_drag_probe_item = item

func clear_drag_probe(item: ItemNode) -> void:
	if _drag_probe_item == item:
		_drag_probe_item = null
		_drag_probe_supported = false

func is_drag_probe_supported() -> bool:
	return _drag_probe_supported

func _update_drag_probe() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space == null:
		_drag_probe_supported = false
		return
	_update_drag_probe_with_space(space)

func _update_drag_probe_with_space(space: PhysicsDirectSpaceState2D) -> void:
	if _drag_probe_item == null or not is_instance_valid(_drag_probe_item):
		_drag_probe_supported = false
		return
	var cog_global := _drag_probe_item.get_global_cog()
	var ray_hit: Dictionary = _cast_support_ray(space, _drag_probe_item, cog_global)
	_drag_probe_supported = not ray_hit.is_empty()
	_log_debug(
		"drag_probe item=%s supported=%s ray=%s" % [
			_drag_probe_item.item_id,
			str(_drag_probe_supported),
			_ray_hit_debug(ray_hit),
		]
	)

func _resolve_surface_bounds_from_collider(collider: Node) -> Rect2:
	var node := collider
	while node != null:
		if node.has_method("get_surface_bounds_global"):
			var bounds_var: Variant = node.call("get_surface_bounds_global")
			if typeof(bounds_var) == TYPE_RECT2:
				return bounds_var as Rect2
		node = node.get_parent()
	return Rect2()

func _log_out_of_bounds(item: ItemNode, bounds: Rect2) -> void:
	if not debug_log:
		return
	if bounds == Rect2():
		return
	var x := item.get_global_cog().x
	var left_x := bounds.position.x - OUT_OF_BOUNDS_MARGIN
	var right_x := bounds.position.x + bounds.size.x + OUT_OF_BOUNDS_MARGIN
	if x < left_x or x > right_x:
		_log_debug(
			"oob item=%s x=%.1f bounds=(%.1f..%.1f)" % [
				item.item_id,
				x,
				left_x,
				right_x,
			]
		)

func _log_high_speed(item: ItemNode) -> void:
	if not debug_log:
		return
	var speed := item.linear_velocity.length()
	if speed >= HIGH_SPEED_LOG_THRESHOLD:
		_log_debug("fast item=%s speed=%.1f" % [item.item_id, speed])

func _log_edge_support(item: ItemNode, bounds: Rect2) -> void:
	if not debug_log:
		return
	if bounds == Rect2():
		return
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var cog_x := item.get_global_cog().x
	if cog_x < left_x or cog_x > right_x:
		_log_debug(
			"edge_support item=%s cog_x=%.1f bounds=(%.1f..%.1f)" % [
				item.item_id,
				cog_x,
				left_x,
				right_x,
			]
		)

func _log_debug(message: String) -> void:
	if not debug_log:
		return
	print("[PhysicsTick] %s" % message)

func _ray_hit_debug(ray_hit: Dictionary) -> String:
	if ray_hit.is_empty():
		return "none"
	var collider: Object = ray_hit.get("collider", null) as Object
	var pos: Vector2 = ray_hit.get("position", Vector2.ZERO)
	return "%s at %.1f,%.1f" % [_collider_debug(collider), pos.x, pos.y]

func _collider_debug(collider: Object) -> String:
	if collider == null:
		return "null"
	if collider is Node:
		var node := collider as Node
		return "%s(%s)" % [node.name, node.get_class()]
	return str(collider)
