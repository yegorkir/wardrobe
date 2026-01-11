extends GdUnitTestSuite

const DeskRejectOutcomeSystemScript := preload("res://scripts/app/desk/desk_reject_outcome_system.gd")
const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

func test_wrong_item_reject_pops_once_and_emits_drop() -> void:
	var system := DeskRejectOutcomeSystemScript.new()
	var storage := StorageStateScript.new()
	var desk_slot_id := StringName("DeskSlot_A")
	storage.register_slot(desk_slot_id)
	var item := ItemInstanceScript.new(StringName("coat_wrong"), ItemInstanceScript.KIND_COAT)
	storage.put(desk_slot_id, item)
	var client := ClientStateScript.new(
		StringName("Client_A"),
		ItemInstanceScript.new(StringName("coat_a"), ItemInstanceScript.KIND_COAT),
		ItemInstanceScript.new(StringName("ticket_a"), ItemInstanceScript.KIND_TICKET),
		StringName(),
		StringName("color_a"),
		StringName("human"),
		5.0
	)
	var clients := {client.client_id: client}
	var floor_resolver := FloorResolverScript.new()
	floor_resolver.configure([StringName("Floor_A")], StringName("Floor_A"))
	var penalty_calls: Array = []
	var apply_penalty := func(client_id: StringName, amount: float, reason_code: StringName) -> void:
		penalty_calls.append({
			"id": client_id,
			"amount": amount,
			"reason": reason_code,
		})
	system.configure(storage, clients, floor_resolver, apply_penalty)
	var reject_event := {
		EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_DESK_REJECTED_DELIVERY,
		EventSchema.EVENT_KEY_PAYLOAD: {
			EventSchema.PAYLOAD_DESK_SLOT_ID: desk_slot_id,
			EventSchema.PAYLOAD_CLIENT_ID: client.client_id,
			EventSchema.PAYLOAD_ITEM_INSTANCE_ID: item.id,
			EventSchema.PAYLOAD_REASON_CODE: EventSchema.REASON_WRONG_ITEM,
			EventSchema.PAYLOAD_CLIENT_PHASE: ClientStateScript.PHASE_PICK_UP,
		},
	}

	var outcome_events := system.process_desk_events([reject_event])
	assert_that(storage.get_slot_item(desk_slot_id)).is_null()
	assert_int(outcome_events.size()).is_equal(1)
	assert_that(outcome_events[0].get(EventSchema.EVENT_KEY_TYPE)).is_equal(EventSchema.EVENT_ITEM_DROPPED)
	assert_int(penalty_calls.size()).is_equal(1)

	var outcome_events_second := system.process_desk_events([reject_event])
	assert_int(outcome_events_second.size()).is_equal(0)
	assert_int(penalty_calls.size()).is_equal(1)
