extends RefCounted

class_name InteractionCommand

const TYPE_AUTO := StringName("interaction_auto")
const TYPE_PICK := StringName("interaction_pick")
const TYPE_PUT := StringName("interaction_put")

var action: StringName
var tick: int
var slot_id: StringName
var hand_item_id: StringName
var slot_item_id: StringName

func _init(
	action_value: StringName,
	tick_value: int,
	slot_id_value: StringName,
	hand_item_id_value: StringName,
	slot_item_id_value: StringName
) -> void:
	action = action_value
	tick = tick_value
	slot_id = slot_id_value
	hand_item_id = hand_item_id_value
	slot_item_id = slot_item_id_value

func duplicate_command() -> InteractionCommand:
	return get_script().new(
		action,
		tick,
		slot_id,
		hand_item_id,
		slot_item_id
	) as InteractionCommand
