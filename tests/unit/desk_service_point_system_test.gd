extends GdUnitTestSuite

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientQueueSystemScript := preload("res://scripts/app/queue/client_queue_system.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

func test_deliver_accepts_any_free_ticket_on_checkin_consumes() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	var clients := {client.client_id: client}
	desk.current_client_id = client.client_id
	var ticket := ItemInstanceScript.new(StringName("ticket_00"), ItemInstanceScript.KIND_TICKET)

	var events := system.process_deliver_attempt(desk, queue, clients, storage, ticket)

	assert_that(client.get_ticket_id()).is_equal(ticket.id)
	assert_that(client.phase).is_equal(ClientStateScript.PHASE_PICK_UP)
	assert_bool(_has_event(events, EventSchema.EVENT_DELIVER_RESULT_ACCEPT_CONSUME)).is_true()
	var payload := _find_event_payload(events, EventSchema.EVENT_DELIVER_RESULT_ACCEPT_CONSUME)
	assert_that(payload.get(EventSchema.PAYLOAD_CONSUME_KIND)).is_equal(StringName("ticket"))

func test_drop_zone_blocker_keeps_client_in_queue() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	system.configure_drop_zone_blocker(Callable(self, "_block_all_drop_zones"))
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	var clients := {client.client_id: client}
	queue.enqueue_checkin(client.client_id)

	system.assign_next_client_to_desk(desk, queue, clients, storage)

	assert_that(desk.current_client_id).is_equal(StringName())
	assert_that(queue.peek_next_checkin()).is_equal(client.client_id)

func test_tray_items_block_assignment_with_full_tray() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	system.register_tray_slots(desk.desk_id, [StringName("Tray_0")])
	storage.register_slot(StringName("Tray_0"))
	storage.put(StringName("Tray_0"), ItemInstanceScript.new(StringName("tray_item"), ItemInstanceScript.KIND_COAT))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	var clients := {client.client_id: client}
	queue.enqueue_checkin(client.client_id)

	system.assign_next_client_to_desk(desk, queue, clients, storage)

	assert_that(desk.current_client_id).is_equal(StringName())
	assert_that(queue.peek_next_checkin()).is_equal(client.client_id)

func test_ticket_delivery_clears_desk_and_marks_client_away_with_tray_items() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	system.register_tray_slots(desk.desk_id, [StringName("Tray_0")])
	storage.register_slot(StringName("Tray_0"))
	storage.put(StringName("Tray_0"), ItemInstanceScript.new(StringName("tray_item"), ItemInstanceScript.KIND_COAT))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	var clients := {client.client_id: client}
	desk.current_client_id = client.client_id
	var ticket := ItemInstanceScript.new(StringName("ticket_00"), ItemInstanceScript.KIND_TICKET)

	system.process_deliver_attempt(desk, queue, clients, storage, ticket)

	assert_that(desk.current_client_id).is_equal(StringName())
	assert_that(client.presence).is_equal(ClientStateScript.PRESENCE_AWAY)
	assert_that(client.assigned_service_point_id).is_equal(StringName())
	assert_that(queue.peek_next_checkout()).is_equal(client.client_id)

func test_dropoff_requeues_checkout_on_shared_queue_system() -> void:
	var queue_system := ClientQueueSystemScript.new()
	queue_system.configure({
		"queue_delay_checkin_min": 0.0,
		"queue_delay_checkin_max": 0.0,
		"queue_delay_checkout_min": 1.0,
		"queue_delay_checkout_max": 1.0,
	}, 0)
	var system := DeskServicePointSystemScript.new()
	system.set_queue_system(queue_system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	var clients := {client.client_id: client}
	desk.current_client_id = client.client_id
	var ticket := ItemInstanceScript.new(StringName("ticket_00"), ItemInstanceScript.KIND_TICKET)

	system.process_deliver_attempt(desk, queue, clients, storage, ticket)
	queue_system.tick(queue, 1.0)

	assert_that(queue.peek_next_checkout()).is_equal(client.client_id)

func test_deliver_rejects_wrong_item_in_checkout_keeps_phase() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var queue := ClientQueueStateScript.new()
	var client := _make_client("Client_A", "coat_a")
	client.set_phase(ClientStateScript.PHASE_PICK_UP)
	var clients := {client.client_id: client}
	desk.current_client_id = client.client_id
	var wrong_item := ItemInstanceScript.new(StringName("coat_wrong"), ItemInstanceScript.KIND_COAT)

	var events := system.process_deliver_attempt(desk, queue, clients, storage, wrong_item)

	assert_that(client.phase).is_equal(ClientStateScript.PHASE_PICK_UP)
	assert_bool(_has_event(events, EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN)).is_true()
	var payload := _find_event_payload(events, EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN)
	assert_that(payload.get(EventSchema.PAYLOAD_REASON_CODE)).is_equal(EventSchema.REASON_WRONG_ITEM)

func test_tray_items_block_assignment() -> void:
	var system := DeskServicePointSystemScript.new()
	_configure_queue_system(system)
	var storage := _make_storage()
	var desk := DeskStateScript.new(StringName("Desk_A"), StringName("DeskSlot_A"))
	var tray_slots := [
		StringName("Tray_0"),
		StringName("Tray_1"),
		StringName("Tray_2"),
		StringName("Tray_3"),
	]
	system.register_tray_slots(desk.desk_id, tray_slots)
	for slot_id in tray_slots:
		storage.register_slot(slot_id)
		var filler := ItemInstanceScript.new(StringName("tray_fill_%s" % slot_id), ItemInstanceScript.KIND_COAT)
		storage.put(slot_id, filler)

	var queue := ClientQueueStateScript.new()
	var checkin_client := _make_client("Client_Checkin", "coat_in")
	var checkout_client := _make_client("Client_Checkout", "coat_out")
	checkout_client.set_phase(ClientStateScript.PHASE_PICK_UP)
	var clients := {
		checkin_client.client_id: checkin_client,
		checkout_client.client_id: checkout_client,
	}
	queue.enqueue_checkin(checkin_client.client_id)
	queue.enqueue_checkout(checkout_client.client_id)

	system.assign_next_client_to_desk(desk, queue, clients, storage)

	assert_that(desk.current_client_id).is_equal(StringName())

func _make_storage() -> WardrobeStorageState:
	var storage := StorageStateScript.new()
	storage.register_slot(StringName("DeskSlot_A"))
	return storage

func _configure_queue_system(system: DeskServicePointSystem) -> void:
	var queue_config := {
		"queue_delay_checkin_min": 0.0,
		"queue_delay_checkin_max": 0.0,
		"queue_delay_checkout_min": 0.0,
		"queue_delay_checkout_max": 0.0,
	}
	system.configure_queue_system(queue_config, 0)

func _make_client(id: String, coat_id: String) -> ClientState:
	var coat := ItemInstanceScript.new(StringName(coat_id), ItemInstanceScript.KIND_COAT)
	return ClientState.new(StringName(id), coat)

func _block_all_drop_zones(_desk_id: StringName) -> bool:
	return true

func _has_event(events: Array, event_type: StringName) -> bool:
	for event_data in events:
		if event_data.get(EventSchema.EVENT_KEY_TYPE) == event_type:
			return true
	return false

func _find_event_payload(events: Array, event_type: StringName) -> Dictionary:
	for event_data in events:
		if event_data.get(EventSchema.EVENT_KEY_TYPE) == event_type:
			return event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
	return {}
