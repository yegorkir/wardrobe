class_name DeskServicePoint
extends Node2D

const DESK_GROUP := "wardrobe_desks"

@export var desk_id: StringName = StringName()
@export var desk_slot_id: StringName = StringName()

@onready var _desk_slot: WardrobeSlot = $DeskSlot

func _ready() -> void:
	add_to_group(DESK_GROUP)
	if desk_id == StringName():
		desk_id = StringName(name)
	if desk_slot_id == StringName():
		desk_slot_id = StringName("%s_Slot" % desk_id)
	if _desk_slot:
		_desk_slot.slot_id = String(desk_slot_id)

func get_slot_id() -> StringName:
	return desk_slot_id

func get_slot_node() -> WardrobeSlot:
	return _desk_slot
