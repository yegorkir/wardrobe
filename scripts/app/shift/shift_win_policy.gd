extends RefCounted

class_name ShiftWinPolicy

const RunStateScript := preload("res://scripts/domain/run/run_state.gd")

const REASON_ALL_TARGETS_MET := StringName("all_targets_met")
const REASON_SHIFT_FAILED := StringName("shift_failed")
const REASON_NO_TARGET := StringName("no_target_clients")

func evaluate(run_state: RunState) -> Dictionary:
	if run_state == null:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	if run_state.shift_status == RunStateScript.SHIFT_STATUS_FAILED:
		return {
			"can_win": false,
			"reason": REASON_SHIFT_FAILED,
		}
	if run_state.target_checkin <= 0 and run_state.target_checkout <= 0:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	if run_state.checkin_done < run_state.target_checkin:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	if run_state.checkout_done < run_state.target_checkout:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	return {
		"can_win": true,
		"reason": REASON_ALL_TARGETS_MET,
	}
