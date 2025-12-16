extends Control

@onready var _continue_button: Button = %ContinueButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	if _run_manager:
		_run_manager.go_to_menu()
	else:
		push_warning("RunManager singleton not found; cannot continue.")
