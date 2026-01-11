extends RefCounted

class_name DeskServicePointSystem

const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")


var _queue_system: ClientQueueSystem = ClientQueueSystemScript.new()
var _queue_mix_provider: Callable

func configure_queue_mix_provider(provider: Callable) -> void:
	_queue_mix_provider = provider

func process_interaction_event(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	interaction_event: Dictionary
) -> Array:
	if desk_state == null or storage_state == null:
		return []
	var event_type: StringName = interaction_event.get(EventSchema.EVENT_KEY_TYPE, StringName())
	if event_type != EventSchema.EVENT_ITEM_PLACED:
		return []
	var payload: Dictionary = interaction_event.get(EventSchema.EVENT_KEY_PAYLOAD, {})
	var slot_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_SLOT_ID, "")))
	var tick: int = int(payload.get(EventSchema.PAYLOAD_TICK, 0))
	if slot_id != desk_state.desk_slot_id:
		return []
	var slot_item := storage_state.get_slot_item(desk_state.desk_slot_id)
	if slot_item == null:
		return []
	var current_client := _get_current_client(desk_state, clients)
	if current_client == null:
		return []
	if current_client.phase == ClientState.PHASE_DROP_OFF:
		return _handle_dropoff(desk_state, queue_state, clients, storage_state, current_client, slot_item, tick)
	if current_client.phase == ClientState.PHASE_PICK_UP:
		return _handle_pickup(desk_state, queue_state, clients, storage_state, current_client, slot_item, tick)
	return []

func _handle_dropoff(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	current_client: ClientState,
	slot_item: ItemInstance,
	tick: int
) -> Array:
	if slot_item.kind != ItemInstanceScript.KIND_TICKET:
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, EventSchema.REASON_WRONG_ITEM, tick)
	if current_client.presence == ClientState.PRESENCE_AWAY:
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, EventSchema.REASON_CLIENT_AWAY, tick)
	var consume_events := _consume_desk_item(desk_state, storage_state, slot_item, EventSchema.REASON_DROP_OFF_TICKET)
	if consume_events.is_empty():
		return []
	current_client.assign_ticket_item(slot_item)
	var previous_phase := current_client.phase
	current_client.set_phase(ClientState.PHASE_PICK_UP)
	_queue_system.requeue_after_dropoff(queue_state, current_client.client_id)
	var events := consume_events
	events.append(_make_phase_change_event(current_client, previous_phase))
	events.append_array(_assign_next_client_to_desk(desk_state, queue_state, clients, storage_state))
	return events

func _handle_pickup(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	current_client: ClientState,
	slot_item: ItemInstance,
	tick: int
) -> Array:
	if slot_item.kind != ItemInstanceScript.KIND_COAT:
		return []
	if current_client.presence == ClientState.PRESENCE_AWAY:
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, EventSchema.REASON_CLIENT_AWAY, tick)
	if slot_item.id != current_client.get_coat_id():
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, EventSchema.REASON_WRONG_ITEM, tick)
	var consume_events := _consume_desk_item(desk_state, storage_state, slot_item, EventSchema.REASON_PICKUP_COAT)
	if consume_events.is_empty():
		return []
	var previous_phase := current_client.phase
	current_client.set_phase(ClientState.PHASE_DONE)
	_queue_system.remove_client(queue_state, current_client.client_id)
	var events := consume_events
	events.append(_make_phase_change_event(current_client, previous_phase))
	events.append(_make_event(EventSchema.EVENT_CLIENT_COMPLETED, {
		EventSchema.PAYLOAD_CLIENT_ID: current_client.client_id,
	}))
	events.append_array(_assign_next_client_to_desk(desk_state, queue_state, clients, storage_state))
	return events

func assign_next_client_to_desk(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState
) -> Array:
	return _assign_next_client_to_desk(desk_state, queue_state, clients, storage_state)

func _assign_next_client_to_desk(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState
) -> Array:
	if desk_state == null:
		return []
	desk_state.current_client_id = StringName()
	if queue_state == null:
		return []
	var mix_snapshot: Dictionary = {}
	if _queue_mix_provider != null and _queue_mix_provider.is_valid():
		mix_snapshot = _queue_mix_provider.call()
	var attempts := queue_state.get_count()
	for _step in range(attempts):
		var next_client_id := _queue_system.take_next_waiting_client(queue_state, mix_snapshot)
		if next_client_id.is_empty():
			return []
		var next_client := _get_client(clients, next_client_id)
		if next_client == null or next_client.phase == ClientState.PHASE_DONE:
			continue
		desk_state.current_client_id = next_client_id
		next_client.set_assigned_service_point(desk_state.desk_id)
		var expected_kind := _get_expected_kind_for_client(next_client)
		if expected_kind == StringName():
			return []
		return _spawn_item_for_client(desk_state, storage_state, next_client, expected_kind)
	return []

