extends RefCounted

class_name DeskRejectOutcomeSystem

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

var _apply_patience_penalty: Callable

func configure(apply_patience_penalty: Callable) -> void:
	_apply_patience_penalty = apply_patience_penalty

func process_desk_events(events: Array) -> Array:
	if events.is_empty():
		return []
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		if event_type != EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN:
			continue
		var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		_apply_penalty(payload)
	return []

func _apply_penalty(payload: Dictionary) -> void:
	var client_id: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_CLIENT_ID, "")))
	var penalty: float = float(payload.get(EventSchema.PAYLOAD_PATIENCE_DELTA, 0.0))
	var reason_code: StringName = StringName(str(payload.get(EventSchema.PAYLOAD_REASON_CODE, "")))
	if penalty <= 0.0:
		return
	if client_id == StringName():
		return
	if _apply_patience_penalty.is_valid():
		_apply_patience_penalty.call(client_id, penalty, reason_code)
