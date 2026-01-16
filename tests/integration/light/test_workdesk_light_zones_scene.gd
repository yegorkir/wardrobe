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
