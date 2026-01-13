# tests/unit/domain/magic/test_aura_transfer_delay.gd
extends GdUnitTestSuite

const ExposureServiceScript := preload("res://scripts/domain/magic/exposure_service.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const ItemArchetypeDefinitionScript := preload("res://scripts/domain/content/item_archetype_definition.gd")
const ZombieExposureStateScript := preload("res://scripts/domain/magic/zombie_exposure_state.gd")

var _exposure: ExposureServiceScript

func before_test() -> void:
	_exposure = ExposureServiceScript.new()

func test_transfer_delay_prevents_immediate_corruption() -> void:
	var zombie_id := &"zombie"
	var target_id := &"target"
	
	var zombie_item = ItemInstanceScript.new(zombie_id, "COAT")
	var target_item = ItemInstanceScript.new(target_id, "COAT")
	
	var items = [zombie_item, target_item]
	var positions = {
		zombie_id: Vector2.ZERO,
		target_id: Vector2(50, 0), # dist 50 -> t = 0.5
	}
	var drag_states = {zombie_id: false, target_id: false}
	var empty_dict := {}
	var empty_str_array: Array[StringName] = []
	var empty_sources := {zombie_id: empty_str_array, target_id: empty_str_array}
	
	var archetype_provider = func(id):
		if id == zombie_id:
			return ItemArchetypeDefinitionScript.new(zombie_id, false, true, 3)
		return null
	
	# Tick for 0.4s (less than t=0.5)
	_exposure.tick(items, positions, drag_states, empty_dict, empty_sources, archetype_provider, 0.4)
	
	var z_state = _exposure._item_states[target_id]["zombie"] as ZombieExposureStateScript
	assert_float(z_state.current_stage_exposure).is_equal(0.0)
	assert_bool(z_state.is_active(zombie_id)).is_false()
	
	# Tick for another 0.2s (total 0.6s > 0.5s)
	# In this tick of 0.2s, 0.1s was pending, 0.1s was active.
	# Exposure should be 1.0 * 0.1 = 0.1
	_exposure.tick(items, positions, drag_states, empty_dict, empty_sources, archetype_provider, 0.2)
	
	assert_float(z_state.current_stage_exposure).is_equal_approx(0.1, 0.001)
	assert_bool(z_state.is_active(zombie_id)).is_true()

func test_multiple_sources_staggered_activation() -> void:
	var z1_id := &"z1"
	var z2_id := &"z2"
	var target_id := &"target"
	
	var items = [
		ItemInstanceScript.new(z1_id, "COAT"),
		ItemInstanceScript.new(z2_id, "COAT"),
		ItemInstanceScript.new(target_id, "COAT")
	]
	
	var positions = {
		z1_id: Vector2.ZERO,
		z2_id: Vector2(150, 0), # dist 150 -> t = 1.5
		target_id: Vector2(50, 0), # dist to z1: 50 (t=0.5), dist to z2: 100 (t=1.0)
	}
	
	var drag_states = {z1_id: false, z2_id: false, target_id: false}
	var empty_dict := {}
	var empty_str_array: Array[StringName] = []
	var empty_sources := {z1_id: empty_str_array, z2_id: empty_str_array, target_id: empty_str_array}
	
	var archetype_provider = func(id):
		if id == z1_id or id == z2_id:
			return ItemArchetypeDefinitionScript.new(id, false, true, 200.0)
		return null
		
	# Tick 0.4s: none active
	_exposure.tick(items, positions, drag_states, empty_dict, empty_sources, archetype_provider, 0.4)
	var z_state = _exposure._item_states[target_id]["zombie"] as ZombieExposureStateScript
	assert_float(z_state.current_stage_exposure).is_equal(0.0)
	
	# Tick 0.3s (total 0.7s): z1 active for 0.2s, z2 still pending (0.3s remaining)
	_exposure.tick(items, positions, drag_states, empty_dict, empty_sources, archetype_provider, 0.3)
	assert_float(z_state.current_stage_exposure).is_equal_approx(0.2, 0.001)
	assert_bool(z_state.is_active(z1_id)).is_true()
	assert_bool(z_state.is_active(z2_id)).is_false()
	
	# Tick 0.5s (total 1.2s): 
	# z1 active for full 0.5s -> 0.5 exposure
	# z2 was pending for 0.3s, active for 0.2s -> 0.2 exposure
	# Total new exposure = 0.7. Total = 0.2 + 0.7 = 0.9
	_exposure.tick(items, positions, drag_states, empty_dict, empty_sources, archetype_provider, 0.5)
	assert_float(z_state.current_stage_exposure).is_equal_approx(0.9, 0.001)
	assert_bool(z_state.is_active(z1_id)).is_true()
	assert_bool(z_state.is_active(z2_id)).is_true()

func test_exit_and_reenter_resets_pending() -> void:
	var zombie_id := &"zombie"
	var target_id := &"target"
	
	var items = [ItemInstanceScript.new(zombie_id, "COAT"), ItemInstanceScript.new(target_id, "COAT")]
	var drag_states = {zombie_id: false, target_id: false}
	var empty_dict := {}
	var empty_str_array: Array[StringName] = []
	var empty_sources := {zombie_id: empty_str_array, target_id: empty_str_array}
	
	var archetype_provider = func(id):
		if id == zombie_id:
			return ItemArchetypeDefinitionScript.new(zombie_id, false, true, 100.0)
		return null
		
	# Enter aura
	var pos_in = { zombie_id: Vector2.ZERO, target_id: Vector2(50, 0) } # t=0.5
	_exposure.tick(items, pos_in, drag_states, empty_dict, empty_sources, archetype_provider, 0.3)
	
	var z_state = _exposure._item_states[target_id]["zombie"] as ZombieExposureStateScript
	assert_float(z_state.pending_transfers[zombie_id]).is_equal_approx(0.2, 0.001)
	
	# Exit aura
	var pos_out = { zombie_id: Vector2.ZERO, target_id: Vector2(10000, 0) }
	_exposure.tick(items, pos_out, drag_states, empty_dict, empty_sources, archetype_provider, 0.1)
	assert_bool(z_state.pending_transfers.has(zombie_id)).is_false()
	
	# Re-enter
	_exposure.tick(items, pos_in, drag_states, empty_dict, empty_sources, archetype_provider, 0.1)
	assert_float(z_state.pending_transfers[zombie_id]).is_equal_approx(0.4, 0.001)
