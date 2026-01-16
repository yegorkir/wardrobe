# GdUnit generated TestSuite
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const BulbLightRigScript := preload("res://scripts/wardrobe/lights/bulb_light_rig.gd")
const LightServiceScript := preload("res://scripts/app/light/light_service.gd")

var _rig: BulbLightRig
var _internal_visual: ColorRect
var _external_visual: ColorRect
var _light_service: LightService
var _container: Node2D

func before_test() -> void:
	if _container:
		_container.free()
		_container = null

func _create_rig() -> void:
	_container = Node2D.new()
	add_child(_container)
	
	_rig = BulbLightRigScript.new()
	_rig.name = "Rig"
	
	_internal_visual = ColorRect.new()
	_internal_visual.name = "Visual"
	_rig.add_child(_internal_visual)
	
	var zone = Area2D.new()
	zone.name = "LightZone"
	var col = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	col.shape = RectangleShape2D.new()
	var light_visual = ColorRect.new()
	light_visual.name = "LightVisual"
	col.add_child(light_visual)
	zone.add_child(col)
	_rig.add_child(zone)
	
	_container.add_child(_rig)
	
	_light_service = auto_free(LightServiceScript.new(Callable()))
	_rig.setup(_light_service)

func test_external_visual_connection() -> void:
	_create_rig()
	
	_external_visual = ColorRect.new()
	_external_visual.name = "ExternalVisual"
	_container.add_child(_external_visual)
	
	# Initial state
	assert_bool(_internal_visual.visible).is_true()
	
	# Connect
	_rig.external_visual_path = _rig.get_path_to(_external_visual)
	
	# Behavior check
	assert_bool(_internal_visual.visible).is_false()
	assert_bool(_external_visual.visible).is_true()
	
	# Ensure no modulation on external visual (it shouldn't be touched)
	var original_mod = _external_visual.modulate
	_rig._toggle()
	assert_object(_external_visual.modulate).is_equal(original_mod)

func test_unhandled_input_external() -> void:
	_create_rig()
	
	_external_visual = ColorRect.new()
	_external_visual.name = "ExternalVisual"
	_external_visual.position = Vector2(100, 100)
	_container.add_child(_external_visual)
	
	_rig.external_visual_path = _rig.get_path_to(_external_visual)
	
	# Click on external visual pos (100, 100 global)
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(100, 100)
	
	_rig._unhandled_input(event)
	assert_bool(_light_service.is_bulb_on(0)).is_true()
	
	# Click far away
	event.position = Vector2(0, 0)
	_rig._toggle() # Reset to off
	_rig._unhandled_input(event)
	assert_bool(_light_service.is_bulb_on(0)).is_false()

func test_external_visual_with_callback() -> void:
	_create_rig()
	
	# Create a smart external visual (mock)
	var script = GDScript.new()
	script.source_code = "extends Node2D\nvar state = false\nfunc set_is_on(val):\n\tstate = val"
	script.reload()
	
	var smart_visual = Node2D.new()
	smart_visual.set_script(script)
	smart_visual.name = "SmartVisual"
	_container.add_child(smart_visual)
	
	_rig.external_visual_path = _rig.get_path_to(smart_visual)
	
	# Initial state check (should not be called yet or defaults false)
	assert_bool(smart_visual.get("state")).is_false()
	
	# Toggle ON
	_rig._toggle()
	assert_bool(smart_visual.get("state")).is_true()
	
	# Toggle OFF
	_rig._toggle()
	assert_bool(smart_visual.get("state")).is_false()
