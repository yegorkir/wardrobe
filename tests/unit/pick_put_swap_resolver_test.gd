extends GdUnitTestSuite

const Resolver := preload("res://scripts/app/interaction/pick_put_swap_resolver.gd")

func test_resolver_returns_expected_actions() -> void:
	var resolver := Resolver.new()
	var cases := [
		{ "hand": false, "slot": false, "action": Resolver.ACTION_NONE, "success": false },
		{ "hand": false, "slot": true, "action": Resolver.ACTION_PICK, "success": true },
		{ "hand": true, "slot": false, "action": Resolver.ACTION_PUT, "success": true },
		{ "hand": true, "slot": true, "action": Resolver.ACTION_SWAP, "success": true },
	]
	for case_data in cases:
		var result := resolver.resolve(case_data.hand, case_data.slot)
		assert_that(result.get("action")).is_equal(case_data.action)
		assert_that(result.get("success", false)).is_equal(case_data.success)

func test_resolver_reason_when_no_action() -> void:
	var resolver := Resolver.new()
	var result := resolver.resolve(false, false)
	assert_that(result.get("reason", "")).is_equal("nothing_to_do")
