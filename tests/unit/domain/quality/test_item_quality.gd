extends GdUnitTestSuite

const ItemQualityConfigScript := preload("res://scripts/domain/quality/item_quality_config.gd")
const ItemQualityStateScript := preload("res://scripts/domain/quality/item_quality_state.gd")
const ItemQualityServiceScript := preload("res://scripts/domain/quality/item_quality_service.gd")

func test_initialization() -> void:
	var config = ItemQualityConfigScript.new(5)
	var state = ItemQualityStateScript.new(config)
	
	assert_float(state.current_stars).is_equal(5.0)
	assert_int(state.max_stars).is_equal(5)

func test_clamping() -> void:
	var config = ItemQualityConfigScript.new(3)
	
	# Test overflow initialization
	var state_high = ItemQualityStateScript.new(config, 10.0)
	assert_float(state_high.current_stars).is_equal(3.0)
	
	# Test explicit zero
	var state_low = ItemQualityStateScript.new(config, 0.0)
	assert_float(state_low.current_stars).is_equal(0.0)

func test_apply_damage() -> void:
	var config = ItemQualityConfigScript.new(5)
	config.set("allowed_steps", [0.5, 1.0])
	var state = ItemQualityStateScript.new(config) # Starts at 5.0
	
	# Apply 1.0 damage
	var result = ItemQualityServiceScript.apply_damage(state, "fall", 1.0)
	assert_float(result.get("old_stars")).is_equal(5.0)
	assert_float(result.get("new_stars")).is_equal(4.0)
	assert_str(result.get("source")).is_equal("fall")
	assert_float(state.current_stars).is_equal(4.0)
	
	# Apply 0.7 damage -> quantized to 0.5 (largest step <= 0.7)
	# allowed_steps [0.5, 1.0]
	result = ItemQualityServiceScript.apply_damage(state, "fall", 0.7)
	assert_float(state.current_stars).is_equal(3.5) # 4.0 - 0.5
	
	# Apply 0.4 damage -> quantized to 0.0
	result = ItemQualityServiceScript.apply_damage(state, "fall", 0.4)
	assert_float(state.current_stars).is_equal(3.5) # Unchanged

func test_damage_clamping() -> void:
	var config = ItemQualityConfigScript.new(3)
	var state = ItemQualityStateScript.new(config, 0.5)
	
	# Apply 1.0 damage -> should clamp at 0
	ItemQualityServiceScript.apply_damage(state, "fall", 1.0)
	assert_float(state.current_stars).is_equal(0.0)