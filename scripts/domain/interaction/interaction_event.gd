extends RefCounted

class_name InteractionEvent

var event_type: StringName
var payload: Dictionary

func _init(event_type_value: StringName, payload_value: Dictionary) -> void:
	event_type = event_type_value
	payload = payload_value.duplicate(true)

func duplicate_event() -> InteractionEvent:
	return get_script().new(event_type, payload) as InteractionEvent
