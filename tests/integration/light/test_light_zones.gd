extends GdUnitTestSuite

const LightZonesAdapter := preload("res://scripts/ui/light/light_zones_adapter.gd")
const LightService := preload("res://scripts/app/light/light_service.gd")
const ItemNodeScript := preload("res://scripts/wardrobe/item_node.gd")
const ItemScene := preload("res://scenes/prefabs/item_node.tscn")

var _scene: Node2D
var _adapter: LightZonesAdapter
var _service: LightService
var _curtain_zone: Area2D
var _bulb_row0_zone: Area2D
var _bulb_row1_zone: Area2D

func before_test() -> void:
	_scene = Node2D.new()
	add_child(_scene)
	
	_curtain_zone = _create_zone(Rect2(0, 0, 100, 200)) # 0..100 x 0..200
	_bulb_row0_zone = _create_zone(Rect2(200, 0, 100, 100)) # 200..300 x 0..100
	_bulb_row1_zone = _create_zone(Rect2(200, 150, 100, 50)) # 200..300 x 150..200
	
	_scene.add_child(_curtain_zone)
	_scene.add_child(_bulb_row0_zone)
	_scene.add_child(_bulb_row1_zone)
	
	_adapter = LightZonesAdapter.new()
	# Use NodePath from the node directly (absolute path)
	_adapter.curtain_zone_path = _curtain_zone.get_path()
	_adapter.bulb_row0_zone_path = _bulb_row0_zone.get_path()
	_adapter.bulb_row1_zone_path = _bulb_row1_zone.get_path()
	_scene.add_child(_adapter)
	
	_service = LightService.new()
	_adapter.setup(_service)

func after_test() -> void:
	_scene.free()

func _create_zone(rect: Rect2) -> Area2D:
	var area = Area2D.new()
	# Unique names to avoid path conflict
	area.name = "Zone_%d_%d" % [rect.position.x, rect.position.y]
	area.position = rect.position + rect.size * 0.5
	var shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	area.add_child(shape)
	var visual = ColorRect.new()
	visual.name = "LightVisual"
	visual.size = rect.size
	visual.position = -rect.size * 0.5
	area.add_child(visual)
	return area

func test_curtain_overlap() -> void:
	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	
	# Ratio 0: No light
	_service.set_curtain_open_ratio(0.0, "test")
	item.global_position = Vector2(50, 100)
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	
	# Ratio 1: Full light
	_service.set_curtain_open_ratio(1.0, "test")
	assert_bool(_adapter.is_item_in_light(item)).is_true()
	
	# Ratio 0.5: Half height (Vertical Center growth)
	# Zone Height 200. Center Y = 100.
	# At ratio 0.5, size Y = 100. Range: 100 - 50 = 50 to 100 + 50 = 150.
	_service.set_curtain_open_ratio(0.5, "test")
	
	# At center (50, 100) -> Should be inside.
	item.global_position = Vector2(50, 100)
	assert_bool(_adapter.is_item_in_light(item)).is_true()
	
	# At top edge of full zone (0) -> Outside active zone (50..150)
	item.global_position = Vector2(50, 10)
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	
	item.queue_free()

func test_bulb_overlap() -> void:
	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	
	# Bulb 0 (Row 0)
	# Zone: 200..300 x 0..100. Center 250, 50.
	item.global_position = Vector2(250, 50)
	
	# Off
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	
	# On
	_service.toggle_bulb(0, "test")
	assert_bool(_adapter.is_item_in_light(item)).is_true()
	
	# Toggle Off
	_service.toggle_bulb(0, "test")
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	
	item.queue_free()

func test_dragging_ignored() -> void:
	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	item.enter_drag_mode()
	
	_service.set_curtain_open_ratio(1.0, "test")
	item.global_position = Vector2(50, 100)
	
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	
	item.queue_free()

func test_which_sources() -> void:
	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	
	_service.set_curtain_open_ratio(1.0, "test")
	_service.toggle_bulb(0, "test")
	
	# Item in BOTH Curtain (0..100 x 0..200) and Bulb0? No, they don't overlap in my setup.
	# Curtain X: 0..100. Bulb0 X: 200..300.
	
	# Move item to Curtain
	item.global_position = Vector2(50, 100)
	assert_array(_adapter.which_sources_affect(item)).contains_exactly([LightZonesAdapter.CURTAIN_SOURCE_ID])
	
	# Move item to Bulb0
	item.global_position = Vector2(250, 50)
	assert_array(_adapter.which_sources_affect(item)).contains_exactly([LightZonesAdapter.BULB_SOURCE_ID_ROW0])
	
	item.queue_free()
