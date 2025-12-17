extends RefCounted

class_name WardrobeInteractionEventAdapter

const InteractionEngine := preload("res://scripts/app/interaction/interaction_engine.gd")

signal item_picked(slot_id: StringName, item: Dictionary, tick: int)
signal item_placed(slot_id: StringName, item: Dictionary, tick: int)
signal item_swapped(slot_id: StringName, incoming_item: Dictionary, outgoing_item: Dictionary, tick: int)
signal action_rejected(slot_id: StringName, reason: StringName, tick: int)

func emit_events(events: Array) -> void:
	for event in events:
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event as Dictionary
		var event_type: StringName = event_dict.get(InteractionEngine.EVENT_KEY_TYPE, StringName())
		var payload_variant: Variant = event_dict.get(InteractionEngine.EVENT_KEY_PAYLOAD, {})
		var payload: Dictionary = payload_variant if payload_variant is Dictionary else {}
		var slot_id: StringName = payload.get(InteractionEngine.PAYLOAD_SLOT_ID, StringName())
		var tick: int = int(payload.get(InteractionEngine.PAYLOAD_TICK, 0))
		match event_type:
			InteractionEngine.EVENT_ITEM_PICKED:
				var item_payload: Variant = payload.get(InteractionEngine.PAYLOAD_ITEM, {})
				if item_payload is Dictionary:
					item_picked.emit(slot_id, item_payload as Dictionary, tick)
			InteractionEngine.EVENT_ITEM_PLACED:
				var placed_item: Variant = payload.get(InteractionEngine.PAYLOAD_ITEM, {})
				if placed_item is Dictionary:
					item_placed.emit(slot_id, placed_item as Dictionary, tick)
			InteractionEngine.EVENT_ITEM_SWAPPED:
				var incoming: Variant = payload.get(InteractionEngine.PAYLOAD_INCOMING_ITEM, {})
				var outgoing: Variant = payload.get(InteractionEngine.PAYLOAD_OUTGOING_ITEM, {})
				if incoming is Dictionary and outgoing is Dictionary:
					item_swapped.emit(slot_id, incoming as Dictionary, outgoing as Dictionary, tick)
			InteractionEngine.EVENT_ACTION_REJECTED:
				var reason: StringName = payload.get(InteractionEngine.PAYLOAD_REASON, StringName())
				action_rejected.emit(slot_id, reason, tick)
