extends RefCounted

class_name InspectionConfig

var inspection_mode: StringName
var inspection_interval: int
var mvp_emulation: bool
var thresholds: Dictionary

func _init(
	inspection_mode_value: StringName,
	inspection_interval_value: int,
	mvp_emulation_value: bool,
	thresholds_value: Dictionary
) -> void:
	inspection_mode = inspection_mode_value
	inspection_interval = inspection_interval_value
	mvp_emulation = mvp_emulation_value
	thresholds = thresholds_value.duplicate(true)

func duplicate_config() -> InspectionConfig:
	return get_script().new(
		inspection_mode,
		inspection_interval,
		mvp_emulation,
		thresholds
	) as InspectionConfig
