extends GdUnitTestSuite

const ShiftWinPolicyScript := preload("res://scripts/app/shift/shift_win_policy.gd")
const RunStateScript := preload("res://scripts/domain/run/run_state.gd")

func test_win_when_checkin_and_checkout_targets_met() -> void:
	var policy := ShiftWinPolicyScript.new()
	var run_state := RunStateScript.new()
	run_state.shift_status = RunStateScript.SHIFT_STATUS_RUNNING
	run_state.configure_shift_targets(6, 4)
	run_state.checkin_done = 6
	run_state.checkout_done = 4
	var result := policy.evaluate(run_state)
	assert_bool(bool(result.get("can_win", false))).is_true()

func test_no_win_when_checkin_below_target() -> void:
	var policy := ShiftWinPolicyScript.new()
	var run_state := RunStateScript.new()
	run_state.shift_status = RunStateScript.SHIFT_STATUS_RUNNING
	run_state.configure_shift_targets(6, 4)
	run_state.checkin_done = 5
	run_state.checkout_done = 4
	var result := policy.evaluate(run_state)
	assert_bool(bool(result.get("can_win", true))).is_false()

func test_no_win_when_shift_failed() -> void:
	var policy := ShiftWinPolicyScript.new()
	var run_state := RunStateScript.new()
	run_state.shift_status = RunStateScript.SHIFT_STATUS_FAILED
	run_state.configure_shift_targets(6, 4)
	run_state.checkin_done = 6
	run_state.checkout_done = 4
	var result := policy.evaluate(run_state)
	assert_bool(bool(result.get("can_win", true))).is_false()
