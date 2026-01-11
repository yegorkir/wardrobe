extends GdUnitTestSuite

const ShiftWinPolicyScript := preload("res://scripts/app/shift/shift_win_policy.gd")
const RunStateScript := preload("res://scripts/domain/run/run_state.gd")

func test_win_when_all_clients_served_and_no_active() -> void:
	var policy := ShiftWinPolicyScript.new()
	var result := policy.evaluate(RunStateScript.SHIFT_STATUS_RUNNING, 3, 3, 0)
	assert_bool(bool(result.get("can_win", false))).is_true()

func test_no_win_when_active_clients_remaining() -> void:
	var policy := ShiftWinPolicyScript.new()
	var result := policy.evaluate(RunStateScript.SHIFT_STATUS_RUNNING, 3, 3, 1)
	assert_bool(bool(result.get("can_win", true))).is_false()

func test_no_win_when_failed() -> void:
	var policy := ShiftWinPolicyScript.new()
	var result := policy.evaluate(RunStateScript.SHIFT_STATUS_FAILED, 3, 3, 0)
	assert_bool(bool(result.get("can_win", true))).is_false()
