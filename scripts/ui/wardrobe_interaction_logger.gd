extends RefCounted
class_name WardrobeInteractionLogger

const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")

const EVENT_INTERACTION_SUCCESS := StringName("interaction_success")
const EVENT_INTERACTION_REJECT := StringName("interaction_reject")

var _record_event: Callable

func configure(record_event: Callable) -> void:
	_record_event = record_event

func record_success(
	action: String,
	slot_id: StringName,
	item_name: String,
	command: InteractionCommandScript
) -> void:
	print("%s item=%s slot=%s" % [action, item_name, slot_id])
	_record_interaction_event(EVENT_INTERACTION_SUCCESS, {
		"action": action,
		"item_name": item_name,
		"slot_id": slot_id,
		"command": _command_to_dict(command),
	})

func record_reject(reason: StringName, slot_id: StringName, command: InteractionCommandScript) -> void:
	print("NO ACTION reason=%s slot=%s" % [reason, slot_id])
	_record_interaction_event(EVENT_INTERACTION_REJECT, {
		"reason": reason,
		"slot_id": slot_id,
		"command": _command_to_dict(command),
	})

func _record_interaction_event(event_type: StringName, payload: Dictionary) -> void:
	if _record_event.is_valid():
		_record_event.call(event_type, payload)

func _command_to_dict(command: InteractionCommandScript) -> Dictionary:
	if command == null:
		return {}
	return {
		"action": command.action,
		"tick": command.tick,
		"slot_id": command.slot_id,
		"hand_item_id": command.hand_item_id,
		"slot_item_id": command.slot_item_id,
	}
