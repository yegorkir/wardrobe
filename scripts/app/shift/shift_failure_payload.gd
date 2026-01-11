extends RefCounted

class_name ShiftFailurePayload

var reason: StringName
var strikes_current: int
var strikes_limit: int

func _init(reason_value: StringName, strikes_current_value: int, strikes_limit_value: int) -> void:
	reason = reason_value
	strikes_current = strikes_current_value
	strikes_limit = strikes_limit_value

func duplicate_payload() -> ShiftFailurePayload:
	return get_script().new(reason, strikes_current, strikes_limit) as ShiftFailurePayload
