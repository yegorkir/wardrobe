extends GdUnitTestSuite

const FloorZoneAdapterScript := preload("res://scripts/ui/floor_zone_adapter.gd")
const ShelfSurfaceAdapterScript := preload("res://scripts/ui/shelf_surface_adapter.gd")
const WardrobePhysicsTickAdapterScript := preload("res://scripts/ui/wardrobe_physics_tick_adapter.gd")
const ItemScene := preload("res://scenes/prefabs/item_node.tscn")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const FLOOR_Y := 280.0
const SHELF_Y := 180.0
const FLOOR_WIDTH := 360.0
const FLOOR_HEIGHT := 8.0
const SHELF_WIDTH := 220.0
const SHELF_HEIGHT := 8.0
const DROP_HEIGHT := 80.0
const HEAVY_PUSH_X := -160.0
const POSITION_EPS := 1.5
const LANDING_WAIT_FRAMES := 240

func test_knocked_from_shelf_lands_on_floor() -> void:
	var run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase
	assert_that(run_manager).is_not_null()
	run_manager.start_shift()
	var shift_log: WardrobeShiftLog = run_manager.get_shift_log()
	assert_that(shift_log).is_not_null()

	var runner := scene_runner("res://tests/scenes/reject_no_item_contacts.tscn")
	var root := runner.scene() as Node2D
	assert_that(root).is_not_null()

	var tick: WardrobePhysicsTickAdapter = WardrobePhysicsTickAdapterScript.new()
	root.add_child(tick)

	var floor_zone := _create_floor_zone(FLOOR_Y, FLOOR_WIDTH, FLOOR_HEIGHT)
	root.add_child(floor_zone)

	var shelf := _create_shelf_surface(SHELF_Y, SHELF_WIDTH, SHELF_HEIGHT)
	root.add_child(shelf)

	await _await_physics_frames(2)

	var light_item := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(light_item).is_not_null()
	light_item.item_id = "light_item"
	light_item.item_type = ItemNode.ItemType.TICKET
	root.add_child(light_item)
	shelf.place_item(light_item, Vector2(SHELF_WIDTH * 0.49, SHELF_Y))
	light_item.apply_collision_profile_default()
	light_item.freeze = false
	light_item.sleeping = false

	var heavy_item := auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(heavy_item).is_not_null()
	heavy_item.item_id = "heavy_item"
	heavy_item.item_type = ItemNode.ItemType.CHEST
	root.add_child(heavy_item)
	heavy_item.freeze = false
	heavy_item.sleeping = false
	heavy_item.global_position = Vector2(SHELF_WIDTH * 0.62, SHELF_Y - DROP_HEIGHT)
	heavy_item.linear_velocity = Vector2(HEAVY_PUSH_X, 0.0)

	await _await_physics_frames(LANDING_WAIT_FRAMES)

	assert_float(abs(light_item.get_bottom_y_global() - FLOOR_Y)).is_less_equal(POSITION_EPS)
	var events: Array = shift_log.get_events()
	assert_bool(_has_landing_event(events, StringName(light_item.item_id))).is_true()

func _create_floor_zone(floor_y: float, width: float, height: float) -> FloorZoneAdapter:
	var floor_zone: FloorZoneAdapter = FloorZoneAdapterScript.new() as FloorZoneAdapter
	floor_zone.name = "FloorZone"
	floor_zone.global_position = Vector2(0.0, floor_y + height * 0.5)

	var surface_body: StaticBody2D = StaticBody2D.new()
	surface_body.name = "SurfaceBody"
	var surface_shape: CollisionShape2D = CollisionShape2D.new()
	surface_shape.name = "CollisionShape2D"
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	surface_shape.shape = rect
	surface_body.add_child(surface_shape)
	floor_zone.add_child(surface_body)

	var drop_area: Area2D = Area2D.new()
	drop_area.name = "DropArea"
	var drop_shape: CollisionShape2D = CollisionShape2D.new()
	drop_shape.name = "CollisionShape2D"
	var drop_rect: RectangleShape2D = RectangleShape2D.new()
	drop_rect.size = Vector2(width, 64.0)
	drop_shape.shape = drop_rect
	drop_area.add_child(drop_shape)
	var items_root: Node2D = Node2D.new()
	items_root.name = "ItemsRoot"
	drop_area.add_child(items_root)
	floor_zone.add_child(drop_area)

	var surface_ref: Node2D = Node2D.new()
	surface_ref.name = "SurfaceRef"
	floor_zone.add_child(surface_ref)

	return floor_zone

func _create_shelf_surface(shelf_y: float, width: float, height: float) -> ShelfSurfaceAdapter:
	var shelf: ShelfSurfaceAdapter = ShelfSurfaceAdapterScript.new() as ShelfSurfaceAdapter
	shelf.name = "ShelfSurface"
	shelf.shelf_length_px = width
	shelf.drop_area_height_px = 64.0
	shelf.global_position = Vector2(0.0, shelf_y)

	var surface_body: StaticBody2D = StaticBody2D.new()
	surface_body.name = "SurfaceBody"
	var surface_shape: CollisionShape2D = CollisionShape2D.new()
	surface_shape.name = "CollisionShape2D"
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, height)
	surface_shape.shape = rect
	surface_body.add_child(surface_shape)
	shelf.add_child(surface_body)

	var surface_ref: Node2D = Node2D.new()
	surface_ref.name = "SurfaceRef"
	shelf.add_child(surface_ref)

	var surface_left: Node2D = Node2D.new()
	surface_left.name = "SurfaceLeft"
	surface_left.position = Vector2(-width * 0.5, 0.0)
	shelf.add_child(surface_left)

	var surface_right: Node2D = Node2D.new()
	surface_right.name = "SurfaceRight"
	surface_right.position = Vector2(width * 0.5, 0.0)
	shelf.add_child(surface_right)

	var drop_area: Area2D = Area2D.new()
	drop_area.name = "DropArea"
	var drop_shape: CollisionShape2D = CollisionShape2D.new()
	drop_shape.name = "CollisionShape2D"
	var drop_rect: RectangleShape2D = RectangleShape2D.new()
	drop_rect.size = Vector2(width, 64.0)
	drop_shape.shape = drop_rect
	drop_area.add_child(drop_shape)
	var items_root: Node2D = Node2D.new()
	items_root.name = "ItemsRoot"
	drop_area.add_child(items_root)
	shelf.add_child(drop_area)

	return shelf

func _has_landing_event(events: Array, item_id: StringName) -> bool:
	for event in events:
		if event is Dictionary:
			var event_dict: Dictionary = event as Dictionary
			var event_type: StringName = event_dict.get(EventSchema.EVENT_KEY_TYPE, StringName())
			if event_type != EventSchema.EVENT_ITEM_LANDED:
				continue
			var payload: Dictionary = event_dict.get(EventSchema.EVENT_KEY_PAYLOAD, {})
			var landed_id: StringName = payload.get(EventSchema.PAYLOAD_ITEM_ID, StringName())
			if landed_id == item_id:
				return true
	return false

func _await_physics_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame
