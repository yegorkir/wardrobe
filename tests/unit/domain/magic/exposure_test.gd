# tests/unit/domain/magic/exposure_test.gd
extends GdUnitTestSuite

const VampireExposureSystemScript := preload("res://scripts/domain/magic/vampire_exposure_system.gd")
const ZombieExposureSystemScript := preload("res://scripts/domain/magic/zombie_exposure_system.gd")
const VampireExposureStateScript := preload("res://scripts/domain/magic/vampire_exposure_state.gd")
const ZombieExposureStateScript := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const ItemArchetypeDefinitionScript := preload("res://scripts/domain/content/item_archetype_definition.gd")
const ItemEffectTypesScript := preload("res://scripts/domain/effects/item_effect_types.gd")
const CorruptionAuraServiceScript := preload("res://scripts/domain/magic/corruption_aura_service.gd")

func test_vampire_exposure_accumulation() -> void:
	var system = VampireExposureSystemScript.new()
	var state = VampireExposureStateScript.new()
	var item = ItemInstanceScript.new("test_vampire", "COAT")
	var arch = ItemArchetypeDefinitionScript.new("vampire_cloak", true, false)
	
	# Tick in light
	system.tick(state, item, arch, true, [], false, 0.5)
	assert_float(state.current_stage_exposure).is_equal(0.5)
	
	# Tick in light more
	system.tick(state, item, arch, true, [], false, 0.4)
	assert_float(state.current_stage_exposure).is_equal(0.9)
	
	# Drag resets
	system.tick(state, item, arch, true, [], true, 0.1)
	assert_float(state.current_stage_exposure).is_equal(0.0)
	
	# Not in light resets
	system.tick(state, item, arch, true, [], false, 0.5)
	assert_float(state.current_stage_exposure).is_equal(0.5)
	system.tick(state, item, arch, false, [], false, 0.1)
	assert_float(state.current_stage_exposure).is_equal(0.0)

func test_vampire_effect_application() -> void:
	var system = VampireExposureSystemScript.new()
	var state = VampireExposureStateScript.new()
	var item = ItemInstanceScript.new("test_vampire", "COAT")
	var arch = ItemArchetypeDefinitionScript.new("vampire_cloak", true, false)
	
	# Initial quality
	assert_float(item.quality_state.current_stars).is_equal(3.0)
	
	# Reach threshold (1.0)
	system.tick(state, item, arch, true, [], false, 1.0)
	assert_int(state.stage_index).is_equal(1)
	assert_float(state.current_stage_exposure).is_equal(0.0)
	
	# Check quality loss (1 star)
	assert_float(item.quality_state.current_stars).is_equal(2.0)

func test_zombie_exposure_accumulation() -> void:
	var system = ZombieExposureSystemScript.new()
	var state = ZombieExposureStateScript.new()
	var item = ItemInstanceScript.new("test_normal", "COAT")
	
	# Tick with rate
	system.tick(state, item, 1.0, [], false, 0.5)
	assert_float(state.current_stage_exposure).is_equal(0.5)
	
	# Drag resets
	system.tick(state, item, 1.0, [], true, 0.1)
	assert_float(state.current_stage_exposure).is_equal(0.0)
	
	# Rate 0 resets
	system.tick(state, item, 1.0, [], false, 0.5)
	system.tick(state, item, 0.0, [], false, 0.1)
	assert_float(state.current_stage_exposure).is_equal(0.0)

func test_zombie_effect_and_propagation() -> void:
	var system = ZombieExposureSystemScript.new()
	var state = ZombieExposureStateScript.new()
	var item = ItemInstanceScript.new("test_normal", "COAT")
	
	assert_bool(state.is_emitting_weak_aura).is_false()
	assert_float(item.quality_state.current_stars).is_equal(3.0)
	
	# Reach threshold (3.0)
	system.tick(state, item, 1.0, [&"zombie_1"], false, 3.0)
	
	assert_int(state.stage_index).is_equal(1)
	assert_bool(state.is_emitting_weak_aura).is_true()
	assert_float(item.quality_state.current_stars).is_equal(2.0)

func test_corruption_aura_service() -> void:
	var service = CorruptionAuraServiceScript.new()
	var source = CorruptionAuraServiceScript.AuraSource.new(&"s1", Vector2(0, 0), 100.0, 1.0)
	
	var targets = {
		"near": Vector2(10, 0),
		"far": Vector2(200, 0),
		"edge": Vector2(99, 0)
	}
	
	var results = service.calculate_exposure_rates(targets, [source])
	
	assert_float(results["near"].rate).is_equal(1.0)
	assert_array(results["near"].sources).contains_exactly([&"s1"])
	assert_float(results["far"].rate).is_equal(0.0)
	assert_float(results["edge"].rate).is_equal(1.0)
	
	# Stacking and Cap
	var source2 = CorruptionAuraServiceScript.AuraSource.new(&"s2", Vector2(10, 0), 100.0, 1.0)
	var source3 = CorruptionAuraServiceScript.AuraSource.new(&"s3", Vector2(20, 0), 100.0, 1.0)
	var source4 = CorruptionAuraServiceScript.AuraSource.new(&"s4", Vector2(30, 0), 100.0, 1.0)
	
	var stacked_results = service.calculate_exposure_rates(targets, [source, source2, source3, source4])
	
	# 4 sources overlapping "near"
	assert_float(stacked_results["near"].rate).is_equal(3.0) # Cap at 3.0
	assert_int(stacked_results["near"].sources.size()).is_equal(4)
