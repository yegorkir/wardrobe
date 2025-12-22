extends RefCounted
class_name WardrobeWorldSetupAdapter

const WardrobeStep3SetupContextScript := preload("res://scripts/ui/wardrobe_step3_setup_context.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const DeskServicePointScript := preload("res://scripts/wardrobe/desk_service_point.gd")

var _root: Node
var _interaction_service: WardrobeInteractionService
var _storage_state: WardrobeStorageState
var _step3_setup: WardrobeStep3SetupAdapter
var _item_visuals: WardrobeItemVisualsAdapter
var _apply_desk_events: Callable

var _slots: Array[WardrobeSlot] = []
var _slot_lookup: Dictionary = {}
var _spawned_items: Array[ItemNode] = []
var _item_nodes: Dictionary = {}
var _desk_nodes: Array = []
var _desk_states: Array = []
var _desk_by_id: Dictionary = {}
var _desk_by_slot_id: Dictionary = {}
var _clients: Dictionary = {}
var _client_queue_state: ClientQueueState = ClientQueueStateScript.new()
var _desk_system: DeskServicePointSystem = DeskServicePointSystemScript.new()
var _queue_system: ClientQueueSystem = ClientQueueSystemScript.new()

func configure(
	root: Node,
	interaction_service: WardrobeInteractionService,
	storage_state: WardrobeStorageState,
	step3_setup: WardrobeStep3SetupAdapter,
	item_visuals: WardrobeItemVisualsAdapter,
	apply_desk_events: Callable
) -> void:
	_root = root
	_interaction_service = interaction_service
	_storage_state = storage_state
	_step3_setup = step3_setup
	_item_visuals = item_visuals
	_apply_desk_events = apply_desk_events
	_setup_step3_context()

func get_slots() -> Array[WardrobeSlot]:
	return _slots

func get_slot_lookup() -> Dictionary:
	return _slot_lookup

func get_spawned_items() -> Array[ItemNode]:
	return _spawned_items

func get_item_nodes() -> Dictionary:
	return _item_nodes

func get_desk_nodes() -> Array:
	return _desk_nodes

func get_desk_states() -> Array:
	return _desk_states

func get_desk_by_id() -> Dictionary:
	return _desk_by_id

func get_desk_by_slot_id() -> Dictionary:
	return _desk_by_slot_id

func get_clients() -> Dictionary:
	return _clients

func get_client_queue_state() -> ClientQueueState:
	return _client_queue_state

func get_desk_system() -> DeskServicePointSystem:
	return _desk_system

func get_queue_system() -> ClientQueueSystem:
	return _queue_system

func collect_slots() -> void:
	_slots.clear()
	_slot_lookup.clear()
	for node in _root.get_tree().get_nodes_in_group(WardrobeSlot.SLOT_GROUP):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			_slots.append(slot)
			var slot_id := StringName(slot.get_slot_identifier())
			_slot_lookup[slot_id] = slot
	if _slots.is_empty():
		for node in _root.find_children("*", "WardrobeSlot", true, true):
			if node is WardrobeSlot:
				var slot := node as WardrobeSlot
				_slots.append(slot)
				var slot_id := StringName(slot.get_slot_identifier())
				_slot_lookup[slot_id] = slot

func collect_desks() -> void:
	_desk_nodes.clear()
	for node in _root.get_tree().get_nodes_in_group(DeskServicePointScript.DESK_GROUP):
		if node is Node2D and node.has_method("get_slot_id"):
			_desk_nodes.append(node)

func reset_storage_state() -> void:
	_interaction_service.reset_state()
	register_storage_slots()

func register_storage_slots() -> void:
	for slot in _slots:
		_interaction_service.register_slot(StringName(slot.get_slot_identifier()))

func initialize_world() -> void:
	if _step3_setup:
		_step3_setup.initialize_step3()

func reset_world() -> void:
	initialize_world()

func clear_spawned_items() -> void:
	for slot in _slots:
		slot.clear_item(false)
	for item in _spawned_items:
		if is_instance_valid(item):
			item.queue_free()
	_spawned_items.clear()
	_item_nodes.clear()
	_interaction_service.reset_state()
	register_storage_slots()

func get_ticket_slots() -> Array[WardrobeSlot]:
	var ticket_slots: Array[WardrobeSlot] = []
	for slot in _slots:
		var slot_id := slot.get_slot_identifier()
		if slot_id.ends_with("_SlotA"):
			ticket_slots.append(slot)
	return ticket_slots

func place_item_instance_in_slot(slot_id: StringName, instance: ItemInstance) -> void:
	if instance == null:
		return
	if not _storage_state.has_slot(slot_id):
		_interaction_service.register_slot(slot_id)
	if _storage_state.get_slot_item(slot_id) != null:
		return
	var put_result := _storage_state.put(slot_id, instance)
	if not put_result.get(WardrobeStorageStateScript.RESULT_KEY_SUCCESS, false):
		push_warning("Step 3 failed to place item %s in slot %s: %s" % [
			instance.id,
			slot_id,
			put_result.get(WardrobeStorageStateScript.RESULT_KEY_REASON, "unknown"),
		])
		return
	_item_visuals.spawn_or_move_item_node(slot_id, instance)

func find_item_instance(item_id: StringName) -> ItemInstance:
	if item_id == StringName():
		return null
	for client in _clients.values():
		var client_state: RefCounted = client
		if client_state == null:
			continue
		if client_state.get_coat_id() == item_id:
			return client_state.get_coat_item()
		if client_state.get_ticket_id() == item_id:
			return client_state.get_ticket_item()
	return null

func _setup_step3_context() -> void:
	if _step3_setup == null:
		return
	var step3_context := WardrobeStep3SetupContextScript.new()
	step3_context.root = _root
	step3_context.clear_spawned_items = Callable(self, "clear_spawned_items")
	step3_context.collect_desks = Callable(self, "collect_desks")
	step3_context.desk_nodes = _desk_nodes
	step3_context.desk_states = _desk_states
	step3_context.desk_by_id = _desk_by_id
	step3_context.desk_by_slot_id = _desk_by_slot_id
	step3_context.clients = _clients
	step3_context.client_queue_state = _client_queue_state
	step3_context.desk_system = _desk_system
	step3_context.queue_system = _queue_system
	step3_context.storage_state = _storage_state
	step3_context.get_ticket_slots = Callable(self, "get_ticket_slots")
	step3_context.place_item_instance_in_slot = Callable(self, "place_item_instance_in_slot")
	step3_context.apply_desk_events = _apply_desk_events
	_step3_setup.configure(step3_context)
