extends RefCounted

class_name ShiftLogEntry

var event_type: StringName
var payload: Dictionary

func _init(event_type_value: StringName, payload_value: Dictionary) -> void:
	event_type = event_type_value
	payload = payload_value.duplicate(true)

func duplicate_entry() -> ShiftLogEntry:
	return get_script().new(event_type, payload) as ShiftLogEntry
