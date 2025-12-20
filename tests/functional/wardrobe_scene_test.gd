extends GdUnitTestSuite

const WardrobeScene := preload("res://scenes/screens/WardrobeScene.tscn")
func test_wardrobe_scene_reacts_to_hud_updates() -> void:
	var run_manager := get_node_or_null("/root/RunManager") as RunManagerBase
	assert_that(run_manager).is_not_null()
	run_manager.start_shift()
	var wardrobe: Node = auto_free(WardrobeScene.instantiate())
	get_tree().root.add_child(wardrobe)
	await get_tree().process_frame
	var money_label: Label = wardrobe.get_node("HUDLayer/HUDContainer/HUDPanel/VBox/MoneyValue") as Label
	assert_that(money_label).is_not_null()
	var initial_value := _parse_label_value(money_label.text)
	run_manager.adjust_demo_money(5)
	await get_tree().process_frame
	var updated_value := _parse_label_value(money_label.text)
	assert_that(updated_value).is_greater(initial_value)

func test_wardrobe_scene_seeds_items() -> void:
	var wardrobe: Node = auto_free(WardrobeScene.instantiate())
	get_tree().root.add_child(wardrobe)
	await get_tree().process_frame
	var desk_slot_a := wardrobe.get_node("GameRoot/Desk/DeskSlot") as WardrobeSlot
	var desk_slot_b := wardrobe.get_node("GameRoot/Desk_B/DeskSlot") as WardrobeSlot
	assert_that(desk_slot_a).is_not_null()
	assert_that(desk_slot_b).is_not_null()
	assert_bool(desk_slot_a.has_item()).is_true()
	assert_bool(desk_slot_b.has_item()).is_true()
	assert_int(desk_slot_a.get_item().item_type).is_equal(ItemNode.ItemType.COAT)
	assert_int(desk_slot_b.get_item().item_type).is_equal(ItemNode.ItemType.COAT)
	var hook_slot := _find_slot_by_id(wardrobe, "Board_A_Hook_0_SlotA")
	assert_that(hook_slot).is_not_null()
	assert_bool(hook_slot.has_item()).is_true()
	assert_int(hook_slot.get_item().item_type).is_equal(ItemNode.ItemType.TICKET)

func _parse_label_value(text: String) -> int:
	var parts := text.split(": ")
	if parts.size() < 2:
		return -1
	return int(parts[1])

func _find_slot_by_id(root: Node, slot_id: String) -> WardrobeSlot:
	for node in root.get_tree().get_nodes_in_group(WardrobeSlot.SLOT_GROUP):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			if slot.get_slot_identifier() == slot_id:
				return slot
	return null
