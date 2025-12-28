extends Node2D
class_name WardrobePhysicsTickAdapter

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const PhysicsPlacementGateScript := preload("res://scripts/wardrobe/physics/physics_placement_gate.gd")
const SurfaceRegistry := preload("res://scripts/wardrobe/surface/surface_registry.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")
const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const TORQUE_BASE := 5.0
const Y_SNAP_EPSILON := 2.0
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
const REJECT_PASS_THROUGH_MARGIN_PX := 2.0

var _pending_stability_checks: Array[Dictionary] = []
var _drag_probe_item: ItemNode
var _drag_probe_supported := false
var _overlap_cooldowns: Dictionary = {}
var _placement_gate: PhysicsPlacementGate
var _surface_registry: SurfaceRegistry
var _run_manager: RunManagerBase

func _ready() -> void:
	add_to_group(PhysicsLayers.GROUP_TICK)
	_placement_gate = PhysicsPlacementGateScript.new(
		OVERLAP_MAX_AFFECTED,
		OVERLAP_MAX_AREA_RATIO,
		OVERLAP_MAX_PUSH_PER_ITEM_PX,
		OVERLAP_MAX_PUSH_TOTAL_PX,
		OVERLAP_MIN_PUSH_PX,
		OVERLAP_IGNORE_PX
	)
	_surface_registry = SurfaceRegistry.get_autoload()
	_run_manager = get_node_or_null("/root/RunManager") as RunManagerBase

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
	if item.is_reject_falling():
		_log_debug("skip settle item=%s reject_falling", [item.item_id])
		return
	if item.is_transfer_active():
		_log_debug("skip settle item=%s transfer_active", [item.item_id])
		return
	if item.is_settling() and not item.allow_settle():
		_log_debug("skip settle item=%s grace_frames", [item.item_id])
		return
	var bounds := Rect2()
	if not ray_hit.is_empty():
		bounds = _resolve_surface_bounds_from_collider(ray_hit.get("collider", null) as Node)
	_log_out_of_bounds(item, bounds)
	_log_high_speed(item)
	_log_debug(
		"check item=%s cog=%.1f,%.1f ray=%s overlap=%s",
		[
			item.item_id,
			cog_global.x,
			cog_global.y,
			_ray_hit_debug(ray_hit),
			str(has_overlap),
		]
	)
	if has_overlap:
		var dir := _resolve_overlap_push_dir(item, overlap_hits, bounds)
		var metrics := _compute_overlap_metrics(item, overlap_hits)
		var would_push := _would_push_out_of_bounds(item, bounds, dir, float(metrics.get("max_push_px", 0.0)))
		var result: PhysicsGateResult = _placement_gate.decide_overlap(metrics, would_push)
		var reason := StringName()
		if result != null:
			reason = result.reason
		if _is_in_overlap_cooldown(item):
			if result != null and result.decision == PhysicsPlacementGate.Decision.REJECT:
				_log_overlap_metrics(item, metrics, String(reason))
				_reject_big_overlap(item)
				_log_debug("overlap item=%s resolve", [item.item_id])
				return
			_log_debug("overlap skip item=%s cooldown", [item.item_id])
			return
		if reason != StringName():
			_log_overlap_metrics(item, metrics, String(reason))
		var decision := PhysicsPlacementGate.Decision.ALLOW
		if result != null:
			decision = result.decision as PhysicsPlacementGate.Decision
		match decision:
			PhysicsPlacementGate.Decision.REJECT:
				_reject_big_overlap(item)
			PhysicsPlacementGate.Decision.ALLOW_NUDGE:
				_apply_small_overlap_push(item, dir, metrics)
				_set_overlap_cooldown(item)
			_:
				pass
		_log_debug("overlap item=%s resolve", [item.item_id])
		return
	if not ray_hit.is_empty() and bounds != Rect2() and _is_within_surface_bounds(item, bounds):
		var hit_pos: Vector2 = ray_hit.get("position", cog_global) as Vector2
		var bottom_y: float = item.get_bottom_y_global()
		var snap_delta: float = abs(hit_pos.y - bottom_y)
		if snap_delta <= Y_SNAP_EPSILON:
			var impact: float = abs(item.linear_velocity.y)
			var before_x := item.global_position.x
			var before_cog_x := item.get_global_cog().x
			item.freeze = true
			item.snap_to_surface(hit_pos, Y_SNAP_EPSILON)
			item.mark_stable()
			_clear_overlap_cooldown(item)
			_log_debug(
				"snap item=%s x=%.2f->%.2f cog_x=%.2f->%.2f",
				[
					item.item_id,
					before_x,
					item.global_position.x,
					before_cog_x,
					item.get_global_cog().x,
				]
			)
			_log_debug("stable item=%s snap_y=%.2f", [item.item_id, hit_pos.y])
			if item.consume_landing_arm():
				_handle_item_landed(item, ray_hit, hit_pos, impact)
			return
		item.arm_landing()
		item.freeze = false
		item.sleeping = false
		_log_debug("unstable item=%s snap_delta=%.2f", [item.item_id, snap_delta])
		return
	if not ray_hit.is_empty() and bounds != Rect2():
		item.arm_landing()
		item.freeze = false
		item.sleeping = false
		_log_edge_support(item, bounds)
		_log_debug("unstable item=%s out_of_bounds", [item.item_id])
		return
	if not ray_hit.is_empty() and bounds == Rect2():
		_log_debug("unstable item=%s missing surface bounds", [item.item_id])
		item.arm_landing()
		item.freeze = false
		item.sleeping = false
		return
	item.arm_landing()
	item.freeze = false
	item.sleeping = false
	_apply_overhang_torque(item, preferred_surface, bounds)
	_log_debug("unstable item=%s torque applied", [item.item_id])

