extends GdUnitTestSuite

const MagicSystemScript := preload("res://scripts/sim/magic_system.gd")

func test_apply_insurance_registers_magic_links() -> void:
	var magic_system := MagicSystemScript.new()
	var custom_config := {
		"insurance_mode": MagicSystemScript.INSURANCE_MODE_SOFT_LIMIT,
		"insurance_cost": 5,
		"soft_limit": 3,
	}
	magic_system.setup(custom_config)
	var run_state := {
		"magic_links": {},
	}
	var result: Dictionary = magic_system.apply_insurance(run_state, 42, ["item_a", "item_b"])
	assert_that(result.get("ticket_number")).is_equal(42)
	assert_that(result.get("items")).is_equal(["item_a", "item_b"])
	assert_that(result.get("mode")).is_equal(MagicSystemScript.INSURANCE_MODE_SOFT_LIMIT)
	assert_that(result.get("cost")).is_equal(5)
	var stored_links: Dictionary = run_state.get("magic_links", {})
	assert_that(stored_links.has(42)).is_true()
	assert_that(stored_links[42]).is_equal(["item_a", "item_b"])

func test_request_emergency_locate_uses_configured_cost() -> void:
	var magic_system := MagicSystemScript.new()
	var config := {
		"emergency_cost_mode": MagicSystemScript.EMERGENCY_COST_SHIFT_CASH,
		"emergency_cost_value": 12,
		"search_effect": "SPOTLIGHT",
	}
	magic_system.setup(config)
	var result: Dictionary = magic_system.request_emergency_locate({}, 7)
	assert_that(result.get("ticket_number")).is_equal(7)
	assert_that(result.get("cost_type")).is_equal(MagicSystemScript.EMERGENCY_COST_SHIFT_CASH)
	assert_that(result.get("cost_value")).is_equal(12)
	assert_that(result.get("mode")).is_equal("SPOTLIGHT")
