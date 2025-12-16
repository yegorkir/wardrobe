extends Control

@onready var _summary_label: Label = %SummaryLabel
@onready var _back_button: Button = %BackButton
var _run_manager: RunManagerBase
var _payload: Dictionary = {}
var _is_ready := false

func _ready() -> void:
	_run_manager = get_node_or_null("/root/RunManager") as RunManagerBase
	if _back_button:
		_back_button.pressed.connect(_on_back_pressed)
	else:
		push_warning("Back button node not found; cannot return to menu.")
	_is_ready = true
	_refresh()

func apply_payload(payload: Dictionary) -> void:
	_payload = payload.duplicate(true)
	if _is_ready:
		_refresh()

func _refresh() -> void:
	if not _summary_label:
		return
	var lines: Array = ["Summary placeholder"]
	if _payload.has("money"):
		lines.append("Money earned: %s" % _payload["money"])
	if _payload.has("cleanliness"):
		lines.append("Cleanliness score: %s" % _payload["cleanliness"])
	if _payload.has("inspector_risk"):
		lines.append("Inspector risk: %s" % _payload["inspector_risk"])
		if _payload.has("inspection_report"):
			var report: Dictionary = _payload["inspection_report"]
			if not report.is_empty():
				lines.append("Inspection mode: %s" % report.get("mode", "-"))
				var triggered_flag: bool = bool(report.get("triggered", false))
				lines.append("Inspection triggered: %s" % ("Yes" if triggered_flag else "No"))
	if _payload.has("notes"):
		for note in _payload["notes"]:
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
