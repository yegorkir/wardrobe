extends RefCounted

class_name WardrobeShiftLog

const ShiftLogEntryScript := preload("res://scripts/app/logging/shift_log_entry.gd")

var _events: Array[ShiftLogEntryScript] = []

func record(event_type: StringName, payload: Dictionary = {}) -> void:
	var entry := ShiftLogEntryScript.new(event_type, payload)
	_events.append(entry)

func get_events() -> Array[ShiftLogEntryScript]:
	return _events.duplicate(true)

func clear() -> void:
	_events.clear()
