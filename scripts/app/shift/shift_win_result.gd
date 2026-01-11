extends RefCounted

class_name ShiftWinResult

var can_win: bool
var reason: StringName

func _init(can_win_value: bool, reason_value: StringName) -> void:
	can_win = can_win_value
	reason = reason_value

func duplicate_result() -> ShiftWinResult:
	return get_script().new(can_win, reason) as ShiftWinResult
