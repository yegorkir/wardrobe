extends GdUnitTestSuite

const WardrobeScene := preload("res://scenes/screens/WardrobeScene.tscn")

func test_wardrobe_scene_reacts_to_hud_updates() -> void:
	var run_manager := get_node_or_null("/root/RunManager") as RunManagerBase
	assert_that(run_manager).is_not_null()
	run_manager.start_shift()
	var wardrobe: Control = auto_free(WardrobeScene.instantiate())
	get_tree().root.add_child(wardrobe)
	await get_tree().process_frame
	var money_label: Label = wardrobe.get_node("HUDContainer/HUDPanel/VBox/MoneyValue") as Label
	assert_that(money_label).is_not_null()
	var initial_value := _parse_label_value(money_label.text)
	run_manager.adjust_demo_money(5)
	await get_tree().process_frame
	var updated_value := _parse_label_value(money_label.text)
	assert_that(updated_value).is_greater(initial_value)

func _parse_label_value(text: String) -> int:
	var parts := text.split(": ")
	if parts.size() < 2:
		return -1
	return int(parts[1])
