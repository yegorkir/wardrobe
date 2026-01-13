extends RefCounted
class_name VampireExposureState

var current_stage_exposure: float = 0.0
var stage_index: int = 0

func reset() -> void:
	current_stage_exposure = 0.0
	stage_index = 0

func duplicate_state() -> VampireExposureState:
	var dup = get_script().new()
	dup.current_stage_exposure = current_stage_exposure
	dup.stage_index = stage_index
	return dup
