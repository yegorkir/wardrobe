extends RefCounted
class_name WardrobeStep3SetupAdapter

const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const WardrobeItemConfigScript := preload("res://scripts/ui/wardrobe_item_config.gd")

var _root: Node
var _clear_spawned_items: Callable
var _collect_desks: Callable
var _desk_nodes: Array = []
var _desk_states: Array = []
var _desk_by_id: Dictionary = {}
var _desk_by_slot_id: Dictionary = {}
var _clients: Dictionary = {}
var _client_queue_state: ClientQueueState
var _desk_system: DeskServicePointSystem
var _queue_system: ClientQueueSystem
var _storage_state: WardrobeStorageState
var _get_ticket_slots: Callable
var _place_item_instance_in_slot: Callable
var _apply_desk_events: Callable

func configure(context: RefCounted) -> void:
	_root = context.root
	_clear_spawned_items = context.clear_spawned_items
	_collect_desks = context.collect_desks
	_desk_nodes = context.desk_nodes
	_desk_states = context.desk_states
	_desk_by_id = context.desk_by_id
	_desk_by_slot_id = context.desk_by_slot_id
	_clients = context.clients
	_client_queue_state = context.client_queue_state
	_desk_system = context.desk_system
	_queue_system = context.queue_system
	_storage_state = context.storage_state
	_get_ticket_slots = context.get_ticket_slots
	_place_item_instance_in_slot = context.place_item_instance_in_slot
	_apply_desk_events = context.apply_desk_events

func initialize_step3() -> void:
	if _clear_spawned_items.is_valid():
		_clear_spawned_items.call()
	if _collect_desks.is_valid():
		_collect_desks.call()
	_setup_step3_desks_and_clients()
	_seed_step3_hook_tickets()
	_sync_hook_anchor_tickets_once()

func _setup_step3_desks_and_clients() -> void:
	_reset_desk_state_collections()
	if _desk_nodes.is_empty():
		push_warning("Step 3 desks missing; no service points initialized.")
		return
	_build_desk_states()
	var client_ids := _build_clients()
	_assign_clients_to_desks(client_ids)

func _reset_desk_state_collections() -> void:
	_desk_states.clear()
	_desk_by_id.clear()
	_desk_by_slot_id.clear()
	_clients.clear()
	if _client_queue_state:
		_client_queue_state.clear()

func _build_desk_states() -> void:
	for index in _desk_nodes.size():
		var desk_node: Node = _desk_nodes[index]
		if desk_node == null:
			continue
		var desk_id: StringName = desk_node.desk_id
		var slot_id: StringName = desk_node.get_slot_id()
		var desk_state := DeskStateScript.new(desk_id, slot_id)
		_desk_states.append(desk_state)
		_desk_by_id[desk_state.desk_id] = desk_state
		_desk_by_slot_id[desk_state.desk_slot_id] = desk_state

func _build_clients() -> Array[StringName]:
	var colors: Array[Color] = [
		Color(0.85, 0.35, 0.35),
		Color(0.35, 0.7, 0.45),
		Color(0.35, 0.45, 0.9),
		Color(0.9, 0.75, 0.35),
	]
	var client_ids: Array[StringName] = []
	for i in range(4):
		var client_id := StringName("Client_%d" % i)
		var color: Color = colors[i % colors.size()]
		var client := _make_demo_client(i, client_id, color)
		_clients[client_id] = client
		client_ids.append(client_id)
	return client_ids

func _assign_clients_to_desks(client_ids: Array[StringName]) -> void:
	_queue_system.enqueue_clients(_client_queue_state, client_ids)
	for desk_state in _desk_states:
		var events := _desk_system.assign_next_client_to_desk(
			desk_state,
			_client_queue_state,
			_clients,
			_storage_state
		)
		if _apply_desk_events.is_valid():
			_apply_desk_events.call(events)

func _make_demo_client(index: int, client_id: StringName, color: Color) -> ClientState:
	var item_type := WardrobeItemConfigScript.get_demo_item_type_for_client(index)
	var item_id := WardrobeItemConfigScript.build_client_item_id(item_type, index)
	var item_kind := WardrobeItemConfigScript.get_kind_for_item_type(item_type)
	var coat := ItemInstanceScript.new(
		item_id,
		item_kind,
		color
	)
	var ticket := ItemInstanceScript.new(
		StringName("ticket_%02d" % index),
		ItemInstanceScript.KIND_TICKET,
		color
	)
	return ClientStateScript.new(
		client_id,
		coat,
		ticket,
		StringName(),
		StringName("color_%d" % index)
	)

func _seed_step3_hook_tickets() -> void:
	if not _get_ticket_slots.is_valid():
		return
	var ticket_slots: Array = _get_ticket_slots.call()
	if ticket_slots.is_empty():
		push_warning("Step 3 hooks missing; no ticket slots found.")
		return
	var client_ids: Array = _clients.keys()
	var slot_count: int = min(ticket_slots.size(), client_ids.size())
	for index in range(slot_count):
		var client_id: StringName = StringName(str(client_ids[index]))
		var client: RefCounted = _clients.get(client_id, null)
		if client == null:
			continue
		if _place_item_instance_in_slot.is_valid():
			_place_item_instance_in_slot.call(
				StringName(ticket_slots[index].get_slot_identifier()),
				client.get_ticket_item()
			)

func _sync_hook_anchor_tickets_once() -> void:
	if _root == null:
		return
	for node in _root.find_children("*", "HookItem", true, true):
		if node.has_method("sync_anchor_ticket_color"):
			node.sync_anchor_ticket_color()
