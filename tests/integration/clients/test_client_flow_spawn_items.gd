# GdUnit generated TestSuite
extends GdUnitTestSuite

const WorkdeskScene := preload("res://scenes/screens/WorkdeskScene.tscn")
const ClientSpawnRequestScript := preload("res://scripts/app/clients/client_spawn_request.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

var _scene: Node2D

func before_test() -> void:
	_scene = WorkdeskScene.instantiate()
	add_child(_scene)

func after_test() -> void:
	if _scene:
		_scene.free()

func test_director_checkin_spawns_tray_item() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_scene._world_adapter.clear_spawned_items()
	_scene._world_adapter.get_clients().clear()
	var queue_state: ClientQueueState = _scene._world_adapter.get_client_queue_state() as ClientQueueState
	if queue_state:
		queue_state.clear()
	for desk_state in _scene._world_adapter.get_desk_states():
		if desk_state != null:
			desk_state.current_client_id = StringName()

	var coats_before := _count_spawned_kind(ItemInstanceScript.KIND_COAT)

	var request := ClientSpawnRequestScript.new(ClientSpawnRequest.Type.CHECKIN, "test")
	_scene._on_client_spawn_requested(request)

	var desk_states: Array = _scene._world_adapter.get_desk_states() as Array
	assert_bool(desk_states.is_empty()).is_false()
	var desk_state = desk_states[0]
	var desk_system: DeskServicePointSystem = _scene._world_adapter.get_desk_system() as DeskServicePointSystem
	var events: Array = desk_system.assign_next_client_to_desk(
		desk_state,
		queue_state,
		_scene._world_adapter.get_clients(),
		_scene._storage_state
	)
	_scene._interaction_events.apply_desk_events(events)
	await get_tree().process_frame

	var coats_after := _count_spawned_kind(ItemInstanceScript.KIND_COAT)
	assert_int(coats_after).is_greater(coats_before)

func _count_spawned_kind(kind: StringName) -> int:
	var count := 0
	for node in _scene._world_adapter.get_spawned_items():
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_item_instance"):
			continue
		var instance = node.get_item_instance()
		if instance != null and instance.kind == kind:
			count += 1
	return count
