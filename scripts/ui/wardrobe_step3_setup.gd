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
const ContentDBBaseScript := preload("res://scripts/autoload/bases/content_db_base.gd")
const DEFAULT_CLIENT_COUNT := 4
const DEFAULT_TARGET_CHECKIN := 6
const DEFAULT_TARGET_CHECKOUT := 4

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
var _get_cabinet_ticket_slots: Callable
var _place_item_instance_in_slot: Callable
var _apply_desk_events: Callable
var _register_item: Callable
var _wave_client_defs: Array[StringName] = []
var _wave_client_count: int = DEFAULT_CLIENT_COUNT
var _wave_target_checkin: int = DEFAULT_TARGET_CHECKIN
var _wave_target_checkout: int = DEFAULT_TARGET_CHECKOUT

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
	_get_cabinet_ticket_slots = context.get_cabinet_ticket_slots
	_place_item_instance_in_slot = context.place_item_instance_in_slot
	_apply_desk_events = context.apply_desk_events
	_register_item = context.register_item

func initialize_step3() -> void:
	if _clear_spawned_items.is_valid():
		_clear_spawned_items.call()
	if _collect_desks.is_valid():
		_collect_desks.call()
	_apply_wave_settings()
	_setup_step3_desks_and_clients()
	_seed_cabinet_tickets()
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
	var client_count := _wave_client_count
	for i in range(client_count):
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

	var client_def_id := _resolve_client_def_id(index)
	var client_def := _resolve_client_definition(client_def_id)
	var client_archetype_id: StringName = client_def.get("archetype_id", StringName())
	var portrait_key: StringName = client_def.get("portrait_key", StringName())
	var wrong_item_penalty: float = float(client_def.get("wrong_item_penalty", 0.0))

	var item_archetype_id := StringName()
	# Simple mapping for iteration 7
	if client_archetype_id == "vampire" or client_archetype_id == "client_vampire":
		item_archetype_id = "vampire_cloak"
	elif client_archetype_id == "zombie" or client_archetype_id == "client_zombie":
		item_archetype_id = "zombie_rag"
	elif client_archetype_id == "ghost" or client_archetype_id == "client_ghost":
		item_archetype_id = "ghost_sheet"

	var coat := ItemInstanceScript.new(
		item_id,
		item_kind,
		item_archetype_id,
		color
	)
	if _register_item.is_valid():
		_register_item.call(coat)
		
	return ClientStateScript.new(
		client_id,
		coat,
		null,
		StringName(),
		StringName("color_%d" % index),
		client_archetype_id,
		wrong_item_penalty,
		client_def_id,
		portrait_key
	)

func _resolve_client_def_id(index: int) -> StringName:
	if _wave_client_defs.is_empty():
		return StringName("client_human")
	return _wave_client_defs[index % _wave_client_defs.size()]

func _resolve_client_definition(client_def_id: StringName) -> Dictionary:
	if _root == null:
		return {
			"archetype_id": StringName("human"),
			"portrait_key": StringName(),
			"wrong_item_penalty": 0.0,
		}
	var content_db := _root.get_node_or_null("/root/ContentDB") as ContentDBBaseScript
	if content_db == null:
		return {
			"archetype_id": StringName("human"),
			"portrait_key": StringName(),
			"wrong_item_penalty": 0.0,
		}
	var client_def := content_db.get_client(String(client_def_id))
	var client_payload: Dictionary = client_def.get("payload", {})
	var archetype_id := StringName(str(client_payload.get("archetype_id", "human")))
	var portrait_key := StringName(str(client_payload.get("portrait_key", "")))
	var penalty: float = float(client_payload.get("wrong_item_patience_penalty", 0.0))
	return {
		"archetype_id": archetype_id,
		"portrait_key": portrait_key,
		"wrong_item_penalty": penalty,
	}

func get_shift_targets() -> Dictionary:
	return {
		"target_checkin": _wave_target_checkin,
		"target_checkout": _wave_target_checkout,
	}

func _apply_wave_settings() -> void:
	var settings := _load_wave_settings()
	var clients_value: Variant = settings.get("clients", [])
	if clients_value is Array:
		_wave_client_defs = clients_value as Array[StringName]
	else:
		_wave_client_defs = []
	_wave_client_count = max(0, int(settings.get("client_count", DEFAULT_CLIENT_COUNT)))
	_wave_target_checkin = max(0, int(settings.get("target_checkin", DEFAULT_TARGET_CHECKIN)))
	_wave_target_checkout = max(0, int(settings.get("target_checkout", DEFAULT_TARGET_CHECKOUT)))

func _load_wave_settings() -> Dictionary:
	if _root == null:
		return {}
	var content_db := _root.get_node_or_null("/root/ContentDB") as ContentDBBaseScript
	if content_db == null:
		return {}
	var wave := content_db.get_wave("wave_1")
	var wave_payload: Dictionary = wave.get("payload", {})
	var wave_clients: Variant = wave_payload.get("clients", [])
	if wave_clients is Array:
		var result: Array[StringName] = []
		for entry in wave_clients:
			result.append(StringName(str(entry)))
		return {
			"clients": result,
			"client_count": int(wave_payload.get("client_count", DEFAULT_CLIENT_COUNT)),
			"target_checkin": int(wave_payload.get("target_checkin", DEFAULT_TARGET_CHECKIN)),
			"target_checkout": int(wave_payload.get("target_checkout", DEFAULT_TARGET_CHECKOUT)),
		}
	return {
		"clients": [],
		"client_count": int(wave_payload.get("client_count", DEFAULT_CLIENT_COUNT)),
		"target_checkin": int(wave_payload.get("target_checkin", DEFAULT_TARGET_CHECKIN)),
		"target_checkout": int(wave_payload.get("target_checkout", DEFAULT_TARGET_CHECKOUT)),
	}

func _seed_cabinet_tickets() -> void:
	if not _get_cabinet_ticket_slots.is_valid():
		return
	var cabinet_slots: Array = _get_cabinet_ticket_slots.call()
	if cabinet_slots.is_empty():
		push_warning("Step 3 cabinet ticket slots missing; no cabinet slots found.")
		return
	var colors: Array[Color] = [
		Color(0.85, 0.35, 0.35),
		Color(0.35, 0.7, 0.45),
		Color(0.35, 0.45, 0.9),
		Color(0.9, 0.75, 0.35),
		Color(0.75, 0.35, 0.85),
		Color(0.35, 0.85, 0.8),
		Color(0.85, 0.6, 0.35),
	]
	var slot_count: int = cabinet_slots.size()
	for index in range(slot_count):
		var color := colors[index % colors.size()]
		var ticket := ItemInstanceScript.new(
			StringName("ticket_cabinet_%02d" % index),
			ItemInstanceScript.KIND_TICKET,
			StringName(),
			color
		)
		if _place_item_instance_in_slot.is_valid():
			_place_item_instance_in_slot.call(
				StringName(cabinet_slots[index].get_slot_identifier()),
				ticket
			)

func _sync_hook_anchor_tickets_once() -> void:
	if _root == null:
		return
	for node in _root.find_children("*", "HookItem", true, true):
		if node.has_method("sync_anchor_ticket_color"):
			node.sync_anchor_ticket_color()
