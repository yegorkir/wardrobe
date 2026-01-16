extends RefCounted
class_name WardrobeWorldSetupAdapter

const WardrobeStep3SetupContextScript := preload("res://scripts/ui/wardrobe_step3_setup_context.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const DeskServicePointScript := preload("res://scripts/wardrobe/desk_service_point.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

var _root: Node
var _interaction_service: WardrobeInteractionService
var _storage_state: WardrobeStorageState
var _step3_setup: WardrobeStep3SetupAdapter
var _item_visuals: WardrobeItemVisualsAdapter
var _apply_desk_events: Callable
var _register_item: Callable

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
var _ticket_rack_slots: Array[WardrobeSlot] = []
var _ticket_racks: Array = []
var _tray_slots: Array[WardrobeSlot] = []
var _client_drop_zones: Array = []
var _item_registry: Dictionary = {}

func configure(
	root: Node,
	interaction_service: WardrobeInteractionService,
	storage_state: WardrobeStorageState,
	step3_setup: WardrobeStep3SetupAdapter,
	item_visuals: WardrobeItemVisualsAdapter,
	apply_desk_events: Callable,
	register_item: Callable = Callable()
) -> void:
	_root = root
	_interaction_service = interaction_service
	_storage_state = storage_state
	_step3_setup = step3_setup
	_item_visuals = item_visuals
	_apply_desk_events = apply_desk_events
	_register_item = register_item
	_desk_system.set_queue_system(_queue_system)
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

func get_ticket_rack_slots() -> Array[WardrobeSlot]:
	return _ticket_rack_slots

func get_ticket_racks() -> Array:
	return _ticket_racks

func get_cabinet_ticket_slots() -> Array[WardrobeSlot]:
	var grid := _root.get_node_or_null("StorageHall/CabinetsGrid")
	if grid != null and grid.has_method("get_ticket_slots"):
		var slots: Array = grid.call("get_ticket_slots")
		var filtered: Array[WardrobeSlot] = []
		for entry in slots:
			if entry is WardrobeSlot:
				filtered.append(entry)
		if not filtered.is_empty():
			return filtered
	var cabinet_slots: Array[WardrobeSlot] = []
	for slot in _slots:
		if slot == null:
			continue
		var slot_id := String(slot.get_slot_identifier())
		if slot_id.is_empty():
			continue
		if not slot_id.begins_with("Cab_"):
			continue
		if not (slot_id.ends_with("_SlotA") or slot_id.ends_with("_SlotB")):
			continue
		cabinet_slots.append(slot)
	return cabinet_slots

func get_tray_slots() -> Array[WardrobeSlot]:
	return _tray_slots

func get_client_drop_zones() -> Array:
	return _client_drop_zones

func collect_slots() -> void:
	_slots.clear()
	_slot_lookup.clear()
	if DebugLog.enabled():
		DebugLog.log("Storage collect_slots begin")
	if _desk_nodes.is_empty():
		collect_desks()
	for node in _root.get_tree().get_nodes_in_group(WardrobeSlot.SLOT_GROUP):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			_slots.append(slot)
			var slot_id := StringName(slot.get_slot_identifier())
			_slot_lookup[slot_id] = slot
	if DebugLog.enabled():
		DebugLog.logf("Storage collect_slots group_count=%d", [_slots.size()])
	if _slots.is_empty():
		for node in _root.find_children("*", "WardrobeSlot", true, true):
			if node is WardrobeSlot:
				var slot := node as WardrobeSlot
				_slots.append(slot)
				var slot_id := StringName(slot.get_slot_identifier())
				_slot_lookup[slot_id] = slot
		if DebugLog.enabled():
			DebugLog.logf("Storage collect_slots fallback_count=%d", [_slots.size()])
	_collect_service_point_layouts()
	if DebugLog.enabled():
		DebugLog.logf("Storage collect_slots tray_count=%d", [_tray_slots.size()])
	for tray_slot in _tray_slots:
		if tray_slot == null:
			continue
		var tray_id := StringName(tray_slot.get_slot_identifier())
		if tray_id == StringName():
			continue
		if _slot_lookup.has(tray_id):
			continue
		_slots.append(tray_slot)
		_slot_lookup[tray_id] = tray_slot
	_collect_ticket_rack_slots()
	if DebugLog.enabled():
		var sample_ids: Array = []
		for slot in _slots:
			if slot == null:
				continue
			if sample_ids.size() >= 10:
				break
			sample_ids.append(StringName(slot.get_slot_identifier()))
		DebugLog.logf("Storage collect_slots sample=%s", [sample_ids])

func _collect_ticket_rack_slots() -> void:
	_ticket_rack_slots.clear()
	_ticket_racks.clear()
	for node in _root.get_tree().get_nodes_in_group("ticket_rack"):
		if node == null:
			continue
		if not _ticket_racks.has(node):
			_ticket_racks.append(node)
		if node.has_method("get_slots"):
			var slots: Array = node.call("get_slots")
			for slot_entry in slots:
				if slot_entry is WardrobeSlot and not _ticket_rack_slots.has(slot_entry):
					_ticket_rack_slots.append(slot_entry)
	if _ticket_racks.is_empty():
		for node in _root.find_children("TicketRackController", "", true, false):
			if node == null or _ticket_racks.has(node):
				continue
			_ticket_racks.append(node)
			if node.has_method("get_slots"):
				var slots: Array = node.call("get_slots")
				for slot_entry in slots:
					if slot_entry is WardrobeSlot and not _ticket_rack_slots.has(slot_entry):
						_ticket_rack_slots.append(slot_entry)
	if _ticket_rack_slots.is_empty():
		for node in _root.find_children("TicketRack_*", "", true, false):
			if node is WardrobeSlot and not _ticket_rack_slots.has(node):
				_ticket_rack_slots.append(node)

func collect_desks() -> void:
	_desk_nodes.clear()
	for node in _root.get_tree().get_nodes_in_group(DeskServicePointScript.DESK_GROUP):
		if node is Node2D and node.has_method("get_slot_id"):
			_desk_nodes.append(node)
	if DebugLog.enabled():
		DebugLog.logf("Desk collect_desks count=%d", [_desk_nodes.size()])
	_collect_service_point_layouts()

func _collect_service_point_layouts() -> void:
	_tray_slots.clear()
	_client_drop_zones.clear()
	if DebugLog.enabled():
		DebugLog.logf("Desk collect_layouts desks=%d", [_desk_nodes.size()])
	for desk_node in _desk_nodes:
		if desk_node == null:
			continue
		if desk_node.has_method("get_tray_slots"):
			var tray_slots: Array = desk_node.get_tray_slots()
			for entry in tray_slots:
				if entry is WardrobeSlot and not _tray_slots.has(entry):
					_tray_slots.append(entry)
		if desk_node.has_method("get_drop_zone"):
			var drop_zone = desk_node.get_drop_zone()
			if drop_zone != null and not _client_drop_zones.has(drop_zone):
				_client_drop_zones.append(drop_zone)
		if desk_node.has_method("get_tray_slot_ids"):
			var tray_ids: Array = desk_node.get_tray_slot_ids()
			_desk_system.register_tray_slots(desk_node.desk_id, tray_ids)
			if DebugLog.enabled():
				DebugLog.logf("DeskTray world_register desk=%s tray_ids=%s", [
					String(desk_node.desk_id),
					tray_ids,
				])

func reset_storage_state() -> void:
	_interaction_service.reset_state()
	register_storage_slots()

func register_storage_slots() -> void:
	if DebugLog.enabled():
		DebugLog.logf("Storage register_slots total=%d", [_slots.size()])
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
	_item_registry.clear()
	_interaction_service.reset_state()
	register_storage_slots()

func get_ticket_slots() -> Array[WardrobeSlot]:
	return _ticket_rack_slots

func place_item_instance_in_slot(slot_id: StringName, instance: ItemInstance) -> void:
	if instance == null:
		return
	register_item_instance(instance)
	if not _storage_state.has_slot(slot_id):
		_interaction_service.register_slot(slot_id)
	if _storage_state.get_slot_item(slot_id) != null:
		return
	var put_result := _storage_state.put(slot_id, instance)
	if not put_result.success:
		push_warning("Step 3 failed to place item %s in slot %s: %s" % [
			instance.id,
			slot_id,
			put_result.reason,
		])
		return
	_item_visuals.spawn_or_move_item_node(slot_id, instance)

func register_item_instance(instance: ItemInstance) -> void:
	if instance == null:
		return
	_item_registry[instance.id] = instance
	if _register_item.is_valid():
		_register_item.call(instance)

func find_item_instance(item_id: StringName) -> ItemInstance:
	if item_id == StringName():
		return null
	if _item_registry.has(item_id):
		return _item_registry.get(item_id, null) as ItemInstance
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
	step3_context.get_cabinet_ticket_slots = Callable(self, "get_cabinet_ticket_slots")
	step3_context.place_item_instance_in_slot = Callable(self, "place_item_instance_in_slot")
	step3_context.apply_desk_events = _apply_desk_events
	step3_context.register_item = Callable(self, "register_item_instance")
	_step3_setup.configure(step3_context)
	
