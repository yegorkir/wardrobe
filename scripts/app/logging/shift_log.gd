extends RefCounted

class_name WardrobeShiftLog

var _events: Array = []

func record(event_type: StringName, payload: Dictionary = {}) -> void:
	var entry := {
		"type": event_type,
		"payload": payload.duplicate(true),
	}
	_events.append(entry)

func get_events() -> Array:
	return _events.duplicate(true)

func clear() -> void:
	_events.clear()
