extends RefCounted
class_name WardrobeInteractionEventsAdapter

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const SurfaceRegistryScript := preload("res://scripts/wardrobe/surface/surface_registry.gd")

const UNHANDLED_IGNORE := StringName("ignore")
const UNHANDLED_WARN := StringName("warn")
const UNHANDLED_DEBUG := StringName("debug")

var _desk_by_id: Dictionary = {}
var _item_nodes: Dictionary = {}
var _detach_item_node: Callable
var _spawn_or_move_item_node: Callable
var _find_item_instance: Callable
var _handlers: Dictionary = {}
var _unhandled_policy: StringName = UNHANDLED_WARN

func configure(
	desk_by_id: Dictionary,
	item_nodes: Dictionary,
	detach_item_node: Callable,
	spawn_or_move_item_node: Callable,
	find_item_instance: Callable
) -> void:
	_desk_by_id = desk_by_id
	_item_nodes = item_nodes
	_detach_item_node = detach_item_node
	_spawn_or_move_item_node = spawn_or_move_item_node
	_find_item_instance = find_item_instance
	_setup_handlers()

func set_unhandled_policy(policy: StringName) -> void:
	_unhandled_policy = policy

func apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		var handler: Callable = _handlers.get(event_type, Callable())
		if handler.is_valid():
			handler.call(payload)
		else:
			_handle_unhandled(event_type, payload)

func _setup_handlers() -> void:
	_handlers.clear()
	_handlers[EventSchema.EVENT_DESK_CONSUMED_ITEM] = Callable(self, "_apply_desk_consumed")
	_handlers[EventSchema.EVENT_DESK_SPAWNED_ITEM] = Callable(self, "_apply_desk_spawned")
	_handlers[EventSchema.EVENT_DELIVER_TO_CLIENT_ATTEMPT] = Callable(self, "_log_deliver_attempt")
	_handlers[EventSchema.EVENT_DELIVER_RESULT_ACCEPT_CONSUME] = Callable(self, "_log_deliver_accept")
	_handlers[EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN] = Callable(self, "_log_deliver_reject")
	_handlers[EventSchema.EVENT_CLIENT_PHASE_CHANGED] = Callable(self, "_log_client_phase_changed")
	_handlers[EventSchema.EVENT_CLIENT_COMPLETED] = Callable(self, "_log_client_completed")
	_handlers[EventSchema.EVENT_DESK_REJECTED_DELIVERY] = Callable(self, "_log_desk_rejected_delivery")
	_handlers[EventSchema.EVENT_ITEM_DROPPED] = Callable(self, "_apply_item_dropped")

func _apply_desk_consumed(payload: Dictionary) -> void:
	var item_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_ITEM_INSTANCE_ID, "")))
	if item_id == StringName():
		return
	var node: ItemNode = _item_nodes.get(item_id, null)
	if node == null:
		return
	if _detach_item_node.is_valid():
		_detach_item_node.call(node)
	_item_nodes.erase(item_id)
	node.queue_free()

func _apply_desk_spawned(payload: Dictionary) -> void:
	var desk_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_DESK_ID, "")))
	var item_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_ITEM_INSTANCE_ID, "")))
	var slot_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_SLOT_ID, "")))
	if item_id == StringName():
		return
	var desk_state: RefCounted = _desk_by_id.get(desk_id, null)
	if desk_state == null and slot_id == StringName():
		return
	if not _find_item_instance.is_valid():
		return
	var instance: ItemInstance = _find_item_instance.call(item_id) as ItemInstance
	if instance == null:
		return
	if _spawn_or_move_item_node.is_valid():
		var target_slot := slot_id
		if target_slot == StringName() and desk_state != null:
			target_slot = desk_state.desk_slot_id
		_spawn_or_move_item_node.call(target_slot, instance)

func _log_client_phase_changed(payload: Dictionary) -> void:
	_debug_desk_event("client_phase_changed", payload)

func _log_client_completed(payload: Dictionary) -> void:
	_debug_desk_event("client_completed", payload)

func _log_desk_rejected_delivery(payload: Dictionary) -> void:
	_debug_desk_event("desk_rejected_delivery", payload)

func _log_deliver_attempt(payload: Dictionary) -> void:
	_debug_desk_event("deliver_attempt", payload)

func _log_deliver_accept(payload: Dictionary) -> void:
	_debug_desk_event("deliver_accept", payload)

func _log_deliver_reject(payload: Dictionary) -> void:
	_debug_desk_event("deliver_reject", payload)

func _apply_item_dropped(payload: Dictionary) -> void:
	var item_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_ITEM_INSTANCE_ID, "")))
	var floor_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_TO, "")))
	if item_id == StringName() or floor_id == StringName():
		return
	var node: ItemNode = _item_nodes.get(item_id, null)
	if node == null:
		return
	if _detach_item_node.is_valid():
		_detach_item_node.call(node)
	var registry := SurfaceRegistryScript.get_autoload()
	if registry != null:
		registry.remove_item_from_all(node)
	var floor_node := _resolve_floor_by_id(floor_id)
	if floor_node == null:
		push_warning("Floor zone %s not found; item drop skipped." % floor_id)
		return
	var drop_pos := node.global_position
	node.set_landing_cause(EventSchema.CAUSE_REJECT)
	if floor_node.has_method("drop_item_with_fall"):
		floor_node.call("drop_item_with_fall", node, drop_pos)
	else:
		floor_node.call("drop_item", node, drop_pos)
	var floor_y := float(floor_node.call("get_surface_collision_y_global"))
	var mode := ItemNode.FloorTransferMode.FALL_ONLY
	if floor_y < node.get_bottom_y_global():
		mode = ItemNode.FloorTransferMode.RISE_THEN_FALL
	node.start_floor_transfer(floor_y, mode)

func _resolve_floor_by_id(floor_id: StringName) -> Node:
	var registry := SurfaceRegistryScript.get_autoload()
	if registry == null:
		return null
	for floor_node in registry.get_floors():
		if floor_node == null:
			continue
		if StringName(String(floor_node.name)) == floor_id:
			return floor_node
	return null

func _handle_unhandled(event_type: StringName, payload: Dictionary) -> void:
	if _unhandled_policy == UNHANDLED_IGNORE:
		return
	if _unhandled_policy == UNHANDLED_DEBUG:
		_debug_desk_event("unhandled:%s" % event_type, payload)
		return
	push_warning("Unhandled desk event %s payload=%s" % [event_type, payload])

func _debug_desk_event(label: String, payload: Dictionary) -> void:
	print("DeskEvent %s %s" % [label, payload])
