extends RefCounted

class_name InteractionResult

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

var success: bool
var reason: StringName
var action: String
var events: Array
var hand_item: ItemInstance

func _init(
	success_value: bool,
	reason_value: StringName,
	action_value: String,
	events_value: Array,
	hand_item_value: ItemInstance
) -> void:
	success = success_value
	reason = reason_value
	action = action_value
	events = events_value.duplicate(true)
	hand_item = hand_item_value
