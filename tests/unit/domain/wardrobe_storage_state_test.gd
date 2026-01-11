extends GdUnitTestSuite

const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_put_into_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	var item := _make_item("coat_1", ItemInstance.KIND_COAT)
	var result := state.put(StringName("Slot_A"), item)
	assert_that(result.success).is_true()
	assert_that(state.get_slot_item(StringName("Slot_A"))).is_equal(item)

func test_put_rejects_missing_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	var item := _make_item("coat_1", ItemInstance.KIND_COAT)
	var result := state.put(StringName("Unknown"), item)
	assert_bool(result.success).is_false()
	assert_that(result.reason).is_equal(WardrobeStorageState.REASON_SLOT_MISSING)

func test_put_rejects_occupied_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var result := state.put(StringName("Slot_A"), _make_item("coat_2", ItemInstance.KIND_COAT))
	assert_bool(result.success).is_false()
	assert_that(result.reason).is_equal(WardrobeStorageState.REASON_SLOT_BLOCKED)

func test_pick_and_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var result := state.pick(StringName("Slot_A"))
	assert_bool(result.success).is_true()
	assert_that(result.item).is_not_null()
	assert_that(state.get_slot_item(StringName("Slot_A"))).is_null()

func test_pick_rejects_empty_slot() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	var result := state.pick(StringName("Slot_A"))
	assert_bool(result.success).is_false()
	assert_that(result.reason).is_equal(WardrobeStorageState.REASON_SLOT_EMPTY)

func test_snapshot_contains_slot_items() -> void:
	var state := WardrobeStorageStateScript.new()
	state.register_slot(StringName("Slot_A"))
	state.register_slot(StringName("Slot_B"))
	state.put(StringName("Slot_A"), _make_item("coat_1", ItemInstance.KIND_COAT))
	var snapshot := state.get_snapshot()
	assert_that(snapshot.slots_by_id.size()).is_equal(2)
	assert_that(snapshot.slots_by_id.get(StringName("Slot_A"))).is_not_null()
	assert_that(snapshot.slots_by_id.get(StringName("Slot_B"))).is_null()

func _make_item(id: String, kind: StringName) -> ItemInstance:
	return ItemInstanceScript.new(StringName(id), kind)
