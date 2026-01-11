extends RefCounted

class_name ShiftHudSnapshot

var wave: int
var time: int
var money: int
var magic: int
var debt: int
var strikes_current: int
var strikes_limit: int

func _init(
	wave_value: int,
	time_value: int,
	money_value: int,
	magic_value: int,
	debt_value: int,
	strikes_current_value: int,
	strikes_limit_value: int
) -> void:
	wave = wave_value
	time = time_value
	money = money_value
	magic = magic_value
	debt = debt_value
	strikes_current = strikes_current_value
	strikes_limit = strikes_limit_value

func duplicate_snapshot() -> ShiftHudSnapshot:
	return get_script().new(
		wave,
		time,
		money,
		magic,
		debt,
		strikes_current,
		strikes_limit
	) as ShiftHudSnapshot
