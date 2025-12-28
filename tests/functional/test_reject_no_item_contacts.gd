extends GdUnitTestSuite

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const ItemScene := preload("res://scenes/prefabs/item_node.tscn")

const FLOOR_Y := 280.0
const SHELF_Y := 180.0
const BODY_WIDTH := 240.0
const BODY_HEIGHT := 8.0
const POSITION_EPS := 0.5
const VELOCITY_EPS := 0.5

func test_reject_fall_skips_item_collisions() -> void:
	var runner := scene_runner("res://tests/scenes/reject_no_item_contacts.tscn")
	var root := runner.scene() as Node2D
	assert_that(root).is_not_null()
	var shelf_body := _create_static_body("ShelfBody", Vector2(0.0, SHELF_Y), BODY_WIDTH, BODY_HEIGHT)
	shelf_body.collision_layer = PhysicsLayers.LAYER_SHELF_BIT
	shelf_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT
	root.add_child(shelf_body)
	var floor_body := _create_static_body("FloorBody", Vector2(0.0, FLOOR_Y), BODY_WIDTH, BODY_HEIGHT)
	floor_body.collision_layer = PhysicsLayers.LAYER_FLOOR_BIT
	floor_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT
	root.add_child(floor_body)

	var item_a := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item_a).is_not_null()
	root.add_child(item_a)
	item_a.freeze = true
	item_a.sleeping = true
	item_a.global_position = Vector2(0.0, SHELF_Y - 16.0)

	await _await_physics_frames(2)

	var baseline_pos := item_a.global_position
	var baseline_vel := item_a.linear_velocity
	assert_float(baseline_vel.length()).is_less_equal(VELOCITY_EPS)

	var item_b := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item_b).is_not_null()
	root.add_child(item_b)
	item_b.freeze = false
	item_b.sleeping = false
	item_b.global_position = Vector2(0.0, SHELF_Y - 60.0)
	item_b.start_reject_fall(FLOOR_Y)
	assert_int(item_b.last_drop_reason).is_equal(ItemNode.DropReason.REJECT)

	await _await_physics_frames(30)

	var pos_delta := item_a.global_position.distance_to(baseline_pos)
	assert_float(pos_delta).is_less_equal(POSITION_EPS)
	assert_float(item_a.linear_velocity.length()).is_less_equal(VELOCITY_EPS)
	assert_float(baseline_vel.length()).is_less_equal(VELOCITY_EPS)

func test_normal_fall_has_item_collisions() -> void:
	var runner := scene_runner("res://tests/scenes/reject_no_item_contacts.tscn")
	var root := runner.scene() as Node2D
	assert_that(root).is_not_null()
	var shelf_body := _create_static_body("ShelfBody", Vector2(0.0, SHELF_Y), BODY_WIDTH, BODY_HEIGHT)
	shelf_body.collision_layer = PhysicsLayers.LAYER_SHELF_BIT
	shelf_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT
	root.add_child(shelf_body)
	var floor_body := _create_static_body("FloorBody", Vector2(0.0, FLOOR_Y), BODY_WIDTH, BODY_HEIGHT)
	floor_body.collision_layer = PhysicsLayers.LAYER_FLOOR_BIT
	floor_body.collision_mask = PhysicsLayers.LAYER_ITEM_BIT
	root.add_child(floor_body)

	var item_a := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item_a).is_not_null()
	root.add_child(item_a)
	item_a.freeze = true
	item_a.sleeping = true
	item_a.global_position = Vector2(0.0, SHELF_Y - 16.0)

	await _await_physics_frames(2)

	var baseline_pos := item_a.global_position
	var baseline_vel := item_a.linear_velocity
	assert_float(baseline_vel.length()).is_less_equal(VELOCITY_EPS)

	var item_b := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item_b).is_not_null()
	root.add_child(item_b)
	item_b.freeze = false
	item_b.sleeping = false
	item_b.global_position = Vector2(1.0, SHELF_Y - 60.0)

	# verify it can collide
	var can_collide := (
		(item_a.collision_mask & item_b.collision_layer) != 0
		or (item_b.collision_mask & item_a.collision_layer) != 0
	)
	assert_bool(can_collide).is_true()

	await _await_physics_frames(60)

	var pos_delta := item_a.global_position.distance_to(baseline_pos)
	assert_float(pos_delta).is_greater_equal(POSITION_EPS)

func _create_static_body(name_value: String, center: Vector2, width: float, height: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = name_value
	body.global_position = center
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	return body

func _await_physics_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame
