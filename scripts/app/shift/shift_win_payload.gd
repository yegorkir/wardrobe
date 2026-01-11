extends RefCounted

class_name ShiftWinPayload

var checkin_done: int
var checkout_done: int
var target_checkin: int
var target_checkout: int

func _init(
	checkin_done_value: int,
	checkout_done_value: int,
	target_checkin_value: int,
	target_checkout_value: int
) -> void:
	checkin_done = checkin_done_value
	checkout_done = checkout_done_value
	target_checkin = target_checkin_value
	target_checkout = target_checkout_value

func duplicate_payload() -> ShiftWinPayload:
	return get_script().new(
		checkin_done,
		checkout_done,
		target_checkin,
		target_checkout
	) as ShiftWinPayload
