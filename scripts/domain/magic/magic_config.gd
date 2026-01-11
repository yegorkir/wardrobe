extends RefCounted

class_name MagicConfig

var insurance_mode: StringName
var emergency_cost_mode: StringName
var insurance_cost: int
var emergency_cost_value: int
var soft_limit: int
var search_effect: StringName

func _init(
	insurance_mode_value: StringName,
	emergency_cost_mode_value: StringName,
	insurance_cost_value: int,
	emergency_cost_value_value: int,
	soft_limit_value: int,
	search_effect_value: StringName
) -> void:
	insurance_mode = insurance_mode_value
	emergency_cost_mode = emergency_cost_mode_value
	insurance_cost = insurance_cost_value
	emergency_cost_value = emergency_cost_value_value
	soft_limit = soft_limit_value
	search_effect = search_effect_value

func duplicate_config() -> MagicConfig:
	return get_script().new(
		insurance_mode,
		emergency_cost_mode,
		insurance_cost,
		emergency_cost_value,
		soft_limit,
		search_effect
	) as MagicConfig
