extends RefCounted

class_name WardrobeInteractionCommand

const InteractionCommandScript := preload("res://scripts/domain/interaction/interaction_command.gd")

const TYPE_AUTO := InteractionCommandScript.TYPE_AUTO
const TYPE_PICK := InteractionCommandScript.TYPE_PICK
const TYPE_PUT := InteractionCommandScript.TYPE_PUT

static func build(
	action: StringName,
	tick: int,
	slot_id: StringName,
	hand_item_id: String = "",
	slot_item_id: String = ""
) -> InteractionCommandScript:
	return InteractionCommandScript.new(
		action,
		tick,
		slot_id,
		StringName(hand_item_id),
		StringName(slot_item_id)
	)
