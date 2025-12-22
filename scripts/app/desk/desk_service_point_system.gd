extends RefCounted

class_name DeskServicePointSystem

const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/interaction/interaction_event_schema.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")

const EVENT_KEY_TYPE := StringName("type")
const EVENT_KEY_PAYLOAD := StringName("payload")

const EVENT_DESK_CONSUMED_ITEM := StringName("desk_consumed_item")
const EVENT_DESK_SPAWNED_ITEM := StringName("desk_spawned_item")
const EVENT_CLIENT_PHASE_CHANGED := StringName("client_phase_changed")
const EVENT_CLIENT_COMPLETED := StringName("client_completed")
const EVENT_DESK_REJECTED_DELIVERY := StringName("desk_rejected_delivery")

const PAYLOAD_DESK_ID := StringName("desk_id")
const PAYLOAD_ITEM_INSTANCE_ID := StringName("item_instance_id")
const PAYLOAD_ITEM_KIND := StringName("item_kind")
const PAYLOAD_REASON_CODE := StringName("reason_code")
const PAYLOAD_CLIENT_ID := StringName("client_id")
const PAYLOAD_FROM := StringName("from")
const PAYLOAD_TO := StringName("to")

const REASON_DROP_OFF_TICKET := StringName("dropoff_ticket_taken")
const REASON_PICKUP_COAT := StringName("pickup_coat_taken")
const REASON_CLIENT_AWAY := StringName("client_away")
const REASON_WRONG_COAT := StringName("wrong_coat")

var _queue_system: ClientQueueSystem = ClientQueueSystemScript.new()

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
	if event_type != EventSchema.EVENT_ITEM_PLACED and event_type != EventSchema.EVENT_ITEM_SWAPPED:
		return []
	var payload: Dictionary = interaction_event.get(EventSchema.EVENT_KEY_PAYLOAD, {})
	var slot_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_SLOT_ID, "")))
	if slot_id != desk_state.desk_slot_id:
		return []
	var slot_item := storage_state.get_slot_item(desk_state.desk_slot_id)
	if slot_item == null:
		return []
	var current_client := _get_current_client(desk_state, clients)
	if current_client == null:
		return []
	if current_client.phase == ClientState.PHASE_DROP_OFF:
		return _handle_dropoff(desk_state, queue_state, clients, storage_state, current_client, slot_item)
	if current_client.phase == ClientState.PHASE_PICK_UP:
		return _handle_pickup(desk_state, queue_state, clients, storage_state, current_client, slot_item)
	return []

func _handle_dropoff(
	desk_state: DeskState,
	queue_state: ClientQueueState,
	clients: Dictionary,
	storage_state: WardrobeStorageState,
	current_client: ClientState,
	slot_item: ItemInstance
) -> Array:
	if slot_item.kind != ItemInstanceScript.KIND_TICKET:
		return []
	if current_client.presence == ClientState.PRESENCE_AWAY:
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, REASON_CLIENT_AWAY)
	var consume_events := _consume_desk_item(desk_state, storage_state, slot_item, REASON_DROP_OFF_TICKET)
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
	slot_item: ItemInstance
) -> Array:
	if slot_item.kind != ItemInstanceScript.KIND_COAT:
		return []
	if current_client.presence == ClientState.PRESENCE_AWAY:
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, REASON_CLIENT_AWAY)
	if slot_item.id != current_client.get_coat_id():
		return _make_delivery_rejected_event(desk_state, current_client, slot_item, REASON_WRONG_COAT)
	var consume_events := _consume_desk_item(desk_state, storage_state, slot_item, REASON_PICKUP_COAT)
	if consume_events.is_empty():
		return []
	var previous_phase := current_client.phase
	current_client.set_phase(ClientState.PHASE_DONE)
	_queue_system.remove_client(queue_state, current_client.client_id)
	var events := consume_events
	events.append(_make_phase_change_event(current_client, previous_phase))
	events.append(_make_event(EVENT_CLIENT_COMPLETED, {
		PAYLOAD_CLIENT_ID: current_client.client_id,
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
	var attempts := queue_state.get_count()
	for _step in range(attempts):
		var next_client_id := _queue_system.take_next_waiting_client(queue_state)
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
	reason_code: StringName
) -> Array:
	return [_make_event(EVENT_DESK_REJECTED_DELIVERY, {
		PAYLOAD_DESK_ID: desk_state.desk_id,
		PAYLOAD_CLIENT_ID: current_client.client_id,
		PAYLOAD_ITEM_INSTANCE_ID: slot_item.id,
		PAYLOAD_REASON_CODE: reason_code,
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
	return [_make_event(EVENT_DESK_CONSUMED_ITEM, {
		PAYLOAD_DESK_ID: desk_state.desk_id,
		PAYLOAD_ITEM_INSTANCE_ID: slot_item.id,
		PAYLOAD_REASON_CODE: reason_code,
	})]

func _make_phase_change_event(client: ClientState, previous_phase: StringName) -> Dictionary:
	return _make_event(EVENT_CLIENT_PHASE_CHANGED, {
		PAYLOAD_CLIENT_ID: client.client_id,
		PAYLOAD_FROM: previous_phase,
		PAYLOAD_TO: client.phase,
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
	return [_make_event(EVENT_DESK_SPAWNED_ITEM, {
		PAYLOAD_DESK_ID: desk_state.desk_id,
		PAYLOAD_ITEM_INSTANCE_ID: item.id,
		PAYLOAD_ITEM_KIND: item.kind,
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
		EVENT_KEY_TYPE: event_type,
		EVENT_KEY_PAYLOAD: payload.duplicate(true),
	}