func _make_delivery_rejected_event(
	desk_state: DeskState,
	current_client: ClientState,
	slot_item: ItemInstance,
	reason_code: StringName,
	tick: int
) -> Array:
	var event_id := _build_reject_event_id(desk_state, current_client, slot_item, reason_code, tick)
	return [_make_event(EventSchema.EVENT_DESK_REJECTED_DELIVERY, {
		EventSchema.PAYLOAD_DESK_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_DESK_SLOT_ID: desk_state.desk_slot_id,
		EventSchema.PAYLOAD_CLIENT_ID: current_client.client_id,
		EventSchema.PAYLOAD_CLIENT_INSTANCE_ID: current_client.client_id,
		EventSchema.PAYLOAD_CLIENT_SLOT_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_CLIENT_PHASE: current_client.phase,
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: slot_item.id,
		EventSchema.PAYLOAD_REASON_CODE: reason_code,
		EventSchema.PAYLOAD_EVENT_ID: event_id,
	})]

func _consume_desk_item(
	desk_state: DeskState,
	storage_state: WardrobeStorageState,
	slot_item: ItemInstance,
	reason_code: StringName
) -> Array:
	var consume_result := storage_state.pick(desk_state.desk_slot_id)
	if not consume_result.get(StorageStateScript.RESULT_KEY_SUCCESS, false):
		return []
	return [_make_event(EventSchema.EVENT_DESK_CONSUMED_ITEM, {
		EventSchema.PAYLOAD_DESK_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: slot_item.id,
		EventSchema.PAYLOAD_REASON_CODE: reason_code,
	})]

func _make_phase_change_event(client: ClientState, previous_phase: StringName) -> Dictionary:
	return _make_event(EventSchema.EVENT_CLIENT_PHASE_CHANGED, {
		EventSchema.PAYLOAD_CLIENT_ID: client.client_id,
		EventSchema.PAYLOAD_FROM: previous_phase,
		EventSchema.PAYLOAD_TO: client.phase,
	})

func _get_expected_kind_for_client(client: ClientState) -> StringName:
	if client == null:
		return StringName()
	if client.phase == ClientState.PHASE_DROP_OFF:
		return ItemInstanceScript.KIND_COAT
	if client.phase == ClientState.PHASE_PICK_UP:
		return ItemInstanceScript.KIND_TICKET
	return StringName()

func _spawn_item_for_client(
	desk_state: DeskState,
	storage_state: WardrobeStorageState,
	client: ClientState,
	expected_kind: StringName
) -> Array:
	if client == null:
		return []
	var item := _get_client_item(client, expected_kind)
	if item == null:
		return []
	var existing_slot := storage_state.find_item_slot(item.id)
	if existing_slot == desk_state.desk_slot_id:
		return []
	if not existing_slot.is_empty():
		storage_state.pick(existing_slot)
	if storage_state.get_slot_item(desk_state.desk_slot_id) != null:
		return []
	var put_result := storage_state.put(desk_state.desk_slot_id, item)
	if not put_result.get(StorageStateScript.RESULT_KEY_SUCCESS, false):
		return []
	return [_make_event(EventSchema.EVENT_DESK_SPAWNED_ITEM, {
		EventSchema.PAYLOAD_DESK_ID: desk_state.desk_id,
		EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item.id,
		EventSchema.PAYLOAD_ITEM_KIND: item.kind,
	})]

func _get_current_client(desk_state: DeskState, clients: Dictionary) -> ClientState:
	return _get_client(clients, desk_state.current_client_id)

func _get_client(clients: Dictionary, client_id: StringName) -> ClientState:
	if client_id.is_empty():
		return null
	return clients.get(client_id) as ClientState

func _get_client_item(client: ClientState, expected_kind: StringName) -> ItemInstance:
	if expected_kind == ItemInstanceScript.KIND_COAT:
		return client.get_coat_item()
	if expected_kind == ItemInstanceScript.KIND_TICKET:
		return client.get_ticket_item()
	return null

func _make_event(event_type: StringName, payload: Dictionary) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: event_type,
		EventSchema.EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}

func _build_reject_event_id(
	desk_state: DeskState,
	current_client: ClientState,
	slot_item: ItemInstance,
	reason_code: StringName,
	tick: int
) -> StringName:
	if desk_state == null or current_client == null or slot_item == null:
		return StringName()
	return StringName("%s:%s:%s:%s:%d" % [
		String(desk_state.desk_id),
		String(current_client.client_id),
		String(slot_item.id),
		String(reason_code),
		tick,
	])
