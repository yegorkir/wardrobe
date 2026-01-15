extends Control

@onready var _start_workdesk_button: Button = %StartWorkdeskButton
@onready var _debug_mode_checkbox: CheckBox = %DebugModeCheckbox
@onready var _quit_button: Button = %QuitButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

func _ready() -> void:
	_start_workdesk_button.pressed.connect(_on_start_workdesk_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	if OS.get_name() == "Web":
		_quit_button.disabled = true
		_quit_button.text = "Quit (N/A on Web)"

func _on_start_workdesk_pressed() -> void:
	if _run_manager:
		var payload := {
			"debug": _debug_mode_checkbox.button_pressed
		}
		_run_manager.start_shift_with_screen(RunManagerBase.SCREEN_WARDROBE, payload)
	else:
		push_warning("Cannot start run: RunManager singleton missing.")

func _on_quit_pressed() -> void:
	get_tree().quit()
