extends RefCounted

class_name WardrobeInteractionEventAdapter

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

signal item_picked(slot_id: StringName, item: Dictionary, tick: int)
signal item_placed(slot_id: StringName, item: Dictionary, tick: int)
signal action_rejected(slot_id: StringName, reason: StringName, tick: int)

func emit_events(events: Array) -> void:
	for event in events:
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event as Dictionary
		var event_type: StringName = event_dict.get(EventSchema.EVENT_KEY_TYPE, StringName())
		var payload_variant: Variant = event_dict.get(EventSchema.EVENT_KEY_PAYLOAD, {})
		var payload: Dictionary = payload_variant if payload_variant is Dictionary else {}
		var slot_id: StringName = payload.get(EventSchema.PAYLOAD_SLOT_ID, StringName())
		var tick: int = int(payload.get(EventSchema.PAYLOAD_TICK, 0))
		match event_type:
			EventSchema.EVENT_ITEM_PICKED:
				var item_payload: Variant = payload.get(EventSchema.PAYLOAD_ITEM, {})
				if item_payload is Dictionary:
					item_picked.emit(slot_id, item_payload as Dictionary, tick)
			EventSchema.EVENT_ITEM_PLACED:
				var placed_item: Variant = payload.get(EventSchema.PAYLOAD_ITEM, {})
				if placed_item is Dictionary:
					item_placed.emit(slot_id, placed_item as Dictionary, tick)
			EventSchema.EVENT_ACTION_REJECTED:
				var reason: StringName = payload.get(EventSchema.PAYLOAD_REASON, StringName())
				action_rejected.emit(slot_id, reason, tick)
