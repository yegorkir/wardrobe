extends Control

@onready var _summary_label: Label = %SummaryLabel
@onready var _back_button: Button = %BackButton
@onready var _run_manager := get_node_or_null("/root/RunManager")
var _payload: Dictionary = {}

func _ready() -> void:
    _back_button.pressed.connect(_on_back_pressed)
    _refresh()

func apply_payload(payload: Dictionary) -> void:
    _payload = payload.duplicate(true)
    _refresh()

func _refresh() -> void:
    var lines: Array = ["Summary placeholder"]
    if _payload.has("money"):
        lines.append("Money earned: %s" % _payload["money"])
    if _payload.has("notes"):
        for note in _payload["notes"]:
            lines.append(str(note))
    _summary_label.text = "\n".join(lines)

func _on_back_pressed() -> void:
    if _run_manager:
        _run_manager.go_to_menu()
    else:
        push_warning("RunManager singleton not found; cannot go to menu.")
