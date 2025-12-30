extends GdUnitTestSuite

const ItemScene := preload("res://scenes/prefabs/item_node.tscn")
const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")

func test_item_node_layers_match_config() -> void:
	var item := auto_free(ItemScene.instantiate()) as ItemNode
	get_tree().root.add_child(item)
	await get_tree().process_frame
	assert_int(item.collision_layer).is_equal(PhysicsLayers.LAYER_ITEM_BIT)
	assert_int(item.collision_mask).is_equal(PhysicsLayers.MASK_ITEM_DEFAULT)
	var pick_area := item.get_node_or_null("PickArea") as Area2D
	assert_that(pick_area).is_not_null()
	assert_int(pick_area.collision_layer).is_equal(PhysicsLayers.LAYER_PICK_AREA_BIT)
	assert_int(pick_area.collision_mask).is_equal(PhysicsLayers.LAYER_PICK_AREA_BIT)
