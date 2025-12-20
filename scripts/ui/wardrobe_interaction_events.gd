extends RefCounted
class_name WardrobeInteractionEventsAdapter

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const WardrobeInteractionEngineScript := preload("res://scripts/app/interaction/interaction_engine.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")

var _desk_states: Array = []
var _desk_by_slot_id: Dictionary = {}
var _desk_by_id: Dictionary = {}
var _desk_system: DeskServicePointSystem
var _client_queue_state: ClientQueueState
var _clients: Dictionary = {}
var _storage_state: WardrobeStorageState
var _item_nodes: Dictionary = {}
var _detach_item_node: Callable
var _spawn_or_move_item_node: Callable
var _find_item_instance: Callable

func configure(
	desk_states: Array,
	desk_by_slot_id: Dictionary,
	desk_by_id: Dictionary,
	desk_system: DeskServicePointSystem,
	client_queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	item_nodes: Dictionary,
	detach_item_node: Callable,
	spawn_or_move_item_node: Callable,
	find_item_instance: Callable
) -> void:
	_desk_states = desk_states
	_desk_by_slot_id = desk_by_slot_id
	_desk_by_id = desk_by_id
	_desk_system = desk_system
	_client_queue_state = client_queue_state
	_clients = clients
	_storage_state = storage_state
	_item_nodes = item_nodes
	_detach_item_node = detach_item_node
	_spawn_or_move_item_node = spawn_or_move_item_node
	_find_item_instance = find_item_instance

func process_desk_events(events: Array) -> void:
	if _desk_states.is_empty():
		return
	for event_data in events:
		var payload: Dictionary = event_data.get(WardrobeInteractionEngineScript.EVENT_KEY_PAYLOAD, {})
		var slot_id: StringName = StringName(str(payload.get(WardrobeInteractionEngineScript.PAYLOAD_SLOT_ID, "")))
		if slot_id == StringName():
			continue
		var desk_state: RefCounted = _desk_by_slot_id.get(slot_id, null)
		if desk_state == null:
			continue
		var desk_events: Array = _desk_system.process_interaction_event(
			desk_state,
			_client_queue_state,
			_clients,
			_storage_state,
			event_data
		)
		apply_desk_events(desk_events)

func apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(DeskServicePointSystemScript.EVENT_KEY_TYPE, StringName())
		var payload: Dictionary = event_data.get(DeskServicePointSystemScript.EVENT_KEY_PAYLOAD, {})
		match event_type:
			DeskServicePointSystemScript.EVENT_DESK_CONSUMED_ITEM:
				_apply_desk_consumed(payload)
			DeskServicePointSystemScript.EVENT_DESK_SPAWNED_ITEM:
				_apply_desk_spawned(payload)
			DeskServicePointSystemScript.EVENT_CLIENT_PHASE_CHANGED:
				_debug_desk_event("client_phase_changed", payload)
			DeskServicePointSystemScript.EVENT_CLIENT_COMPLETED:
				_debug_desk_event("client_completed", payload)
			DeskServicePointSystemScript.EVENT_DESK_REJECTED_DELIVERY:
				_debug_desk_event("desk_rejected_delivery", payload)

func _apply_desk_consumed(payload: Dictionary) -> void:
	var item_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_ITEM_INSTANCE_ID, "")))
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
	var desk_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_DESK_ID, "")))
	var item_id: StringName = StringName(str(payload.get(DeskServicePointSystemScript.PAYLOAD_ITEM_INSTANCE_ID, "")))
	if desk_id == StringName() or item_id == StringName():
		return
	var desk_state: RefCounted = _desk_by_id.get(desk_id, null)
	if desk_state == null:
		return
	if not _find_item_instance.is_valid():
		return
	var instance := _find_item_instance.call(item_id)
	if instance == null:
		return
	if _spawn_or_move_item_node.is_valid():
		_spawn_or_move_item_node.call(desk_state.desk_slot_id, instance)

func _debug_desk_event(label: String, payload: Dictionary) -> void:
	print("DeskEvent %s %s" % [label, payload])
