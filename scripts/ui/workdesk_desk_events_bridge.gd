extends WardrobeInteractionEventsAdapter
class_name WorkdeskDeskEventsBridge

var _on_client_completed: Callable

func configure_bridge(on_client_completed: Callable) -> void:
	_on_client_completed = on_client_completed

func apply_desk_events(events: Array) -> void:
	for event_data in events:
		var event_type: StringName = event_data.get(EventSchema.EVENT_KEY_TYPE, StringName())
		if event_type == EventSchema.EVENT_CLIENT_COMPLETED and _on_client_completed.is_valid():
			_on_client_completed.call()
	super.apply_desk_events(events)
