extends GdUnitTestSuite

const FloorZoneAdapterScript := preload("res://scripts/ui/floor_zone_adapter.gd")
const WardrobePhysicsTickAdapterScript := preload("res://scripts/ui/wardrobe_physics_tick_adapter.gd")
const ItemScene := preload("res://scenes/prefabs/item_node.tscn")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

const FLOOR_Y := 120.0
const FLOOR_WIDTH := 320.0
const FLOOR_HEIGHT := 8.0
const DROP_HEIGHT := 80.0
const POSITION_EPS := 1.5
const LANDING_WAIT_FRAMES := 180

func test_transfer_rise_then_fall_lands_on_floor() -> void:
	var run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase
	assert_that(run_manager).is_not_null()
	run_manager.start_shift()
	var shift_log: WardrobeShiftLog = run_manager.get_shift_log()
	assert_that(shift_log).is_not_null()

	var runner: Variant = scene_runner("res://tests/scenes/reject_no_item_contacts.tscn")
	var root: Node2D = runner.scene() as Node2D
	assert_that(root).is_not_null()

	var tick: WardrobePhysicsTickAdapter = WardrobePhysicsTickAdapterScript.new()
	root.add_child(tick)

	var floor_zone: FloorZoneAdapter = _create_floor_zone(FLOOR_Y, FLOOR_WIDTH, FLOOR_HEIGHT)
	root.add_child(floor_zone)

	var item: ItemNode = auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item).is_not_null()
	root.add_child(item)
	item.freeze = false
	item.sleeping = false
	item.global_position = Vector2(0.0, FLOOR_Y + DROP_HEIGHT)

	item.start_floor_transfer(FLOOR_Y, ItemNode.FloorTransferMode.RISE_THEN_FALL)

	await _await_physics_frames(LANDING_WAIT_FRAMES)

	assert_bool(item.is_transfer_active()).is_false()
	assert_float(abs(item.get_bottom_y_global() - FLOOR_Y)).is_less_equal(POSITION_EPS)

	await _await_physics_frames(30)
	assert_float(abs(item.get_bottom_y_global() - FLOOR_Y)).is_less_equal(POSITION_EPS)

	var events: Array = shift_log.get_events()
	assert_bool(_has_landing_event(events, StringName(item.item_id))).is_true()

func test_passive_fall_emits_landing_event() -> void:
	var run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase
	assert_that(run_manager).is_not_null()
	run_manager.start_shift()
	var shift_log: WardrobeShiftLog = run_manager.get_shift_log()
	assert_that(shift_log).is_not_null()

	var runner: Variant = scene_runner("res://tests/scenes/reject_no_item_contacts.tscn")
	var root: Node2D = runner.scene() as Node2D
	assert_that(root).is_not_null()

	var tick: WardrobePhysicsTickAdapter = WardrobePhysicsTickAdapterScript.new()
	root.add_child(tick)

	var floor_zone: FloorZoneAdapter = _create_floor_zone(FLOOR_Y, FLOOR_WIDTH, FLOOR_HEIGHT)
	root.add_child(floor_zone)

	var item: ItemNode = auto_free(ItemScene.instantiate()) as ItemNode
	assert_that(item).is_not_null()
	root.add_child(item)
	item.freeze = false
	item.sleeping = false
	item.global_position = Vector2(0.0, FLOOR_Y - DROP_HEIGHT)

	await _await_physics_frames(LANDING_WAIT_FRAMES)

	var events: Array = shift_log.get_events()
	assert_bool(_has_landing_event(events, StringName(item.item_id))).is_true()

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
