extends GdUnitTestSuite

const InteractionService := preload("res://scripts/app/interaction/interaction_service.gd")
const StorageState := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstance := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/interaction/interaction_event_schema.gd")
const Resolver := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")

func test_build_auto_command_tracks_hand_and_slot() -> void:
	var service := InteractionService.new()
	var storage: StorageState = service.get_storage_state()
	storage.register_slot(StringName("Slot_A"))
	var slot_item := _make_item("coat_slot")
	storage.put(StringName("Slot_A"), slot_item)
	service.set_hand_item(_make_item("coat_hand"))

	var command := service.build_auto_command(StringName("Slot_A"), slot_item)
	var payload: Dictionary = command.get("payload", {})

	assert_that(payload.get("slot_id")).is_equal(StringName("Slot_A"))
	assert_that(payload.get("hand_item_id")).is_equal("coat_hand")
	assert_that(payload.get("slot_item_id")).is_equal("coat_slot")

func test_execute_command_updates_hand_state() -> void:
	var service := InteractionService.new()
	var storage: StorageState = service.get_storage_state()
	storage.register_slot(StringName("Slot_A"))
	storage.put(StringName("Slot_A"), _make_item("coat_slot"))

	var command := service.build_auto_command(StringName("Slot_A"), storage.get_slot_item(StringName("Slot_A")))
	var result := service.execute_command(command)

	assert_that(result.get(EventSchema.RESULT_KEY_SUCCESS, false)).is_true()
	assert_that(result.get(EventSchema.RESULT_KEY_ACTION, "")).is_equal(Resolver.ACTION_PICK)
	var hand := service.get_hand_item()
	assert_that(hand).is_not_null()
	if hand:
		assert_that(hand.id).is_equal(StringName("coat_slot"))

func _make_item(id: String) -> ItemInstance:
	return ItemInstance.new(StringName(id), ItemInstance.KIND_COAT)
