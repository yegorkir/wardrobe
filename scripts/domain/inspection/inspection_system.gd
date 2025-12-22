extends RefCounted

const MODE_PER_SHIFT := "PER_SHIFT"
const MODE_INTERVAL := "INTERVAL"

const RunState := preload("res://scripts/domain/run/run_state.gd")

var _config := {}

func setup(config: Dictionary) -> void:
	_config = {
		"inspection_mode": MODE_PER_SHIFT,
		"inspection_interval": 3,
		"mvp_emulation": true,
		"thresholds": {},
	}
	for key in config.keys():
		_config[key] = config[key]

func get_config() -> Dictionary:
	return _config.duplicate(true)

func record_entropy(run_state: RunState, amount: float) -> void:
	run_state.cleanliness_or_entropy += amount
	run_state.inspector_risk = max(run_state.inspector_risk, run_state.cleanliness_or_entropy)

func should_trigger_inspection(shift_index: int) -> bool:
	if _config.get("inspection_mode") == MODE_PER_SHIFT:
		return true
	var interval: int = max(1, int(_config.get("inspection_interval", 3)))
	return shift_index % interval == 0

func build_inspection_report(run_state: RunState, shift_index: int) -> Dictionary:
	var triggered := should_trigger_inspection(shift_index)
	if not triggered and not _config.get("mvp_emulation", true):
		return {}
	return {
		"triggered": triggered,
		"mode": _config.get("inspection_mode"),
		"cleanliness": run_state.cleanliness_or_entropy,
		"inspector_risk": run_state.inspector_risk,
		"notes": [],
	}
