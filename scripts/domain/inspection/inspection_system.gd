extends RefCounted

const InspectionConfigScript := preload("res://scripts/domain/inspection/inspection_config.gd")
const InspectionReportScript := preload("res://scripts/domain/inspection/inspection_report.gd")
const MODE_PER_SHIFT := StringName("PER_SHIFT")
const MODE_INTERVAL := StringName("INTERVAL")

var _config: InspectionConfigScript = _build_default_config()

func setup(config: InspectionConfigScript) -> void:
	_config = config.duplicate_config() if config else _build_default_config()

func get_config() -> InspectionConfigScript:
	return _config.duplicate_config()

func record_entropy(run_state: RunState, amount: float) -> void:
	run_state.cleanliness_or_entropy += amount
	run_state.inspector_risk = max(run_state.inspector_risk, run_state.cleanliness_or_entropy)

func should_trigger_inspection(shift_index: int) -> bool:
	if _config.inspection_mode == MODE_PER_SHIFT:
		return true
	var interval: int = max(1, _config.inspection_interval)
	return shift_index % interval == 0

func build_inspection_report(run_state: RunState, shift_index: int) -> InspectionReportScript:
	var triggered := should_trigger_inspection(shift_index)
	if not triggered and not _config.mvp_emulation:
		return null
	return InspectionReportScript.new(
		triggered,
		_config.inspection_mode,
		run_state.cleanliness_or_entropy,
		run_state.inspector_risk,
		[]
	)

func _build_default_config() -> InspectionConfigScript:
	return InspectionConfigScript.new(
		MODE_PER_SHIFT,
		3,
		true,
		{}
	)
