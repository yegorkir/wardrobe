extends GdUnitTestSuite

const ItemNodeScript := preload("res://scripts/wardrobe/item_node.gd")
const ItemScene := preload("res://scenes/prefabs/item_node.tscn")
const WorkdeskScene := preload("res://scenes/screens/WorkdeskScene.tscn")

var _scene: Node2D
var _adapter: LightZonesAdapter
var _service: LightService

func before_test() -> void:
	_scene = WorkdeskScene.instantiate()
	add_child(_scene)
	_adapter = _scene.get_node("StorageHall/LightZonesAdapter") as LightZonesAdapter

func after_test() -> void:
	_scene.free()

func test_workdesk_curtain_zone_path() -> void:
	assert_object(_adapter).is_not_null()
	var zone_shape := _scene.get_node("StorageHall/CurtainRig/CurtainZone/CollisionShape2D") as CollisionShape2D
	assert_object(zone_shape).is_not_null()

	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame

	await get_tree().process_frame
	_service = _scene._light_service
	assert_object(_service).is_not_null()
	_service.set_curtain_open_ratio(1.0, "test")
	item.global_position = zone_shape.global_position

	assert_bool(_adapter.is_item_in_light(item)).is_true()
	item.queue_free()

func test_workdesk_service_light_rig_wiring() -> void:
	var rig := _scene.get_node("ServiceZone/LightZone/BulbLightRig") as BulbLightRig
	assert_object(rig).is_not_null()
	var service_zone_rig := _scene.get_node("ServiceZone/ServiceLightZone") as BulbLightRig
	assert_object(service_zone_rig).is_not_null()
	var visual := rig.get_node("Visual") as CanvasItem
	assert_object(visual).is_not_null()
	var light_visual := rig.get_node("LightZone/CollisionShape2D/LightVisual") as CanvasItem
	assert_object(light_visual).is_not_null()
	var zone_shape := _scene.get_node("ServiceZone/ServiceLightZone/LightZone/CollisionShape2D") as CollisionShape2D
	assert_object(zone_shape).is_not_null()
	var rect_shape := zone_shape.shape as RectangleShape2D
	assert_object(rect_shape).is_not_null()

	await get_tree().process_frame
	await get_tree().process_frame
	_service = _scene._light_service
	assert_object(_service).is_not_null()
	assert_float(rect_shape.size.x).is_equal_approx(service_zone_rig.zone_width, 0.01)
	assert_float(rect_shape.size.y).is_equal_approx(service_zone_rig.zone_height, 0.01)
	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	item.global_position = zone_shape.global_position
	assert_bool(_adapter.is_item_in_light(item)).is_false()

	_service.toggle_bulb(rig.row_index, "test")
	await get_tree().process_frame
	assert_bool(visual.modulate.is_equal_approx(rig.on_color)).is_true()
	assert_bool(light_visual.visible).is_true()
	assert_bool(_service.is_bulb_on(0)).is_false()
	assert_bool(_adapter.is_item_in_light(item)).is_true()

	_service.toggle_bulb(rig.row_index, "test")
	await get_tree().process_frame
	assert_bool(visual.modulate.is_equal_approx(rig.off_color)).is_true()
	assert_bool(light_visual.visible).is_false()
	assert_bool(_service.is_bulb_on(0)).is_false()
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	item.queue_free()

func test_workdesk_service_light_affects_desk_slot() -> void:
	var anchor := _scene.get_node("ServiceZone/ServiceSlots/Desk_A/ClientDropZone/DeskLayout/ClientTray/TraySlot_0/ItemAnchor") as Node2D
	assert_object(anchor).is_not_null()

	await get_tree().process_frame
	await get_tree().process_frame
	_service = _scene._light_service
	assert_object(_service).is_not_null()
	assert_bool(_adapter._service_rect.has_area()).is_true()
	assert_bool(_adapter._service_rect.has_point(anchor.global_position)).is_true()

	var item = ItemScene.instantiate() as ItemNodeScript
	_scene.add_child(item)
	await get_tree().process_frame
	item.global_position = anchor.global_position

	assert_bool(_adapter.is_item_in_light(item)).is_false()
	_service.toggle_bulb(2, "test")
	await get_tree().process_frame
	assert_bool(_adapter.is_item_in_light(item)).is_true()
	_service.toggle_bulb(2, "test")
	await get_tree().process_frame
	assert_bool(_adapter.is_item_in_light(item)).is_false()
	item.queue_free()