func _cast_support_ray(
	space: PhysicsDirectSpaceState2D,
	item: ItemNode,
	cog_global: Vector2
) -> Dictionary:
	var params := PhysicsRayQueryParameters2D.new()
	params.from = cog_global
	params.to = cog_global + Vector2(0.0, item.get_support_ray_length())
	params.collision_mask = PhysicsLayers.LAYER_SHELF_BIT | PhysicsLayers.LAYER_FLOOR_BIT
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
	params.collision_mask = PhysicsLayers.MASK_ITEMS_QUERY
	params.exclude = [item.get_rid()]
	var hits: Array = space.intersect_shape(params, 4)
	if DebugLog.enabled() and not hits.is_empty():
		for hit in hits:
			var collider: Object = hit.get("collider", null) as Object
			_log_debug("overlap item=%s with=%s", [item.item_id, _collider_debug(collider)])
	return hits

func _apply_overhang_torque(item: ItemNode, preferred_surface: Node, fallback_bounds: Rect2) -> void:
	var bounds := fallback_bounds
	if bounds == Rect2():
		bounds = _resolve_surface_bounds_from_collider(preferred_surface)
	if bounds == Rect2():
		_log_debug("torque skipped item=%s missing surface bounds", [item.item_id])
		return
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var cog_x := item.get_global_cog().x
	var clamped := clampf(cog_x, left_x, right_x)
	var overhang := cog_x - clamped
	if is_equal_approx(overhang, 0.0):
		_log_debug("torque skipped item=%s overhang=0", [item.item_id])
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

func _would_push_out_of_bounds(item: ItemNode, bounds: Rect2, dir: float, push_px: float) -> bool:
	if bounds == Rect2():
		return false
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var next_x := item.get_global_cog().x + dir * push_px
	return next_x < left_x or next_x > right_x

