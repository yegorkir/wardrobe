extends GdUnitTestSuite

const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_put_into_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	var item := _make_item("coat_1", ItemInstance.KIND_COAT)
	var result := state.put(StringName("Slot_A"), item)
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false)).is_true()
	assert_that(state.get_slot_item(StringName("Slot_A"))).is_equal(item)

func test_put_rejects_missing_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	var item := _make_item("coat_1", ItemInstance.KIND_COAT)
	var result := state.put(StringName("Unknown"), item)
	assert_bool(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, true)).is_false()
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_REASON, StringName())).is_equal(
		WardrobeStorageState.REASON_SLOT_MISSING
	)

func test_put_rejects_occupied_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var result := state.put(StringName("Slot_A"), _make_item("coat_2", ItemInstance.KIND_COAT))
	assert_bool(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, true)).is_false()
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_REASON, StringName())).is_equal(
		WardrobeStorageState.REASON_SLOT_BLOCKED
	)

func test_pick_and_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var result := state.pick(StringName("Slot_A"))
	assert_bool(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false)).is_true()
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_ITEM)).is_not_null()
	assert_that(state.get_slot_item(StringName("Slot_A"))).is_null()

func test_pick_rejects_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	var result := state.pick(StringName("Slot_A"))
	assert_bool(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, true)).is_false()
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_REASON, StringName())).is_equal(
		WardrobeStorageState.REASON_SLOT_EMPTY
	)

func test_swap_exchanges_items() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.put(StringName("Slot_A"), _make_item("coat_slot", ItemInstance.KIND_COAT))
	var incoming := _make_item("coat_hand", ItemInstance.KIND_COAT)
	var result := state.swap(StringName("Slot_A"), incoming)
	assert_bool(result.get(WardrobeStorageState.RESULT_KEY_SUCCESS, false)).is_true()
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_REASON, StringName())).is_equal(
		WardrobeStorageState.REASON_OK
	)
	assert_that(result.get(WardrobeStorageState.RESULT_KEY_OUTGOING)).is_not_null()
	assert_that(state.get_slot_item(StringName("Slot_A"))).is_equal(incoming)

func test_snapshot_contains_slot_items() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.register_slot(StringName("Slot_B"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var snapshot := state.get_snapshot()
	var slots_variant: Variant = snapshot.get("slots", {})
	var slots: Dictionary = slots_variant if slots_variant is Dictionary else {}
	assert_that(slots.size()).is_equal(2)
	assert_that(slots.get(StringName("Slot_A"))).is_not_null()
	assert_that(slots.get(StringName("Slot_B"))).is_null()

func _make_item(id: String, kind: StringName) -> ItemInstance:
	return ItemInstanceScript.new(StringName(id), kind)
