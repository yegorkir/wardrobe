extends Control

const SCREEN_SCENES := {
	"main_menu": preload("res://scenes/screens/MainMenu.tscn"),
	"wardrobe": preload("res://scenes/screens/WardrobeScene.tscn"),
	"shift_summary": preload("res://scenes/screens/ShiftSummary.tscn"),
}

@onready var _screen_root: Control = %ScreenRoot
@onready var _run_manager := get_node_or_null("/root/RunManager")
var _current_screen: Control

func _ready() -> void:
	if _run_manager:
		_run_manager.screen_requested.connect(_on_screen_requested)
	else:
		push_warning("RunManager singleton not found; screens won't swap.")

func _on_screen_requested(screen_id: String, payload: Dictionary = {}) -> void:
	if not SCREEN_SCENES.has(screen_id):
		push_warning("Unknown screen requested: %s" % screen_id)
		return
	var scene: Control = SCREEN_SCENES[screen_id].instantiate()
	_swap_screen(scene, payload)

func _swap_screen(new_screen: Control, payload: Dictionary) -> void:
	if _current_screen:
		_current_screen.queue_free()
	_current_screen = new_screen
	_screen_root.add_child(_current_screen)
	if _current_screen.has_method("apply_payload"):
		_current_screen.apply_payload(payload)
