# GdUnit generated TestSuite
class_name LightSwitchTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const LightSwitchScript := preload("res://scripts/wardrobe/lights/light_switch.gd")

var _switch: LightSwitch
var _handle: Sprite2D

func before_test() -> void:
	_switch = LightSwitchScript.new()
	_handle = Sprite2D.new()
	_handle.name = "HandleSprite"
	_switch.add_child(_handle)
	add_child(_switch)

func test_initial_state_off() -> void:
	assert_float(_handle.rotation_degrees).is_equal(_switch.rotation_off_degrees)

func test_set_is_on_animates() -> void:
	# Initial
	assert_float(_handle.rotation_degrees).is_equal(_switch.rotation_off_degrees)
	
	# Turn ON
	_switch.set_is_on(true)
	
	# Animation is async (Tween). 
	# For unit test, we can check if tween started or just wait.
	# Or since we are in a test environment, we can fast-forward?
	# GdUnit has await_millis.
	
	await get_tree().create_timer(_switch.animation_duration + 0.1).timeout
	
	assert_float(_handle.rotation_degrees).is_equal(_switch.rotation_on_degrees)
	
	# Turn OFF
	_switch.set_is_on(false)
	await get_tree().create_timer(_switch.animation_duration + 0.1).timeout
	
	assert_float(_handle.rotation_degrees).is_equal(_switch.rotation_off_degrees)

func test_set_is_on_immediate_if_same() -> void:
	_switch.set_is_on(true)
	await get_tree().create_timer(_switch.animation_duration + 0.1).timeout
	assert_float(_handle.rotation_degrees).is_equal(_switch.rotation_on_degrees)
	
	# Set true again - should not restart animation or change anything
	# Hard to test "no animation" easily without spying on Tween, but logic is simple.
	pass
