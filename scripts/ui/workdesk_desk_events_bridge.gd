extends WardrobeInteractionEventsAdapter
class_name WorkdeskDeskEventsBridge

const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")

var _on_client_completed: Callable
var _on_client_checkin: Callable

func configure_bridge(on_client_completed: Callable, on_client_checkin: Callable) -> void:
	_on_client_completed = on_client_completed
	_on_client_checkin = on_client_checkin

func apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		if event_type == EventSchema.EVENT_CLIENT_COMPLETED and _on_client_completed.is_valid():
			_on_client_completed.call()
		if event_type == EventSchema.EVENT_CLIENT_PHASE_CHANGED and _on_client_checkin.is_valid():
			var payload: Dictionary = event_data.get(EventSchema.EVENT_KEY_PAYLOAD, {})
			var from_phase := StringName(str(payload.get(EventSchema.PAYLOAD_FROM, "")))
			var to_phase := StringName(str(payload.get(EventSchema.PAYLOAD_TO, "")))
			if from_phase == ClientStateScript.PHASE_DROP_OFF and to_phase == ClientStateScript.PHASE_PICK_UP:
				_on_client_checkin.call()
	super.apply_desk_events(events)
