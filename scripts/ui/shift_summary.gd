extends Control

const ShiftSummaryModel := preload("res://scripts/app/shift/shift_summary.gd")

@onready var _summary_label: Label = %SummaryLabel
@onready var _back_button: Button = %BackButton
var _run_manager: RunManagerBase
var _payload: ShiftSummaryModel
var _is_ready := false

func _ready() -> void:
	_run_manager = get_node_or_null("/root/RunManager") as RunManagerBase
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	else:
		push_warning("Back button node not found; cannot return to menu.")
	_is_ready = true
	_refresh()

func apply_payload(payload: ShiftSummaryModel) -> void:
	_payload = payload.duplicate_summary() if payload else null
	if _is_ready:
		_refresh()

func _refresh() -> void:
	if not _summary_label:
		return
	var lines: Array = ["Summary placeholder"]
	if _payload:
		lines.append("Money earned: %s" % _payload.money)
		lines.append("Cleanliness score: %s" % _payload.cleanliness)
		lines.append("Inspector risk: %s" % _payload.inspector_risk)
		lines.append("Shift status: %s" % _payload.status)
		lines.append("Strikes: %s/%s" % [_payload.strikes_current, _payload.strikes_limit])
		if not _payload.end_reasons.is_empty():
			lines.append("End reasons: %s" % ", ".join(_payload.end_reasons))
		if _payload.inspection_report:
			lines.append("Inspection mode: %s" % _payload.inspection_report.mode)
			lines.append(
				"Inspection triggered: %s" % ("Yes" if _payload.inspection_report.triggered else "No")
			)
		for note in _payload.notes:
			lines.append(str(note))
	_summary_label.text = "\n".join(lines)

func _on_back_pressed() -> void:
	var run_manager: RunManagerBase = _ensure_run_manager()
	if run_manager:
		run_manager.go_to_menu()
	else:
		push_warning("RunManager singleton not found; cannot go to menu.")

func _ensure_run_manager() -> RunManagerBase:
	if _run_manager and is_instance_valid(_run_manager):
		return _run_manager
	_run_manager = get_node_or_null("/root/RunManager") as RunManagerBase
	return _run_manager
