extends RefCounted
class_name WardrobeDragDropAdapter

const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")
const PickPutSwapResolverScript := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const WardrobeInteractionEventAdapterScript := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const WardrobeInteractionEventsAdapterScript := preload("res://scripts/ui/wardrobe_interaction_events.gd")
const DeskEventDispatcherScript := preload("res://scripts/ui/desk_event_dispatcher.gd")
const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")
const InteractionEventScript := preload("res://scripts/domain/interaction/interaction_event.gd")
const InteractionResultScript := preload("res://scripts/domain/interaction/interaction_result.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const PlacementTypesScript := preload("res://scripts/app/wardrobe/placement/placement_types.gd")
const ShelfSurfaceAdapterScript := preload("res://scripts/ui/shelf_surface_adapter.gd")
const FloorZoneAdapterScript := preload("res://scripts/ui/floor_zone_adapter.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")
const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const SurfaceRegistry := preload("res://scripts/wardrobe/surface/surface_registry.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientDropZoneScript := preload("res://scripts/wardrobe/client_drop_zone.gd")
const TicketRackScript := preload("res://scripts/wardrobe/ticket_rack.gd")

const HOVER_DISTANCE_SQ := 64.0 * 64.0
const HOVER_TIE_EPSILON := 0.001
const HOVER_COLOR := Color(1.0, 0.92, 0.55, 1.0)
const PASS_THROUGH_MARGIN_PX := 2.0
const META_ORIGIN_SLOT_ID := "drag_origin_slot_id"
const META_ORIGIN_POS := "drag_origin_global_pos"

var _interaction_service: WardrobeInteractionService
var _storage_state: WardrobeStorageState
var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _slots_array: Array[WardrobeSlot] = []
var _item_nodes: Dictionary = {}
var _spawned_items: Array = []
var _event_adapter: WardrobeInteractionEventAdapter
var _interaction_events: WardrobeInteractionEventsAdapter
var _desk_event_dispatcher: DeskEventDispatcher
var _desk_system: DeskServicePointSystem
var _item_visuals: WardrobeItemVisualsAdapter
var _interaction_logger
var _find_item_instance: Callable
var _cursor_hand: CursorHand
var _physics_tick
var _validate_world: Callable
var _last_interaction_command: InteractionCommandScript
var _event_connected := false
var _drag_active := false
var _hover_slot: WardrobeSlot
var _hover_slot_original_modulate := Color.WHITE
var _shelf_surfaces: Array = []
var _floor_zone: FloorZoneAdapter
var _floor_zones: Array = []
var _surface_registry: SurfaceRegistry
var _validate_pick_callback: Callable
var _ticket_rack_slots: Array[WardrobeSlot] = []
var _ticket_racks: Array = []
var _tray_slots: Array[WardrobeSlot] = []
var _client_drop_zones: Array = []
var _drag_origin_slot: WardrobeSlot
var _drag_origin_slot_id: StringName = StringName()
var _drag_origin_pos: Vector2 = Vector2.ZERO
var _drag_item_instance_id: StringName = StringName()
var _drag_item_node: ItemNode
var _drag_returning := false

func configure(context: RefCounted, cursor_hand: CursorHand, validate_world: Callable = Callable()) -> void:
	var typed := context
	_interaction_service = typed.interaction_service
	_storage_state = typed.storage_state
	_slots = typed.slots
	_slot_lookup = typed.slot_lookup
	_item_nodes = typed.item_nodes
	_spawned_items = typed.spawned_items
	_item_visuals = typed.item_visuals
	_event_adapter = typed.event_adapter
	_interaction_events = typed.interaction_events
	_desk_event_dispatcher = typed.desk_event_dispatcher
	_desk_system = typed.desk_system
	_find_item_instance = typed.find_item_instance
	_interaction_logger = typed.interaction_logger
	_cursor_hand = cursor_hand
	_physics_tick = typed.physics_tick
	_validate_world = validate_world
	_surface_registry = SurfaceRegistry.get_autoload()
	_ticket_rack_slots = typed.ticket_rack_slots
	_ticket_racks = typed.ticket_racks
	_tray_slots = typed.tray_slots
	_client_drop_zones = typed.client_drop_zones
	_cache_slots()
	_setup_item_visuals(typed.item_scene)
	_setup_interaction_events(typed.desk_by_id)
	_setup_desk_dispatcher(
		typed.desk_by_id,
		typed.desk_system,
		typed.client_queue_state,
		typed.clients,
		typed.apply_patience_penalty
	)
	_connect_event_adapter()

func configure_rules(validate_pick: Callable) -> void:
	_validate_pick_callback = validate_pick

func configure_surface_targets(
	shelves: Array,
	floor_zone: FloorZoneAdapter
) -> void:
	_shelf_surfaces = shelves
	_floor_zone = floor_zone
	_floor_zones = []
	if floor_zone != null:
		_floor_zones.append(floor_zone)
	if floor_zone != null and floor_zone is FloorZoneAdapter:
		for zone in floor_zone.get_tree().get_nodes_in_group(FloorZoneAdapter.FLOOR_GROUP):
			if zone is FloorZoneAdapter and not _floor_zones.has(zone):
				_floor_zones.append(zone)

func on_pointer_down(cursor_pos: Vector2) -> void:
	_drag_active = true
	_update_hover(cursor_pos)
	_log_debug("pointer_down pos=%.1f,%.1f hover=%s hand_item=%s", [
		cursor_pos.x,
		cursor_pos.y,
		_get_hover_slot_id(),
		_get_hand_item_id(),
	])
	_log_click_snapshot("down", cursor_pos)
	if _cursor_hand == null:
		return
	if _cursor_hand.get_active_hand_item() == null:
		if _try_pick_surface_item(cursor_pos):
			return
		if _hover_slot and _hover_slot.has_item():
			_perform_slot_interaction(_hover_slot)

func on_pointer_move(cursor_pos: Vector2) -> void:
	_update_hover(cursor_pos)

func on_pointer_up(cursor_pos: Vector2) -> void:
	_update_hover(cursor_pos)
	_log_debug("pointer_up pos=%.1f,%.1f hover=%s hand_item=%s", [
		cursor_pos.x,
		cursor_pos.y,
		_get_hover_slot_id(),
		_get_hand_item_id(),
	])
	_log_click_snapshot("up", cursor_pos)
	if not _drag_active:
		return
	if _cursor_hand and _cursor_hand.get_active_hand_item() != null:
		var held := _cursor_hand.get_active_hand_item()
		if _hover_slot:
			if _is_slot_blocked_for_drop(_hover_slot, held):
				_return_to_origin()
				_drag_active = false
				return
			var exec_result := _perform_slot_interaction(_hover_slot)
			if exec_result and not exec_result.success and _cursor_hand.get_active_hand_item() != null:
				_return_to_origin()
		elif _try_deliver_to_client(cursor_pos):
			pass
		else:
			_return_to_origin()
	_drag_active = false

func update_drag_watchdog() -> void:
	if not _drag_active:
		return
	if not Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT):
		_log_debug("watchdog_cancel hand_item=%s", [_get_hand_item_id()])
		cancel_drag()

func has_active_drag() -> bool:
	if _drag_active or _drag_returning:
		return true
	return _cursor_hand != null and _cursor_hand.get_active_hand_item() != null

func get_dragged_item() -> ItemNode:
	if _cursor_hand == null:
		return null
	return _cursor_hand.get_active_hand_item()

func cancel_drag() -> void:
	_drag_active = false
	_set_hover_slot(null)
	if _cursor_hand:
		_cursor_hand.set_preview_small(false)
	if _cursor_hand and _cursor_hand.get_active_hand_item() != null:
		_return_to_origin()
	_log_debug("cancel_drag hand_item=%s", [_get_hand_item_id()])

func force_cancel_drag() -> void:
	cancel_drag()

func build_interaction_command(slot: WardrobeSlot) -> InteractionCommandScript:
	var slot_id := StringName(slot.get_slot_identifier())
	var slot_item_instance := _storage_state.get_slot_item(slot_id)
	var command: InteractionCommandScript = _interaction_service.build_auto_command(slot_id, slot_item_instance)
	_last_interaction_command = command
	return command

func execute_interaction(command: InteractionCommandScript) -> InteractionResultScript:
	return _interaction_service.execute_command(command)

func apply_interaction_events(events: Array) -> void:
	_event_adapter.emit_events(events)
	var desk_events: Array = _desk_event_dispatcher.process_interaction_events(events)
	_interaction_events.apply_desk_events(desk_events)

func _perform_slot_interaction(slot: WardrobeSlot) -> InteractionResultScript:
	var item_node := slot.get_item()
	if item_node and _validate_pick_callback.is_valid():
		if not _validate_pick_callback.call(StringName(item_node.item_id)):
			if item_node.has_method("play_reject_effect"):
				item_node.play_reject_effect()
			_log_debug("pick rejected by rule item=%s", [item_node.item_id])
			return InteractionResultScript.new(false, StringName("rule_blocked"), String(WardrobeInteractionCommandScript.TYPE_PICK), [], null)

	var command := build_interaction_command(slot)
	var exec_result: InteractionResultScript = execute_interaction(command)
	apply_interaction_events(exec_result.events)
	log_interaction(exec_result, slot)
	_debug_validate_world()
	return exec_result

func log_interaction(result: InteractionResultScript, slot: WardrobeSlot) -> void:
	var action: String = result.action
	if result.success:
		if _last_interaction_command:
			_last_interaction_command.action = _resolve_command_type(action)
		var slot_label := slot.get_slot_identifier()
		var held := _cursor_hand.get_active_hand_item() if _cursor_hand else null
		var item_name := held.item_id if held else (slot.get_item().item_id if slot.get_item() else "none")
		if _interaction_logger:
			_interaction_logger.record_success(action, StringName(slot_label), item_name, _last_interaction_command)
		else:
			print("%s item=%s slot=%s" % [action, item_name, slot_label])
	else:
		var slot_id := StringName(slot.get_slot_identifier())
		if _interaction_logger:
			_interaction_logger.record_reject(result.reason, slot_id, _last_interaction_command)
		else:
			print("NO ACTION reason=%s slot=%s" % [result.reason, slot_id])

func _resolve_command_type(action: String) -> StringName:
	match action:
		PickPutSwapResolverScript.ACTION_PICK:
			return WardrobeInteractionCommandScript.TYPE_PICK
		PickPutSwapResolverScript.ACTION_PUT:
			return WardrobeInteractionCommandScript.TYPE_PUT
		_:
			return WardrobeInteractionCommandScript.TYPE_AUTO

func _try_pick_surface_item(cursor_pos: Vector2) -> bool:
	if _cursor_hand == null:
		return false
	if _cursor_hand.get_active_hand_item() != null:
		return false
	var item := _get_surface_item_at_point(cursor_pos)
	if item == null:
		return false
	
	if _validate_pick_callback.is_valid():
		if not _validate_pick_callback.call(StringName(item.item_id)):
			if item.has_method("play_reject_effect"):
				item.play_reject_effect()
			_log_debug("pick rejected by rule item=%s", [item.item_id])
			return true # Consumed input, even if rejected

	_remove_item_from_surfaces(item)
	item.enter_drag_mode()
	_cursor_hand.hold_item(item)
	var instance := _get_item_instance_for_node(item)
	var instance_id := StringName()
	if instance != null:
		_interaction_service.set_hand_item(instance)
		instance_id = instance.id
	_begin_drag_session(item, null, instance_id)
	_log_debug("pick_surface item=%s pos=%.1f,%.1f", [item.item_id, cursor_pos.x, cursor_pos.y])
	return true

func _try_drop_to_shelf(cursor_pos: Vector2) -> bool:
	if _cursor_hand == null:
		return false
	var item := _cursor_hand.get_active_hand_item()
	if item == null:
		return false
	if item.is_reject_falling():
		return false
	var shelf := _get_shelf_at_point(cursor_pos)
	if shelf == null:
		return false
	if not _can_place_on_shelf(item):
		shelf.log_debug("drop rejected; falling to floor")
		_log_debug("drop_shelf_rejected item=%s pos=%.1f,%.1f", [item.item_id, cursor_pos.x, cursor_pos.y])
		return _try_drop_to_floor(cursor_pos)
	var held := _cursor_hand.take_item_from_hand()
	_remove_item_from_surfaces(held)
	held.set_landing_cause(EventSchema.CAUSE_DROP)
	shelf.place_item(held, cursor_pos)
	held.exit_drag_mode()
	_enqueue_stability_check(held, shelf)
	_log_debug("drop shelf item=%s pos=%.1f,%.1f", [held.item_id, held.global_position.x, held.global_position.y])
	_interaction_service.clear_hand_item()
	return true

func _try_drop_to_floor(cursor_pos: Vector2) -> bool:
	if _cursor_hand == null:
		return false
	var item := _cursor_hand.get_active_hand_item()
	if item == null:
		return false
	var target_floor := _get_target_floor_for_item(item)
	if target_floor == null:
		push_warning("No FloorZone available; drop ignored.")
		_log_debug("drop_floor_missing item=%s pos=%.1f,%.1f", [item.item_id, cursor_pos.x, cursor_pos.y])
		return false
	var floor_y := target_floor.get_surface_collision_y_global()
	item = _cursor_hand.take_item_from_hand()
	_remove_item_from_surfaces(item)
	item.exit_drag_mode()
	item.set_landing_cause(EventSchema.CAUSE_DROP)
	if target_floor.has_method("drop_item_with_fall"):
		target_floor.call("drop_item_with_fall", item, cursor_pos)
	else:
		target_floor.drop_item(item, cursor_pos)
	var mode := ItemNode.FloorTransferMode.FALL_ONLY
	if floor_y < item.get_bottom_y_global():
		mode = ItemNode.FloorTransferMode.RISE_THEN_FALL
	item.start_floor_transfer(floor_y, mode)
	_enqueue_stability_check(item, target_floor)
	_log_debug("drop floor item=%s pos=%.1f,%.1f", [item.item_id, item.global_position.x, item.global_position.y])
	_interaction_service.clear_hand_item()
	return true

func _get_target_floor_for_item(item: ItemNode) -> FloorZoneAdapter:
	if item == null:
		return null
	var item_rect := item.get_collider_aabb_global()
	var item_x := item.global_position.x
	if item_rect.size != Vector2.ZERO:
		item_x = item_rect.position.x + item_rect.size.x * 0.5
	var item_bottom_y := item.get_bottom_y_global()
	if _surface_registry != null:
		var floor_zone = _surface_registry.pick_floor_for_item(item_x, item_bottom_y)
		if floor_zone is FloorZoneAdapter:
			return floor_zone as FloorZoneAdapter
	var candidates: Array[FloorZoneAdapter] = []
	for zone in _floor_zones:
		if zone is FloorZoneAdapter:
			if _is_floor_x_compatible(zone as FloorZoneAdapter, item_x):
				candidates.append(zone as FloorZoneAdapter)
	if candidates.is_empty():
		for zone in _floor_zones:
			if zone is FloorZoneAdapter:
				candidates.append(zone as FloorZoneAdapter)
	var best_below: FloorZoneAdapter = null
	var best_below_delta := INF
	var best_below_name := ""
	for zone in candidates:
		var delta: float = zone.get_surface_collision_y_global() - item_bottom_y
		if delta < 0.0:
			continue
		if delta < best_below_delta or (is_equal_approx(delta, best_below_delta) and String(zone.name) < best_below_name):
			best_below = zone
			best_below_delta = delta
			best_below_name = String(zone.name)
	if best_below != null:
		return best_below
	var best: FloorZoneAdapter = null
	var best_abs_delta := INF
	var best_name := ""
	for zone in candidates:
		var delta: float = abs(zone.get_surface_collision_y_global() - item_bottom_y)
		if delta < best_abs_delta or (is_equal_approx(delta, best_abs_delta) and String(zone.name) < best_name):
			best_abs_delta = delta
			best = zone
			best_name = String(zone.name)
	return best

func _is_floor_x_compatible(zone: FloorZoneAdapter, item_x: float) -> bool:
	if zone == null:
		return false
	var bounds: Rect2 = zone.get_surface_bounds_global()
	if bounds.size == Vector2.ZERO:
		return true
	return item_x >= bounds.position.x and item_x <= bounds.position.x + bounds.size.x

func _get_shelf_at_point(cursor_pos: Vector2) -> ShelfSurfaceAdapter:
	for shelf in _shelf_surfaces:
		if shelf is ShelfSurfaceAdapter and shelf.is_point_inside(cursor_pos):
			return shelf
	return null

func _resolve_floor_pass_through_y(item: ItemNode, floor_zone: FloorZoneAdapter) -> float:
	if item == null or floor_zone == null:
		return INF
	var surface_y := floor_zone.get_surface_collision_y_global()
	var pass_through_y := surface_y
	if pass_through_y <= item.get_bottom_y_global() - PASS_THROUGH_MARGIN_PX:
		return INF
	return pass_through_y

func _get_surface_item_at_point(cursor_pos: Vector2) -> ItemNode:
	var space := _get_world_space_state()
	if space == null:
		return null
	var params := PhysicsPointQueryParameters2D.new()
	params.position = cursor_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = PhysicsLayers.MASK_PICK_QUERY
	var hits := space.intersect_point(params, 32)
	if hits.is_empty():
		return null
	var candidates: Array[ItemNode] = []
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or not (collider is Area2D):
			continue
		var item: ItemNode = (collider as Area2D).get_parent() as ItemNode
		if item == null:
			continue
		if _is_surface_item(item):
			candidates.append(item)
	return _choose_topmost_item(candidates)

func _choose_topmost_item(items: Array) -> ItemNode:
	var best: ItemNode = null
	var best_z: float = -INF
	var best_y: float = -INF
	for item in items:
		if item == null:
			continue
		var z: float = float(item.z_index)
		var y: float = item.global_position.y
		if z > best_z or (is_equal_approx(z, best_z) and y > best_y):
			best = item
			best_z = z
			best_y = y
	return best

func _is_surface_item(item: ItemNode) -> bool:
	if item == null:
		return false
	for shelf in _shelf_surfaces:
		if shelf is ShelfSurfaceAdapter and shelf.contains_item(item):
			return true
	for zone in _floor_zones:
		if zone is FloorZoneAdapter and zone.contains_item(item):
			return true
	return false

func _remove_item_from_surfaces(item: ItemNode) -> void:
	if item == null:
		return
	if item.current_surface != null and is_instance_valid(item.current_surface):
		var surface := item.current_surface
		surface.remove_item(item)
		return
	for shelf in _shelf_surfaces:
		if shelf is ShelfSurfaceAdapter:
			shelf.remove_item(item)
	for zone in _floor_zones:
		if zone is FloorZoneAdapter:
			zone.remove_item(item)

func _get_item_instance_for_node(item: ItemNode) -> ItemInstance:
	if item == null:
		return null
	var item_id := StringName(item.item_id)
	if _find_item_instance.is_valid():
		var found: ItemInstance = _find_item_instance.call(item_id) as ItemInstance
		if found != null:
			return found
	var kind := _item_visuals.resolve_kind_from_item_type(item.item_type)
	var color := _item_visuals.get_item_color(item)
	return ItemInstanceScript.new(item_id, kind, &"", color)

func _get_item_place_flags(item: ItemNode) -> int:
	if item == null:
		return 0
	return WardrobeItemConfigScript.get_place_flags(item.item_type)

func _can_place_on_hook(item: ItemNode) -> bool:
	var place_flags := _get_item_place_flags(item)
	return (place_flags & PlacementTypesScript.PlaceFlags.HANG) != 0

func _can_place_on_shelf(item: ItemNode) -> bool:
	var place_flags := _get_item_place_flags(item)
	return (place_flags & PlacementTypesScript.PlaceFlags.LAY) != 0

func _enqueue_stability_check(item: ItemNode, surface: Node) -> void:
	if _physics_tick == null:
		push_warning("Physics tick adapter missing; stability checks disabled.")
		return
	_physics_tick.enqueue_drop_check(item, surface)

func _log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("DragDrop %s" % format)
		return
	DebugLog.logf("DragDrop " + format, args)

func _is_storage_slot(slot: WardrobeSlot) -> bool:
	if slot == null:
		return false
	if _is_tray_slot(slot):
		return false
	if _is_ticket_rack_slot(slot):
		return false
	return true

func _get_world_space_state() -> PhysicsDirectSpaceState2D:
	if _cursor_hand and _cursor_hand.is_inside_tree():
		return _cursor_hand.get_world_2d().direct_space_state
	return null

func _update_hover(cursor_pos: Vector2) -> void:
	var best_slot: WardrobeSlot = null
	var best_d2 := INF
	var best_id := ""
	for slot in _slots_array:
		var d2 := cursor_pos.distance_squared_to(slot.global_position)
		if d2 < best_d2 - HOVER_TIE_EPSILON:
			best_slot = slot
			best_d2 = d2
			best_id = slot.get_slot_identifier()
			continue
		if abs(d2 - best_d2) <= HOVER_TIE_EPSILON:
			var slot_id := slot.get_slot_identifier()
			if String(slot_id) < String(best_id):
				best_slot = slot
				best_d2 = d2
				best_id = slot_id
	if best_slot != null and best_d2 > HOVER_DISTANCE_SQ:
		best_slot = null
	_set_hover_slot(best_slot)
	_update_preview()

func _set_hover_slot(slot: WardrobeSlot) -> void:
	if _hover_slot == slot:
		return
	_apply_hover(false)
	_hover_slot = slot
	_apply_hover(true)

func _apply_hover(enabled: bool) -> void:
	if _hover_slot == null:
		return
	var sprite := _get_slot_sprite(_hover_slot)
	if sprite == null:
		return
	if enabled:
		_hover_slot_original_modulate = sprite.modulate
		sprite.modulate = HOVER_COLOR
	else:
		sprite.modulate = _hover_slot_original_modulate

func _get_slot_sprite(slot: WardrobeSlot) -> Sprite2D:
	return slot.get_node_or_null("SlotSprite") as Sprite2D

func _update_preview() -> void:
	if _cursor_hand == null:
		return
	if _hover_slot == null:
		_cursor_hand.set_preview_small(false)
		return
	_cursor_hand.set_preview_small(_is_storage_slot(_hover_slot))

func _cache_slots() -> void:
	_slots_array.clear()
	for slot in _slot_lookup.values():
		if slot is WardrobeSlot:
			_slots_array.append(slot)

func _setup_item_visuals(item_scene: PackedScene) -> void:
	if _item_visuals == null:
		return
	_item_visuals.configure(
		item_scene,
		_slot_lookup,
		_item_nodes,
		_spawned_items,
		Callable(self, "_detach_item_node"),
		_find_item_instance
	)

func _setup_interaction_events(desk_by_id: Dictionary) -> void:
	if _interaction_events == null:
		return
	_interaction_events.configure(
		desk_by_id,
		_item_nodes,
		Callable(self, "_detach_item_node"),
		Callable(_item_visuals, "spawn_or_move_item_node"),
		_find_item_instance
	)

func _setup_desk_dispatcher(
	desk_by_id: Dictionary,
	desk_system: DeskServicePointSystem,
	client_queue_state: ClientQueueState,
	clients: Dictionary,
	apply_patience_penalty: Callable
) -> void:
	if _desk_event_dispatcher == null:
		return
	_desk_event_dispatcher.configure(
		desk_by_id,
		desk_system,
		client_queue_state,
		clients,
		_storage_state,
		apply_patience_penalty
	)

func _connect_event_adapter() -> void:
	if _event_adapter == null or _event_connected:
		return
	_event_adapter.item_picked.connect(_on_event_item_picked)
	_event_adapter.item_placed.connect(_on_event_item_placed)
	_event_adapter.action_rejected.connect(_on_event_action_rejected)
	_event_connected = true

func recover_stale_drag() -> void:
	for node in _item_nodes.values():
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_meta(META_ORIGIN_SLOT_ID) and not node.has_meta(META_ORIGIN_POS):
			continue
		var slot_id := StringName(str(node.get_meta(META_ORIGIN_SLOT_ID, "")))
		if slot_id != StringName():
			var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
			if slot != null and not slot.has_item():
				slot.put_item(node)
				var instance := _get_item_instance_for_node(node)
				if instance != null and _storage_state != null and _storage_state.get_slot_item(slot_id) == null:
					_storage_state.put(slot_id, instance)
				_release_origin_reservation_for_slot(slot_id, instance.id if instance != null else StringName())
			node.remove_meta(META_ORIGIN_SLOT_ID)
			node.remove_meta(META_ORIGIN_POS)
		else:
			node.remove_meta(META_ORIGIN_POS)

func _begin_drag_session(item: ItemNode, origin_slot: WardrobeSlot, item_instance_id: StringName) -> void:
	_drag_item_node = item
	_drag_item_instance_id = item_instance_id
	_drag_origin_slot = origin_slot
	_drag_origin_slot_id = StringName(origin_slot.get_slot_identifier()) if origin_slot != null else StringName()
	_drag_origin_pos = item.global_position if item != null else Vector2.ZERO
	_drag_returning = false
	if item != null:
		item.set_meta(META_ORIGIN_SLOT_ID, _drag_origin_slot_id)
		item.set_meta(META_ORIGIN_POS, _drag_origin_pos)
	if origin_slot != null and item_instance_id != StringName():
		origin_slot.reserve(item_instance_id)
		if _desk_system != null:
			_desk_system.reserve_tray_slot(_drag_origin_slot_id, item_instance_id)

func _finalize_drag_after_put(_slot_id: StringName, item_node: ItemNode) -> void:
	if _drag_origin_slot_id == StringName():
		_clear_drag_session()
		return
	_release_origin_reservation()
	if item_node != null:
		item_node.remove_meta(META_ORIGIN_SLOT_ID)
		item_node.remove_meta(META_ORIGIN_POS)
	_clear_drag_session()

func _return_to_origin() -> void:
	if _drag_returning:
		return
	var item := _cursor_hand.get_active_hand_item() if _cursor_hand else null
	if item == null:
		return
	_drag_returning = true
	if _cursor_hand:
		_cursor_hand.take_item_from_hand()
	if item.get_parent() != null and _cursor_hand and item.get_parent() == _cursor_hand:
		var target_parent := _cursor_hand.get_parent()
		if target_parent != null:
			item.reparent(target_parent)
	var anchor := _drag_origin_slot.get_item_anchor() if _drag_origin_slot != null else null
	if anchor == null:
		var temp_anchor := Node2D.new()
		temp_anchor.name = "DragReturnAnchor"
		var anchor_parent: Node = _cursor_hand.get_parent() if _cursor_hand else null
		if anchor_parent == null and item.get_parent() != null:
			anchor_parent = item.get_parent()
		if anchor_parent == null:
			return
		anchor_parent.add_child(temp_anchor)
		temp_anchor.global_position = _drag_origin_pos
		anchor = temp_anchor
	item.return_to_origin(anchor, Callable(self, "_finish_return_to_origin").bind(item, anchor))

func _finish_return_to_origin(item: ItemNode, anchor: Node2D) -> void:
	if anchor != null and anchor.name == "DragReturnAnchor":
		anchor.queue_free()
	if item == null:
		_clear_drag_session()
		return
	if _drag_origin_slot != null:
		_drag_origin_slot.put_item(item)
		if _storage_state != null and _drag_item_instance_id != StringName():
			if _storage_state.get_slot_item(_drag_origin_slot_id) == null:
				var instance: ItemInstance = _interaction_service.get_hand_item()
				if instance != null:
					_storage_state.put(_drag_origin_slot_id, instance)
	_release_origin_reservation()
	item.remove_meta(META_ORIGIN_SLOT_ID)
	item.remove_meta(META_ORIGIN_POS)
	_interaction_service.clear_hand_item()
	_drag_returning = false
	_clear_drag_session()

func _release_origin_reservation() -> void:
	_release_origin_reservation_for_slot(_drag_origin_slot_id, _drag_item_instance_id)

func _release_origin_reservation_for_slot(slot_id: StringName, item_instance_id: StringName) -> void:
	if slot_id == StringName():
		return
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	if slot != null:
		slot.release_reservation()
	if _desk_system != null and item_instance_id != StringName():
		_desk_system.release_tray_slot(slot_id, item_instance_id)

func _clear_drag_session() -> void:
	_drag_item_node = null
	_drag_item_instance_id = StringName()
	_drag_origin_slot = null
	_drag_origin_slot_id = StringName()
	_drag_origin_pos = Vector2.ZERO
	_drag_returning = false

func _is_slot_blocked_for_drop(slot: WardrobeSlot, item: ItemNode) -> bool:
	if slot == null or item == null:
		return true
	if slot.has_reservation() and not slot.is_reserved_by(_drag_item_instance_id):
		return true
	if _is_ticket_rack_slot(slot) and not _is_ticket_item(item):
		if item.has_method("play_reject_effect"):
			item.play_reject_effect()
		return true
	if _is_tray_slot(slot) and slot != _drag_origin_slot:
		if item.has_method("play_reject_effect"):
			item.play_reject_effect()
		return true
	return false

func _is_ticket_rack_slot(slot: WardrobeSlot) -> bool:
	if slot == null:
		return false
	return _ticket_rack_slots.has(slot)

func _is_tray_slot(slot: WardrobeSlot) -> bool:
	if slot == null:
		return false
	if _desk_system == null:
		return _tray_slots.has(slot)
	var slot_id := StringName(slot.get_slot_identifier())
	return _desk_system.is_tray_slot(slot_id)

func _is_ticket_item(item: ItemNode) -> bool:
	if item == null:
		return false
	return item.item_type == ItemNode.ItemType.TICKET

func _try_deliver_to_client(cursor_pos: Vector2) -> bool:
	var drop_zone := _get_drop_zone_at_point(cursor_pos)
	if drop_zone == null:
		return false
	var item_instance: ItemInstance = _interaction_service.get_hand_item()
	if item_instance == null:
		return false
	var events := _desk_event_dispatcher.process_deliver_attempt(drop_zone.service_point_id, item_instance)
	_interaction_events.apply_desk_events(events)
	_apply_deliver_results(events)
	return true

func _apply_deliver_results(events: Array) -> void:
	var accepted := false
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		if event_type == EventSchema.EVENT_DELIVER_RESULT_ACCEPT_CONSUME:
			var item_id := StringName(str(payload.get(EventSchema.PAYLOAD_ITEM_INSTANCE_ID, "")))
			var consume_kind := StringName(str(payload.get(EventSchema.PAYLOAD_CONSUME_KIND, "")))
			_consume_hand_item(item_id, consume_kind)
			accepted = true
		elif event_type == EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN:
			_return_to_origin()
	if accepted:
		_clear_drag_session()

func _consume_hand_item(item_id: StringName, consume_kind: StringName) -> void:
	var node: ItemNode = _item_nodes.get(item_id, null)
	if node == null and _cursor_hand != null:
		node = _cursor_hand.get_active_hand_item()
	if node != null:
		node.remove_meta(META_ORIGIN_SLOT_ID)
		node.remove_meta(META_ORIGIN_POS)
		_detach_item_node(node)
		if _item_nodes.has(item_id):
			_item_nodes.erase(item_id)
		node.queue_free()
	_interaction_service.clear_hand_item()
	if consume_kind == StringName("ticket"):
		_clear_ticket_rack_offset(item_id)
	_release_origin_reservation()
	_clear_drag_session()

func _clear_ticket_rack_offset(ticket_id: StringName) -> void:
	if ticket_id == StringName():
		return
	for rack in _ticket_racks:
		if rack is TicketRackScript:
			rack.clear_ticket_offset(ticket_id)

func _get_drop_zone_at_point(cursor_pos: Vector2) -> ClientDropZoneScript:
	var best_zone: ClientDropZoneScript = null
	var best_d2 := INF
	for zone in _client_drop_zones:
		if zone is ClientDropZoneScript:
			if not zone.is_point_inside(cursor_pos):
				continue
			var d2 := cursor_pos.distance_squared_to(zone.global_position)
			if d2 < best_d2:
				best_d2 = d2
				best_zone = zone
	return best_zone

func _detach_item_node(node: ItemNode) -> void:
	if node == null:
		return
	if _cursor_hand and _cursor_hand.get_active_hand_item() == node:
		_cursor_hand.take_item_from_hand()
	for slot in _slots:
		if slot.get_item() == node:
			var _unused := slot.take_item()
			break

func _instance_from_snapshot(snapshot: Dictionary) -> ItemInstance:
	var id: StringName = snapshot.get("id", StringName())
	var kind: StringName = snapshot.get("kind", ItemInstanceScript.KIND_COAT)
	var color_variant: Variant = snapshot.get("color", Color.WHITE)
	var color := _item_visuals.parse_color(color_variant)
	return ItemInstanceScript.new(id, kind, &"", color)

func _on_event_item_picked(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var node: ItemNode = slot.take_item() if slot else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if node and _cursor_hand:
		node.enter_drag_mode()
		_cursor_hand.hold_item(node)
	var instance := _instance_from_snapshot(item)
	_interaction_service.set_hand_item(instance)
	if node != null:
		_begin_drag_session(node, slot, instance.id)

func _on_event_item_placed(slot_id: StringName, item: Dictionary, _tick: int) -> void:
	var slot: WardrobeSlot = _slot_lookup.get(slot_id, null)
	var hand_before := _cursor_hand.get_active_hand_item() if _cursor_hand else null
	var node: ItemNode = _cursor_hand.take_item_from_hand() if _cursor_hand else null
	var item_id: StringName = item.get("id", StringName())
	if node == null:
		node = _item_nodes.get(item_id, null)
	if slot and node:
		node.freeze = true
		slot.put_item(node)
		_interaction_service.clear_hand_item()
		_finalize_drag_after_put(slot_id, node)
	else:
		_log_put_missing("placed", slot_id, item_id, slot, hand_before, node)

func _on_event_action_rejected(_slot_id: StringName, _reason: StringName, _tick: int) -> void:
	if _cursor_hand and _cursor_hand.get_active_hand_item() != null:
		_return_to_origin()

func _debug_validate_world() -> void:
	if _validate_world.is_valid():
		_validate_world.call()

func _get_hover_slot_id() -> String:
	if _hover_slot == null:
		return "none"
	return String(_hover_slot.get_slot_identifier())

func _get_hand_item_id() -> String:
	if _cursor_hand == null:
		return "none"
	var item := _cursor_hand.get_active_hand_item()
	if item == null:
		return "none"
	return item.item_id

func _log_put_missing(
	context: String,
	slot_id: StringName,
	item_id: StringName,
	slot: WardrobeSlot,
	hand_before: ItemNode,
	node: ItemNode
) -> void:
	if not DebugLog.enabled():
		return
	var reasons: Array[String] = []
	if slot == null:
		reasons.append("missing_slot")
	if node == null:
		reasons.append("missing_node")
	var hand_id := hand_before.item_id if hand_before else "none"
	var node_id := node.item_id if node else "none"
	var slot_has_item := slot.has_item() if slot else false
	DebugLog.logf("PutMissing ctx=%s slot=%s item=%s reasons=%s hand_before=%s node=%s slot_has_item=%s", [
		context,
		String(slot_id),
		String(item_id),
		"|".join(reasons),
		hand_id,
		node_id,
		str(slot_has_item),
	])

func _log_click_snapshot(label: String, cursor_pos: Vector2) -> void:
	if not DebugLog.enabled():
		return
	var hand := _cursor_hand.get_active_hand_item() if _cursor_hand else null
	var parts: Array[String] = []
	var keys := _item_nodes.keys()
	keys.sort()
	for key in keys:
		var node: ItemNode = _item_nodes.get(key, null)
		if node == null:
			continue
		var pos := node.global_position
		var parent_name: String = String(node.get_parent().name) if node.get_parent() else "none"
		var in_hand := _cursor_hand != null and _cursor_hand.get_active_hand_item() == node
		parts.append("%s state=%s pos=%.1f,%.1f parent=%s hand=%s" % [
			node.item_id,
			node.get_debug_state_label(),
			pos.x,
			pos.y,
			parent_name,
			"yes" if in_hand else "no",
		])
	DebugLog.logf("ClickSnapshot %s pos=%.1f,%.1f hover=%s hand=%s items=%s", [
		label,
		cursor_pos.x,
		cursor_pos.y,
		_get_hover_slot_id(),
		hand.item_id if hand else "none",
		"; ".join(parts),
	])
