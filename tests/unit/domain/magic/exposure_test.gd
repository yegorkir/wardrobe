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
const ExposureServiceScript := preload("res://scripts/domain/magic/exposure_service.gd")

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

func test_corruption_aura_self_exclusion() -> void:
	var service = CorruptionAuraServiceScript.new()
	var source = CorruptionAuraServiceScript.AuraSource.new(&"self", Vector2.ZERO, 100.0, 1.0)
	var targets = {
		&"self": Vector2.ZERO,
		&"other": Vector2(10, 0),
	}
	var results = service.calculate_exposure_rates(targets, [source])
	
	assert_float(results[&"self"].rate).is_equal(0.0)
	assert_bool(results[&"self"].sources.is_empty()).is_true()
	assert_float(results[&"other"].rate).is_equal(1.0)
	assert_array(results[&"other"].sources).contains_exactly([&"self"])

func test_zombie_domino_aura_propagation() -> void:
	var exposure = ExposureServiceScript.new()
	var zombie_id := StringName("zombie_source")
	var normal_a_id := StringName("normal_a")
	var normal_b_id := StringName("normal_b")
	
	var zombie_item = ItemInstanceScript.new(zombie_id, "COAT")
	var normal_a = ItemInstanceScript.new(normal_a_id, "COAT")
	var normal_b = ItemInstanceScript.new(normal_b_id, "COAT")
	
	var items = [zombie_item, normal_a, normal_b]
	var positions = {
		zombie_id: Vector2.ZERO,
		normal_a_id: Vector2(50, 0), # within zombie radius
		normal_b_id: Vector2(140, 0), # outside zombie radius, within weak aura
	}
	var drag_states = {
		zombie_id: false,
		normal_a_id: false,
		normal_b_id: false,
	}
	var light_states = {
		zombie_id: false,
		normal_a_id: false,
		normal_b_id: false,
	}
	var empty_sources: Array[StringName] = []
	var light_sources = {
		zombie_id: empty_sources,
		normal_a_id: empty_sources,
		normal_b_id: empty_sources,
	}
	var archetype_provider := Callable(self, "_get_domino_archetype").bind(zombie_id)
	
	# Tick 1: normal_a gets corrupted from zombie source, enabling weak aura.
	exposure.tick(items, positions, drag_states, light_states, light_sources, archetype_provider, 3.0)
	assert_float(normal_a.quality_state.current_stars).is_equal(2.0)
	assert_float(normal_b.quality_state.current_stars).is_equal(3.0)
	
	# Tick 2: normal_b gets corrupted via weak aura from normal_a.
	exposure.tick(items, positions, drag_states, light_states, light_sources, archetype_provider, 3.0)
	assert_float(normal_b.quality_state.current_stars).is_equal(2.0)

func _get_domino_archetype(item_id: StringName, zombie_id: StringName) -> ItemArchetypeDefinitionScript:
	if item_id == zombie_id:
		return ItemArchetypeDefinitionScript.new(zombie_id, false, true, 60.0)
	return null
