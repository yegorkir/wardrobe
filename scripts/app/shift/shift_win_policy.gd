extends RefCounted

class_name ShiftWinPolicy

const RunStateScript := preload("res://scripts/domain/run/run_state.gd")

const REASON_ALL_CLIENTS_SERVED := StringName("all_clients_served")
const REASON_ACTIVE_CLIENTS := StringName("active_clients_remaining")
const REASON_SHIFT_FAILED := StringName("shift_failed")
const REASON_NO_TARGET := StringName("no_target_clients")

func evaluate(shift_status: StringName, served_clients: int, total_clients: int, active_clients: int) -> Dictionary:
	if shift_status == RunStateScript.SHIFT_STATUS_FAILED:
		return {
			"can_win": false,
			"reason": REASON_SHIFT_FAILED,
		}
	if total_clients <= 0:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	if served_clients < total_clients:
		return {
			"can_win": false,
			"reason": REASON_NO_TARGET,
		}
	if active_clients > 0:
		return {
			"can_win": false,
			"reason": REASON_ACTIVE_CLIENTS,
		}
	return {
		"can_win": true,
		"reason": REASON_ALL_CLIENTS_SERVED,
	}
