extends RefCounted
class_name WardrobeInteractionLogger

const EVENT_INTERACTION_SUCCESS := StringName("interaction_success")
const EVENT_INTERACTION_REJECT := StringName("interaction_reject")

var _record_event: Callable

func configure(record_event: Callable) -> void:
	_record_event = record_event

func record_success(action: String, slot_id: StringName, item_name: String, command: Dictionary) -> void:
	print("%s item=%s slot=%s" % [action, item_name, slot_id])
	_record_interaction_event(EVENT_INTERACTION_SUCCESS, {
		"action": action,
		"item_name": item_name,
		"slot_id": slot_id,
		"command": command.duplicate(true),
	})

func record_reject(reason: StringName, slot_id: StringName, command: Dictionary) -> void:
	print("NO ACTION reason=%s slot=%s" % [reason, slot_id])
	_record_interaction_event(EVENT_INTERACTION_REJECT, {
		"reason": reason,
		"slot_id": slot_id,
		"command": command.duplicate(true),
	})

func _record_interaction_event(event_type: StringName, payload: Dictionary) -> void:
	if _record_event.is_valid():
		_record_event.call(event_type, payload)
