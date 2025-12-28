extends GdUnitTestSuite

const ItemScene := preload("res://scenes/prefabs/item_node.tscn")

func test_itemnode_bottom_y_matches_aabb() -> void:
	var item := auto_free(ItemScene.instantiate()) as ItemNode
	get_tree().root.add_child(item)
	item.global_position = Vector2(120.0, 240.0)
	await get_tree().process_frame
	var rect := item.get_collider_aabb_global()
	assert_bool(rect.size != Vector2.ZERO).is_true()
	var expected_bottom := rect.position.y + rect.size.y
	assert_float(item.get_bottom_y_global()).is_equal_approx(expected_bottom, 0.01)

func test_itemnode_snap_bottom_to_y() -> void:
	var item := auto_free(ItemScene.instantiate()) as ItemNode
	get_tree().root.add_child(item)
	item.global_position = Vector2(80.0, 160.0)
	await get_tree().process_frame
	var target_bottom := item.get_bottom_y_global() + 12.0
	item.snap_bottom_to_y(target_bottom)
	assert_float(item.get_bottom_y_global()).is_equal_approx(target_bottom, 0.01)
