extends GdUnitTestSuite

const InteractionEngine := preload("res://scripts/domain/interaction/interaction_engine.gd")
const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const StorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const Resolver := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")
const InteractionResultScript := preload("res://scripts/domain/interaction/interaction_result.gd")

func test_pick_updates_hand_and_emits_event() -> void:
	var engine := InteractionEngine.new()
	var storage := _make_storage()
	storage.put(StringName("Slot_A"), _make_item("coat_1"))
	var command := InteractionCommandScript.new(
		InteractionCommandScript.TYPE_AUTO,
		5,
		StringName("Slot_A"),
		StringName(),
		StringName("coat_1")
	)

	var result: InteractionResultScript = engine.process_command(command, storage, null)

	assert_that(result.success).is_true()
	assert_that(result.action).is_equal(Resolver.ACTION_PICK)
	var picked: ItemInstance = result.hand_item
	assert_that(picked).is_not_null()
	assert_that(picked.id).is_equal(StringName("coat_1"))
	assert_that(storage.get_slot_item(StringName("Slot_A"))).is_null()
	var events: Array = result.events
	assert_int(events.size()).is_equal(1)
	var payload: Dictionary = events[0].payload
	assert_that(events[0].event_type).is_equal(EventSchema.EVENT_ITEM_PICKED)
	assert_that(payload.get(EventSchema.PAYLOAD_SLOT_ID)).is_equal(StringName("Slot_A"))
	var item_payload: Variant = payload.get(EventSchema.PAYLOAD_ITEM, null)
	assert_bool(item_payload is Dictionary).is_true()
	if item_payload is Dictionary:
		assert_that((item_payload as Dictionary).get("id")).is_equal(StringName("coat_1"))

func test_put_consumes_hand_and_logs_event() -> void:
	var engine := InteractionEngine.new()
	var storage := _make_storage()
	var hand := _make_item("coat_1")
	var command := InteractionCommandScript.new(
		InteractionCommandScript.TYPE_AUTO,
		2,
		StringName("Slot_A"),
		StringName("coat_1"),
		StringName()
	)

	var result: InteractionResultScript = engine.process_command(command, storage, hand)

	assert_that(result.success).is_true()
	assert_that(result.action).is_equal(Resolver.ACTION_PUT)
	assert_that(result.hand_item).is_null()
	var slot_item := storage.get_slot_item(StringName("Slot_A"))
	assert_that(slot_item).is_not_null()
	if slot_item:
		assert_that(slot_item.id).is_equal(StringName("coat_1"))
	var events: Array = result.events
	assert_int(events.size()).is_equal(1)
	assert_that(events[0].event_type).is_equal(EventSchema.EVENT_ITEM_PLACED)

func test_rejects_when_swap_disabled() -> void:
	var engine := InteractionEngine.new()
	var storage := _make_storage()
	var hand := _make_item("coat_hand")
	var slot_item := _make_item("coat_slot")
	storage.put(StringName("Slot_A"), slot_item)
	var command := InteractionCommandScript.new(
		InteractionCommandScript.TYPE_AUTO,
		3,
		StringName("Slot_A"),
		StringName("coat_hand"),
		StringName("coat_slot")
	)

	var result: InteractionResultScript = engine.process_command(command, storage, hand)

	assert_that(result.success).is_false()
	assert_that(result.action).is_equal(Resolver.ACTION_NONE)
	assert_that(result.reason).is_equal(InteractionEngine.REASON_SWAP_DISABLED)
	assert_that(result.hand_item).is_equal(hand)
	var slot_after := storage.get_slot_item(StringName("Slot_A"))
	assert_that(slot_after).is_equal(slot_item)
	var events: Array = result.events
	assert_int(events.size()).is_equal(1)
	var payload: Dictionary = events[0].payload
	assert_that(events[0].event_type).is_equal(EventSchema.EVENT_ACTION_REJECTED)
	assert_that(payload.get(EventSchema.PAYLOAD_REASON)).is_equal(InteractionEngine.REASON_SWAP_DISABLED)

func test_rejects_when_hand_id_mismatches() -> void:
	var engine := InteractionEngine.new()
	var storage := _make_storage()
	var hand := _make_item("coat_actual")
	var command := InteractionCommandScript.new(
		InteractionCommandScript.TYPE_PUT,
		1,
		StringName("Slot_A"),
		StringName("coat_expected"),
		StringName()
	)

	var result: InteractionResultScript = engine.process_command(command, storage, hand)

	assert_that(result.success).is_false()
	assert_that(result.reason).is_equal(InteractionEngine.REASON_HAND_MISMATCH)
	assert_that(result.hand_item).is_equal(hand)
	var events: Array = result.events
	assert_int(events.size()).is_equal(1)
	var payload: Dictionary = events[0].payload
	assert_that(events[0].event_type).is_equal(EventSchema.EVENT_ACTION_REJECTED)
	assert_that(payload.get(EventSchema.PAYLOAD_REASON)).is_equal(InteractionEngine.REASON_HAND_MISMATCH)

func test_rejects_slot_mismatch_without_mutation() -> void:
	var engine := InteractionEngine.new()
	var storage := _make_storage()
	var slot_item := _make_item("coat_slot")
	storage.put(StringName("Slot_A"), slot_item)
	var command := InteractionCommandScript.new(
		InteractionCommandScript.TYPE_PICK,
		7,
		StringName("Slot_A"),
		StringName(),
		StringName("different_slot_id")
	)

	var result: InteractionResultScript = engine.process_command(command, storage, null)

	assert_that(result.success).is_false()
	assert_that(result.reason).is_equal(InteractionEngine.REASON_SLOT_MISMATCH)
	assert_that(storage.get_slot_item(StringName("Slot_A"))).is_equal(slot_item)
	var events: Array = result.events
	assert_int(events.size()).is_equal(1)
	var payload: Dictionary = events[0].payload
	assert_that(payload.get(EventSchema.PAYLOAD_SLOT_ID)).is_equal(StringName("Slot_A"))

func _make_storage() -> WardrobeStorageState:
	var storage := StorageStateScript.new()
	storage.register_slot(StringName("Slot_A"))
	return storage

func _make_item(id: String) -> ItemInstance:
	return ItemInstanceScript.new(StringName(id), ItemInstance.KIND_COAT)