func _apply_small_overlap_push(item: ItemNode, dir: float, metrics: Dictionary) -> void:
	if item == null or not item.is_settling():
		return
	var total_push: float = float(metrics.get("total_push_px", 0.0))
	var planned_push := clampf(total_push, OVERLAP_MIN_PUSH_PX, OVERLAP_MAX_PUSH_TOTAL_PX)
	_wake_item(item)
	item.apply_central_impulse(Vector2(dir * planned_push * OVERLAP_PUSH_IMPULSE_PER_PX * item.mass, 0.0))
	item.apply_torque_impulse(randf_range(-1.0, 1.0) * OVERLAP_TORQUE * item.mass)
	_log_debug("overlap allow_small_push item=%s planned_px=%.2f dir=%.0f", [
		item.item_id,
		planned_push,
		dir,
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

func _wake_item(item: ItemNode) -> void:
	if item == null:
		return
	item.arm_landing()
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
	var floor_zone := _get_floor_below_item(item)
	if floor_zone != null:
		var pass_through_y: float = floor_zone.get_surface_collision_y_global()
		item.start_reject_fall(pass_through_y)
		if floor_zone.has_method("drop_item_with_fall"):
			floor_zone.call("drop_item_with_fall", item, item.global_position)
		elif floor_zone.has_method("drop_item"):
			floor_zone.call("drop_item", item, item.global_position)
	_log_debug("overlap reject_big_overlap item=%s drop=%s", [
		item.item_id,
		"floor" if floor_zone != null else "none",
	])

func _remove_item_from_surface_registries(item: ItemNode) -> void:
	if _surface_registry == null:
		return
	_surface_registry.remove_item_from_all(item)

func _get_floor_below_item(item: ItemNode) -> Node:
	if item == null or _surface_registry == null:
		return null
	var item_rect := item.get_collider_aabb_global()
	var item_x := item.global_position.x
	if item_rect.size != Vector2.ZERO:
		item_x = item_rect.position.x + item_rect.size.x * 0.5
	var bottom_y := item.get_bottom_y_global()
	return _surface_registry.get_floor_below(item_x, bottom_y)

func _get_item_aabb(item: ItemNode) -> Rect2:
	if item == null:
		return Rect2()
	return item.get_collider_aabb_global()

func _log_overlap_metrics(item: ItemNode, metrics: Dictionary, decision: String) -> void:
	if not DebugLog.enabled():
		return
	_log_debug(
		"overlap metrics item=%s area_ratio=%.3f max_push=%.2f total_push=%.2f affected=%d decision=%s",
		[
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
		"drag_probe item=%s supported=%s ray=%s",
		[
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

func _handle_item_landed(item: ItemNode, ray_hit: Dictionary, hit_pos: Vector2, impact: float) -> void:
	var surface := _resolve_surface_from_collider(ray_hit.get("collider", null) as Node)
	var surface_kind := _resolve_surface_kind(surface)
	var payload := _build_landing_payload(item, surface_kind, impact)
	if DebugLog.enabled():
		DebugLog.event(StringName("ITEM_LANDED"), payload)
	var outcome := _record_item_landed(payload)
	_apply_landing_outcome(item, outcome, impact, hit_pos)

func _build_landing_payload(item: ItemNode, surface_kind: StringName, impact: float) -> Dictionary:
	var item_kind := WardrobeItemConfigScript.get_kind_for_item_type(item.item_type)
	var cause := item.consume_landing_cause()
	return {
		EventSchema.PAYLOAD_ITEM_ID: StringName(item.item_id),
		EventSchema.PAYLOAD_ITEM_KIND: item_kind,
		EventSchema.PAYLOAD_SURFACE_KIND: surface_kind,
		EventSchema.PAYLOAD_CAUSE: cause,
		EventSchema.PAYLOAD_IMPACT: impact,
		EventSchema.PAYLOAD_TICK: 0,
	}

func _record_item_landed(payload: Dictionary) -> LandingOutcomeScript:
	if _run_manager == null:
		return null
	return _run_manager.record_item_landed(payload)

func _apply_landing_outcome(
	item: ItemNode,
	outcome: LandingOutcomeScript,
	impact: float,
	_hit_pos: Vector2
) -> void:
	if item == null or outcome == null:
		return
	for effect in outcome.effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var entry := effect as Dictionary
		var effect_type: StringName = entry.get(LandingOutcomeScript.KEY_TYPE, LandingOutcomeScript.EFFECT_NONE)
		match effect_type:
			LandingOutcomeScript.EFFECT_BOUNCE:
				var multiplier: float = float(entry.get(LandingOutcomeScript.KEY_MULTIPLIER, 1.0))
				item.freeze = false
				item.sleeping = false
				item.apply_central_impulse(Vector2(0.0, -impact * multiplier * item.mass))
				_log_debug("landing bounce item=%s impulse=%.2f", [item.item_id, impact * multiplier * item.mass])
			LandingOutcomeScript.EFFECT_BREAK:
				item.freeze = true
				item.sleeping = true
				item.visible = false
				item.set_process(false)
				item.set_physics_process(false)
				item.collision_layer = 0
				item.collision_mask = 0
				_log_debug("landing break item=%s", [item.item_id])
			_:
				pass

func _resolve_surface_from_collider(collider: Node) -> WardrobeSurface2D:
	var node := collider
	while node != null:
		if node is WardrobeSurface2D:
			return node as WardrobeSurface2D
		node = node.get_parent()
	return null

func _resolve_surface_kind(surface: WardrobeSurface2D) -> StringName:
	if surface == null:
		return EventSchema.SURFACE_KIND_UNKNOWN
	var kind_var: Variant = surface.call("get_surface_kind") if surface.has_method("get_surface_kind") else EventSchema.SURFACE_KIND_UNKNOWN
	return kind_var if typeof(kind_var) == TYPE_STRING_NAME else EventSchema.SURFACE_KIND_UNKNOWN

func _log_out_of_bounds(item: ItemNode, bounds: Rect2) -> void:
	if not DebugLog.enabled():
		return
	if bounds == Rect2():
		return
	var x := item.get_global_cog().x
	var left_x := bounds.position.x - OUT_OF_BOUNDS_MARGIN
	var right_x := bounds.position.x + bounds.size.x + OUT_OF_BOUNDS_MARGIN
	if x < left_x or x > right_x:
		_log_debug(
			"oob item=%s x=%.1f bounds=(%.1f..%.1f)",
			[
				item.item_id,
				x,
				left_x,
				right_x,
			]
		)

func _log_high_speed(item: ItemNode) -> void:
	if not DebugLog.enabled():
		return
	var speed := item.linear_velocity.length()
	if speed >= HIGH_SPEED_LOG_THRESHOLD:
		_log_debug("fast item=%s speed=%.1f", [item.item_id, speed])

func _log_edge_support(item: ItemNode, bounds: Rect2) -> void:
	if not DebugLog.enabled():
		return
	if bounds == Rect2():
		return
	var left_x := bounds.position.x
	var right_x := bounds.position.x + bounds.size.x
	var cog_x := item.get_global_cog().x
	if cog_x < left_x or cog_x > right_x:
		_log_debug(
			"edge_support item=%s cog_x=%.1f bounds=(%.1f..%.1f)",
			[
				item.item_id,
				cog_x,
				left_x,
				right_x,
			]
		)

func _log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("PhysicsTick %s" % format)
		return
	DebugLog.logf("PhysicsTick " + format, args)

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
