extends RefCounted

const MODE_PER_SHIFT := "PER_SHIFT"
const MODE_INTERVAL := "INTERVAL"

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

func record_entropy(run_state: Dictionary, amount: float) -> void:
	var cleanliness := float(run_state.get("cleanliness_or_entropy", 0.0))
	cleanliness += amount
	run_state["cleanliness_or_entropy"] = cleanliness
	var risk := float(run_state.get("inspector_risk", 0.0))
	run_state["inspector_risk"] = max(risk, cleanliness)

func should_trigger_inspection(shift_index: int) -> bool:
	if _config.get("inspection_mode") == MODE_PER_SHIFT:
		return true
	var interval: int = max(1, int(_config.get("inspection_interval", 3)))
	return shift_index % interval == 0

func build_inspection_report(run_state: Dictionary, shift_index: int) -> Dictionary:
	var triggered := should_trigger_inspection(shift_index)
	if not triggered and not _config.get("mvp_emulation", true):
		return {}
	return {
		"triggered": triggered,
		"mode": _config.get("inspection_mode"),
		"cleanliness": run_state.get("cleanliness_or_entropy", 0.0),
		"inspector_risk": run_state.get("inspector_risk", 0.0),
		"notes": [],
	}
