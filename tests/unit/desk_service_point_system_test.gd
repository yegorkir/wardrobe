extends GdUnitTestSuite

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

func test_dropoff_consumes_ticket_and_spawns_next_coat() -> void:
	var system := DeskServicePointSystemScript.new()
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client_a := _make_client("Client_A", "coat_a", "ticket_a")
	var client_b := _make_client("Client_B", "coat_b", "ticket_b")
	var clients := {
		client_a.client_id: client_a,
		client_b.client_id: client_b,
	}
	desk.current_client_id = client_a.client_id
	queue.enqueue(client_b.client_id)
	storage.put(desk.desk_slot_id, client_a.get_ticket_item())
	var event := _make_put_event(desk.desk_slot_id)

	var events := system.process_interaction_event(desk, queue, clients, storage, event)

	assert_that(client_a.phase).is_equal(ClientStateScript.PHASE_PICK_UP)
	assert_that(desk.current_client_id).is_equal(client_b.client_id)
	assert_that(storage.get_slot_item(desk.desk_slot_id).id).is_equal(client_b.get_coat_id())
	assert_that(queue.peek_next()).is_equal(client_a.client_id)
	assert_bool(_has_event(events, EventSchema.EVENT_DESK_CONSUMED_ITEM)).is_true()
	assert_bool(_has_event(events, EventSchema.EVENT_DESK_SPAWNED_ITEM)).is_true()

func test_dropoff_empty_queue_requeues_client_for_pickup() -> void:
	var system := DeskServicePointSystemScript.new()
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client_a := _make_client("Client_A", "coat_a", "ticket_a")
	var clients := {client_a.client_id: client_a}
	desk.current_client_id = client_a.client_id
	storage.put(desk.desk_slot_id, client_a.get_ticket_item())
	var event := _make_put_event(desk.desk_slot_id)

	var events := system.process_interaction_event(desk, queue, clients, storage, event)

	assert_that(desk.current_client_id).is_equal(client_a.client_id)
	assert_that(storage.get_slot_item(desk.desk_slot_id).id).is_equal(client_a.get_ticket_id())
	assert_that(queue.get_count()).is_equal(0)
	assert_bool(_has_event(events, EventSchema.EVENT_DESK_SPAWNED_ITEM)).is_true()

func test_pickup_consumes_correct_coat_and_spawns_next_ticket() -> void:
	var system := DeskServicePointSystemScript.new()
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client_a := _make_client("Client_A", "coat_a", "ticket_a")
	var client_b := _make_client("Client_B", "coat_b", "ticket_b")
	client_a.set_phase(ClientStateScript.PHASE_PICK_UP)
	client_b.set_phase(ClientStateScript.PHASE_PICK_UP)
	var clients := {
		client_a.client_id: client_a,
		client_b.client_id: client_b,
	}
	desk.current_client_id = client_a.client_id
	queue.enqueue(client_b.client_id)
	storage.put(desk.desk_slot_id, client_a.get_coat_item())
	var event := _make_swap_event(desk.desk_slot_id)

	var events := system.process_interaction_event(desk, queue, clients, storage, event)

	assert_that(client_a.phase).is_equal(ClientStateScript.PHASE_DONE)
	assert_that(desk.current_client_id).is_equal(client_b.client_id)
	assert_that(storage.get_slot_item(desk.desk_slot_id).id).is_equal(client_b.get_ticket_id())
	assert_bool(_has_event(events, EventSchema.EVENT_CLIENT_COMPLETED)).is_true()

func test_pickup_rejects_wrong_coat() -> void:
	var system := DeskServicePointSystemScript.new()
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client_a := _make_client("Client_A", "coat_a", "ticket_a")
	client_a.set_phase(ClientStateScript.PHASE_PICK_UP)
	var clients := {client_a.client_id: client_a}
	desk.current_client_id = client_a.client_id
	var wrong_coat := ItemInstanceScript.new(StringName("coat_wrong"), ItemInstanceScript.KIND_COAT)
	storage.put(desk.desk_slot_id, wrong_coat)
	var event := _make_swap_event(desk.desk_slot_id)

	var events := system.process_interaction_event(desk, queue, clients, storage, event)

	assert_that(storage.get_slot_item(desk.desk_slot_id).id).is_equal(StringName("coat_wrong"))
	assert_bool(_has_event(events, EventSchema.EVENT_DESK_REJECTED_DELIVERY)).is_true()

func _make_storage() -> WardrobeStorageState:
	var storage := StorageStateScript.new()
	storage.register_slot(StringName("DeskSlot_A"))
	return storage

func _make_client(id: String, coat_id: String, ticket_id: String) -> ClientState:
	var coat := ItemInstanceScript.new(StringName(coat_id), ItemInstanceScript.KIND_COAT)
	var ticket := ItemInstanceScript.new(StringName(ticket_id), ItemInstanceScript.KIND_TICKET)
	return ClientState.new(StringName(id), coat, ticket)

func _make_put_event(slot_id: StringName) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ITEM_PLACED,
		EventSchema.EVENT_KEY_PAYLOAD: {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
		},
	}

func _make_swap_event(slot_id: StringName) -> Dictionary:
	return {
		EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ITEM_SWAPPED,
		EventSchema.EVENT_KEY_PAYLOAD: {
			EventSchema.PAYLOAD_SLOT_ID: slot_id,
		},
	}

func _has_event(events: Array, event_type: StringName) -> bool:
	for event_data in events:
		if event_data.get(EventSchema.EVENT_KEY_TYPE) == event_type:
			return true
	return false
