extends Node

signal debug_toggled(enabled)

var enabled := false

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_toggle"):
        enabled = not enabled
        emit_signal("debug_toggled", enabled)
        print("Debug overlay toggled:", enabled)
