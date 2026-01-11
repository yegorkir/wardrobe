extends GdUnitTestSuite

const MagicSystemScript := preload("res://scripts/domain/magic/magic_system.gd")
const MagicConfigScript := preload("res://scripts/domain/magic/magic_config.gd")
const RunStateScript := preload("res://scripts/domain/run/run_state.gd")

func test_apply_insurance_registers_magic_links() -> void:
	var magic_system := MagicSystemScript.new()
	var custom_config := MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_SOFT_LIMIT,
		MagicSystemScript.EMERGENCY_COST_DEBT,
		5,
		0,
		3,
		MagicSystemScript.SEARCH_EFFECT_REVEAL_SLOT
	)
	magic_system.setup(custom_config)
	var run_state := RunStateScript.new()
	var result := magic_system.apply_insurance(
		run_state,
		42,
		[StringName("item_a"), StringName("item_b")]
	)
	assert_that(result.ticket_number).is_equal(42)
	assert_that(result.items).is_equal([StringName("item_a"), StringName("item_b")])
	assert_that(result.mode).is_equal(MagicSystemScript.INSURANCE_MODE_SOFT_LIMIT)
	assert_that(result.cost_value).is_equal(5)
	var stored_links: Dictionary = run_state.get_magic_links()
	assert_that(stored_links.has(42)).is_true()
	assert_that(stored_links[42]).is_equal([StringName("item_a"), StringName("item_b")])

func test_request_emergency_locate_uses_configured_cost() -> void:
	var magic_system := MagicSystemScript.new()
	var config := MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_FREE,
		MagicSystemScript.EMERGENCY_COST_SHIFT_CASH,
		0,
		12,
		0,
		StringName("SPOTLIGHT")
	)
	magic_system.setup(config)
	var run_state := RunStateScript.new()
	var result := magic_system.request_emergency_locate(run_state, 7)
	assert_that(result.ticket_number).is_equal(7)
	assert_that(result.cost_type).is_equal(MagicSystemScript.EMERGENCY_COST_SHIFT_CASH)
	assert_that(result.cost_value).is_equal(12)
	assert_that(result.mode).is_equal(StringName("SPOTLIGHT"))
