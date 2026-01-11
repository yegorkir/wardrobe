extends Control

@onready var _start_workdesk_button: Button = %StartWorkdeskButton
@onready var _start_workdesk_debug_button: Button = %StartWorkdeskDebugButton
@onready var _quit_button: Button = %QuitButton
@onready var _run_manager: RunManagerBase = get_node_or_null("/root/RunManager") as RunManagerBase

func _ready() -> void:
	_start_workdesk_button.pressed.connect(_on_start_workdesk_pressed)
	_start_workdesk_debug_button.pressed.connect(_on_start_workdesk_debug_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	if OS.get_name() == "Web":
		_quit_button.disabled = true
		_quit_button.text = "Quit (N/A on Web)"

func _on_start_workdesk_pressed() -> void:
	if _run_manager:
		_run_manager.start_shift_with_screen(RunManagerBase.SCREEN_WARDROBE)
	else:
		push_warning("Cannot start run: RunManager singleton missing.")

func _on_start_workdesk_debug_pressed() -> void:
	if _run_manager:
		_run_manager.start_shift_with_screen(RunManagerBase.SCREEN_WARDROBE_DEBUG)
	else:
		push_warning("Cannot start run: RunManager singleton missing.")

func _on_quit_pressed() -> void:
	get_tree().quit()
