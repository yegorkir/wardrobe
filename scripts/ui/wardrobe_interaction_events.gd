extends RefCounted
class_name WardrobeInteractionEventsAdapter

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

var _desk_by_id: Dictionary = {}
var _item_nodes: Dictionary = {}
var _detach_item_node: Callable
var _spawn_or_move_item_node: Callable
var _find_item_instance: Callable

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

func apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		match event_type:
			EventSchema.EVENT_DESK_CONSUMED_ITEM:
				_apply_desk_consumed(payload)
			EventSchema.EVENT_DESK_SPAWNED_ITEM:
				_apply_desk_spawned(payload)
			EventSchema.EVENT_CLIENT_PHASE_CHANGED:
				_debug_desk_event("client_phase_changed", payload)
			EventSchema.EVENT_CLIENT_COMPLETED:
				_debug_desk_event("client_completed", payload)
			EventSchema.EVENT_DESK_REJECTED_DELIVERY:
				_debug_desk_event("desk_rejected_delivery", payload)

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
	if desk_id == StringName() or item_id == StringName():
		return
	var desk_state: RefCounted = _desk_by_id.get(desk_id, null)
	if desk_state == null:
		return
	if not _find_item_instance.is_valid():
		return
	var instance: ItemInstance = _find_item_instance.call(item_id) as ItemInstance
	if instance == null:
		return
	if _spawn_or_move_item_node.is_valid():
		_spawn_or_move_item_node.call(desk_state.desk_slot_id, instance)

func _debug_desk_event(label: String, payload: Dictionary) -> void:
	print("DeskEvent %s %s" % [label, payload])
