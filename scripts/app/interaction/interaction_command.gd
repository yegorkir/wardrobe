extends RefCounted

class_name WardrobeInteractionCommand

const KEY_TYPE := &"type"
const KEY_TICK := &"tick"
const KEY_PAYLOAD := &"payload"
const PAYLOAD_SLOT_ID := &"slot_id"
const PAYLOAD_HAND_ITEM_ID := &"hand_item_id"
const PAYLOAD_SLOT_ITEM_ID := &"slot_item_id"

const TYPE_AUTO := &"interaction_auto"
const TYPE_PICK := &"interaction_pick"
const TYPE_PUT := &"interaction_put"

static func build(
	action: StringName,
	tick: int,
	slot_id: StringName,
	hand_item_id: String = "",
	slot_item_id: String = ""
) -> Dictionary:
	return {
		KEY_TYPE: action,
		KEY_TICK: tick,
		KEY_PAYLOAD: {
			PAYLOAD_SLOT_ID: slot_id,
			PAYLOAD_HAND_ITEM_ID: hand_item_id,
			PAYLOAD_SLOT_ITEM_ID: slot_item_id,
		},
	}
