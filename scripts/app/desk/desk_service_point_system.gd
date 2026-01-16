extends RefCounted

class_name DeskServicePointSystem

const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const DeskRejectConsequencePolicyScript := preload("res://scripts/app/desk/reject_consequence_policy.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

const ITEMS_PER_CLIENT := 1
const CONSUME_KIND_TICKET := StringName("ticket")
const CONSUME_KIND_ITEM := StringName("item")

var _queue_system: ClientQueueSystem = ClientQueueSystemScript.new()
var _queue_mix_provider: Callable
var _drop_zone_blocker: Callable
var _tray_slots_by_desk_id: Dictionary = {}
var _tray_slot_to_desk_id: Dictionary = {}
var _reserved_tray_slots: Dictionary = {}
var _reject_policy := DeskRejectConsequencePolicyScript.new()

func set_queue_system(queue_system: ClientQueueSystem) -> void:
	if queue_system == null:
		return
	_queue_system = queue_system

func configure_drop_zone_blocker(provider: Callable) -> void:
	_drop_zone_blocker = provider

func configure_queue_mix_provider(provider: Callable) -> void:
	_queue_mix_provider = provider

func configure_queue_system(config: Dictionary, seed_value: int) -> void:
	_queue_system.configure(config, seed_value)

func register_tray_slots(desk_id: StringName, slot_ids: Array) -> void:
	if desk_id == StringName():
		return
	var clean_ids: Array[StringName] = []
	for entry in slot_ids:
		var slot_id := StringName(str(entry))
		if slot_id == StringName():
			continue
		clean_ids.append(slot_id)
		_tray_slot_to_desk_id[slot_id] = desk_id
	_tray_slots_by_desk_id[desk_id] = clean_ids
	if DebugLog.enabled():
		DebugLog.logf("DeskTray register desk=%s slots=%s", [String(desk_id), clean_ids])

func reserve_tray_slot(slot_id: StringName, item_instance_id: StringName) -> void:
	if slot_id == StringName() or item_instance_id == StringName():
		return
	if not _tray_slot_to_desk_id.has(slot_id):
		return
	_reserved_tray_slots[slot_id] = item_instance_id

func release_tray_slot(slot_id: StringName, item_instance_id: StringName) -> void:
	if not _reserved_tray_slots.has(slot_id):
		return
	var reserved_id := StringName(str(_reserved_tray_slots.get(slot_id, "")))
	if item_instance_id != StringName() and reserved_id != item_instance_id:
		return
	_reserved_tray_slots.erase(slot_id)

func is_tray_slot(slot_id: StringName) -> bool:
	return _tray_slot_to_desk_id.has(slot_id)

func get_desk_id_for_tray_slot(slot_id: StringName) -> StringName:
	if not _tray_slot_to_desk_id.has(slot_id):
		return StringName()
	return StringName(str(_tray_slot_to_desk_id.get(slot_id, "")))

func assign_next_client_to_desk(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState
) -> Array:
	return _assign_next_client_to_desk(desk_state, queue_state, clients, storage_state)

func process_deliver_attempt(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	item_instance: ItemInstance
) -> Array:
	if desk_state == null or item_instance == null:
		return []
	var events: Array = []
	events.append(_make_event(EventSchema.EVENT_DELIVER_TO_CLIENT_ATTEMPT, {
		EventSchema.PAYLOAD_SERVICE_POINT_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item_instance.id,
	}))
	var current_client := _get_current_client(desk_state, clients)
	if current_client == null:
		events.append(_make_deliver_reject_event(desk_state, null, item_instance, EventSchema.REASON_CLIENT_AWAY))
		return events
	if current_client.presence == ClientStateScript.PRESENCE_AWAY:
		events.append(_make_deliver_reject_event(desk_state, current_client, item_instance, EventSchema.REASON_CLIENT_AWAY))
		return events
	if item_instance.kind == ItemInstanceScript.KIND_TICKET:
		return _handle_ticket_delivery(desk_state, queue_state, clients, storage_state, current_client, item_instance, events)
	return _handle_item_delivery(desk_state, queue_state, clients, storage_state, current_client, item_instance, events)

func _assign_next_client_to_desk(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState
) -> Array:
	if desk_state == null:
		return []
	desk_state.current_client_id = StringName()
	if _has_tray_items(desk_state, storage_state):
		if DebugLog.enabled():
			DebugLog.logf("DeskAssign blocked desk=%s reason=tray_items", [String(desk_state.desk_id)])
		return []
	if _drop_zone_blocker != null and _drop_zone_blocker.is_valid():
		if DebugLog.enabled():
			DebugLog.logf("DeskAssign drop_zone_check desk=%s", [String(desk_state.desk_id)])
		if bool(_drop_zone_blocker.call(desk_state.desk_id)):
			if DebugLog.enabled():
				DebugLog.logf("DeskAssign blocked desk=%s reason=drop_zone_items", [String(desk_state.desk_id)])
			return []
	if queue_state == null:
		return []
	var mix_snapshot: Dictionary = {}
	if _queue_mix_provider != null and _queue_mix_provider.is_valid():
		mix_snapshot = _queue_mix_provider.call()
	var attempts := queue_state.get_count()
	var tray_full := not _has_tray_capacity(desk_state, storage_state)
	for _step in range(attempts):
		var next_client_id := StringName()
		if tray_full:
			next_client_id = queue_state.pop_next_checkout()
			if next_client_id.is_empty():
				next_client_id = queue_state.pop_next_checkin()
		else:
			next_client_id = _queue_system.take_next_waiting_client(queue_state, mix_snapshot)
		if next_client_id.is_empty():
			return []
		var next_client := _get_client(clients, next_client_id)
		if next_client == null or next_client.phase == ClientStateScript.PHASE_DONE:
			continue
		if next_client.phase == ClientStateScript.PHASE_DROP_OFF and not _has_tray_capacity(desk_state, storage_state):
			queue_state.enqueue_checkin(next_client_id)
			continue
		desk_state.current_client_id = next_client_id
		next_client.set_assigned_service_point(desk_state.desk_id)
		if next_client.phase == ClientStateScript.PHASE_DROP_OFF:
			return _spawn_tray_items(desk_state, storage_state, next_client)
		return []
	return []

func _has_tray_items(desk_state: DeskState, storage_state: WardrobeStorageState) -> bool:
	if desk_state == null or storage_state == null:
		return false
	var tray_slots: Array = _tray_slots_by_desk_id.get(desk_state.desk_id, [])
	for slot_id_raw in tray_slots:
		var slot_id := StringName(str(slot_id_raw))
		if slot_id == StringName():
			continue
		if storage_state.get_slot_item(slot_id) != null:
			return true
	return false

func _handle_ticket_delivery(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	current_client: ClientState,
	item_instance: ItemInstance,
	events: Array
) -> Array:
	if current_client.phase != ClientStateScript.PHASE_DROP_OFF:
		events.append(_make_deliver_reject_event(desk_state, current_client, item_instance, EventSchema.REASON_WRONG_ITEM))
		return events
	if not _is_ticket_free(item_instance, clients):
		events.append(_make_deliver_reject_event(desk_state, current_client, item_instance, EventSchema.REASON_WRONG_ITEM))
		return events
	current_client.assign_ticket_item(item_instance)
	var previous_phase := current_client.phase
	current_client.set_phase(ClientStateScript.PHASE_PICK_UP)
	current_client.set_presence(ClientStateScript.PRESENCE_AWAY)
	current_client.set_assigned_service_point(StringName())
	if desk_state != null:
		desk_state.current_client_id = StringName()
	_queue_system.requeue_after_dropoff(queue_state, current_client.client_id)
	events.append(_make_deliver_accept_event(desk_state, current_client, item_instance, CONSUME_KIND_TICKET))
	events.append(_make_phase_change_event(current_client, previous_phase))
	events.append_array(_assign_next_client_to_desk(desk_state, queue_state, clients, storage_state))
	return events

func _handle_item_delivery(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	current_client: ClientState,
	item_instance: ItemInstance,
	events: Array
) -> Array:
	if current_client.phase != ClientStateScript.PHASE_PICK_UP:
		events.append(_make_deliver_reject_event(desk_state, current_client, item_instance, EventSchema.REASON_WRONG_ITEM))
		return events
	if item_instance.id != current_client.get_coat_id():
		events.append(_make_deliver_reject_event(desk_state, current_client, item_instance, EventSchema.REASON_WRONG_ITEM))
		return events
	var previous_phase := current_client.phase
	current_client.set_phase(ClientStateScript.PHASE_DONE)
	_queue_system.remove_client(queue_state, current_client.client_id)
	events.append(_make_deliver_accept_event(desk_state, current_client, item_instance, CONSUME_KIND_ITEM))
	events.append(_make_phase_change_event(current_client, previous_phase))
	events.append(_make_event(EventSchema.EVENT_CLIENT_COMPLETED, {
		EventSchema.PAYLOAD_CLIENT_ID: current_client.client_id,
	}))
	events.append_array(_assign_next_client_to_desk(desk_state, queue_state, clients, storage_state))
	return events

func _spawn_tray_items(
	desk_state: DeskState,
	storage_state: WardrobeStorageState,
	client: ClientState
) -> Array:
	if storage_state == null or client == null:
		return []
	var tray_slots: Array = _tray_slots_by_desk_id.get(desk_state.desk_id, [])
	if tray_slots.is_empty():
		if DebugLog.enabled():
			DebugLog.logf("DeskTray spawn_skip desk=%s reason=no_tray_slots", [String(desk_state.desk_id)])
		return []
	var events: Array = []
	var items: Array[ItemInstance] = []
	var coat := client.get_coat_item()
	if coat != null:
		items.append(coat)
	var free_slots := _get_free_tray_slots(tray_slots, storage_state)
	if DebugLog.enabled():
		DebugLog.logf(
			"DeskTray spawn_attempt desk=%s client=%s items=%d free_slots=%s",
			[String(desk_state.desk_id), String(client.client_id), items.size(), free_slots]
		)
	if free_slots.size() < ITEMS_PER_CLIENT:
		if DebugLog.enabled():
			DebugLog.logf("DeskTray spawn_skip desk=%s reason=no_free_slots", [String(desk_state.desk_id)])
		return []
	for i in range(min(ITEMS_PER_CLIENT, items.size())):
		var slot_id := free_slots[i]
		var item := items[i]
		if item == null:
			if DebugLog.enabled():
				DebugLog.logf("DeskTray spawn_skip desk=%s reason=item_null", [String(desk_state.desk_id)])
			continue
		if storage_state.get_slot_item(slot_id) != null:
			if DebugLog.enabled():
				DebugLog.logf(
					"DeskTray spawn_skip desk=%s slot=%s reason=slot_occupied",
					[String(desk_state.desk_id), String(slot_id)]
				)
			continue
		var put_result := storage_state.put(slot_id, item)
		if not put_result.success:
			if DebugLog.enabled():
				DebugLog.logf(
					"DeskTray spawn_fail desk=%s slot=%s item=%s reason=put_failed",
					[String(desk_state.desk_id), String(slot_id), String(item.id)]
				)
			continue
		if DebugLog.enabled():
			DebugLog.logf(
				"DeskTray spawn_ok desk=%s slot=%s item=%s kind=%s",
				[String(desk_state.desk_id), String(slot_id), String(item.id), String(item.kind)]
			)
		events.append(_make_event(EventSchema.EVENT_DESK_SPAWNED_ITEM, {
			EventSchema.PAYLOAD_DESK_ID: desk_state.desk_id,
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
			EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item.id,
			EventSchema.PAYLOAD_ITEM_KIND: item.kind,
		}))
	return events

func _has_tray_capacity(desk_state: DeskState, storage_state: WardrobeStorageState) -> bool:
	if storage_state == null or desk_state == null:
		return false
	var tray_slots: Array = _tray_slots_by_desk_id.get(desk_state.desk_id, [])
	if tray_slots.is_empty():
		return false
	var free_slots := _get_free_tray_slots(tray_slots, storage_state)
	return free_slots.size() >= ITEMS_PER_CLIENT

func _get_free_tray_slots(tray_slots: Array, storage_state: WardrobeStorageState) -> Array[StringName]:
	var free_slots: Array[StringName] = []
	for entry in tray_slots:
		var slot_id := StringName(str(entry))
		if slot_id == StringName():
			continue
		if storage_state.get_slot_item(slot_id) != null:
			continue
		if _reserved_tray_slots.has(slot_id):
			continue
		free_slots.append(slot_id)
	return free_slots

func _is_ticket_free(ticket: ItemInstance, clients: Dictionary) -> bool:
	if ticket == null:
		return false
	for client in clients.values():
		var client_state: RefCounted = client
		if client_state == null:
			continue
		if client_state.get_ticket_id() == ticket.id:
			return false
	return true

func _make_deliver_accept_event(
	desk_state: DeskState,
	current_client: ClientState,
	item_instance: ItemInstance,
	consume_kind: StringName
) -> Dictionary:
	return _make_event(EventSchema.EVENT_DELIVER_RESULT_ACCEPT_CONSUME, {
		EventSchema.PAYLOAD_SERVICE_POINT_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_CLIENT_ID: current_client.client_id,
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item_instance.id,
		EventSchema.PAYLOAD_CONSUME_KIND: consume_kind,
	})

func _make_deliver_reject_event(
	desk_state: DeskState,
	current_client: ClientState,
	item_instance: ItemInstance,
	reason_code: StringName
) -> Dictionary:
	var patience_delta := _resolve_patience_penalty(current_client, reason_code)
	return _make_event(EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN, {
		EventSchema.PAYLOAD_SERVICE_POINT_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_CLIENT_ID: current_client.client_id if current_client != null else StringName(),
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item_instance.id,
		EventSchema.PAYLOAD_PATIENCE_DELTA: patience_delta,
		EventSchema.PAYLOAD_REASON_CODE: reason_code,
	})

func _resolve_patience_penalty(current_client: ClientState, reason_code: StringName) -> float:
	if current_client == null:
		return 0.0
	var policy_result: Dictionary = _reject_policy.evaluate(reason_code, current_client.phase)
	var apply_penalty: bool = bool(policy_result.get("apply_patience_penalty", false))
	if not apply_penalty:
		return 0.0
	return current_client.get_wrong_item_patience_penalty()

func _get_current_client(desk_state: DeskState, clients: Dictionary) -> ClientState:
	return _get_client(clients, desk_state.current_client_id)

func _get_client(clients: Dictionary, client_id: StringName) -> ClientState:
	if client_id.is_empty():
		return null
	return clients.get(client_id) as ClientState

func _make_phase_change_event(client: ClientState, previous_phase: StringName) -> Dictionary:
	return _make_event(EventSchema.EVENT_CLIENT_PHASE_CHANGED, {
		EventSchema.PAYLOAD_CLIENT_ID: client.client_id,
		EventSchema.PAYLOAD_FROM: previous_phase,
		EventSchema.PAYLOAD_TO: client.phase,
	})

func _make_event(event_type: StringName, payload: Dictionary) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: event_type,
		EventSchema.EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}
