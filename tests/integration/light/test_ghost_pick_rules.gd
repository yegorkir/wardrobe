extends GdUnitTestSuite

const WorkdeskScene := preload("res://scenes/screens/WorkdeskScene.tscn")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

var _scene: Node
var _runner: GdUnitSceneRunner
var _light_service: LightService

func before_test() -> void:
	_scene = WorkdeskScene.instantiate()
	_runner = scene_runner(_scene)

func after_test() -> void:
	_scene.free()

func test_ghost_pick_blocked_in_darkness() -> void:
	# 1. Setup scene
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_light_service = _scene._light_service
	
	# Close curtains (darkness)
	_light_service.set_curtain_open_ratio(0.0, "test")
	
	# 2. Spawn ghost item
	# We need to inject a ghost item into the scene. 
	# WorkdeskScene exposes _world_adapter, we can use it to register an item.
	var item_id = StringName("test_ghost")
	
	# We need to ensure _get_item_archetype returns a ghost archetype for this ID.
	# Since _get_item_archetype is hardcoded in WorkdeskScene for now (per previous edit),
	# we can use the hardcoded ID "ghost_sheet".
	var ghost_id = StringName("ghost_sheet") # Matches the hardcoded check in WorkdeskScene
	
	# Register item instance manually or via run manager if accessible. 
	# But easiest is to mock the archetype lookup or use the existing "ghost_sheet" path.
	# Let's try to spawn a "ghost_sheet" item using the ItemSpawner or just injecting it.
	
	# Create a mock ItemInstance with correct archetype
	var instance = ItemInstanceScript.new(ghost_id, ItemInstance.KIND_COAT, ghost_id)
	
	# We need to spawn the visual node.
	# WorkdeskScene doesn't have a direct "spawn_item" public API that takes an instance easily 
	# without going through RunManager/ContentDB usually.
	
	# Hack: Interact with _item_visuals directly?
	# _item_visuals is initialized in _ready.
	
	# Let's assume we can add the item node manually and register it in _item_nodes map of dragdrop adapter.
	# This is getting complicated to setup "properly" without full RunManager.
	
	# Alternative: Test `_validate_pick_rule` directly on WorkdeskScene.
	# This avoids Input event simulation and DragDrop mechanics, focusing on the rule integration.
	
	# Mock the item node for light check
	var item_node = RigidBody2D.new()
	item_node.name = "GhostNode"
	_scene.add_child(item_node)
	item_node.global_position = Vector2(100, 100) # Assuming this pos is controlled
	
	# We need to fake the item instance on the node so _validate_pick_rule can find it
	item_node.set_script(preload("res://scripts/wardrobe/item_node.gd"))
	item_node.item_id = ghost_id
	item_node.set_item_instance(instance)
	
	# Register node in world adapter so _validate_pick_rule finds it in "spawned_items"
	# _world_adapter.get_spawned_items() returns an array.
	# We can't easily inject into that private array unless we use the public API.
	
	# WorkdeskScene._validate_pick_rule iterates _world_adapter.get_spawned_items().
	# WardrobeWorldSetupAdapter.get_spawned_items() returns _spawned_items array.
	
	# Let's try to pass the check by ensuring the node is in the tree and accessible?
	# No, _validate_pick_rule iterates: `for node in spawned:`. 
	# So we MUST get our node into that array.
	
	# WardrobeWorldSetupAdapter has `register_item_node(node)`.
	# But _world_adapter is private in WorkdeskScene, though exposed via `_world_adapter` var? 
	# Let's check WorkdeskScene.gd
	# `var _world_adapter := WardrobeWorldSetupAdapterScript.new()`
	# It is a script variable, so we can access it on `_scene`.
	
	_scene._world_adapter._spawned_items.append(item_node)
	
	# 3. Test Blocked (Darkness)
	# Position item in curtain zone but curtain is closed
	var curtain_zone = _scene.get_node("StorageHall/CurtainRig/CurtainZone")
	var shape = curtain_zone.get_node("CollisionShape2D")
	var rect = _scene._light_zones_adapter._get_global_rect(shape)
	# Place item in the top half, but not too close to the center gap
	item_node.global_position = rect.position + Vector2(rect.size.x * 0.5, 200)
	
	# Debug Step 3
	await get_tree().process_frame
	
	var allowed = _scene._validate_pick_rule(ghost_id)
	assert_bool(allowed).is_false()
	
	# 4. Test Allowed (Light)
	_light_service.set_curtain_open_ratio(1.0, "test")
	await get_tree().process_frame # Allow light adapter to update
	await get_tree().process_frame
	
	var allowed_light = _scene._validate_pick_rule(ghost_id)
	assert_bool(allowed_light).is_true()
