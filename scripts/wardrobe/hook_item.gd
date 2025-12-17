class_name HookItem
extends Node2D

@export var slot_prefix := "Hook_0":
	set(value):
		slot_prefix = value
		_update_slot_ids()

@onready var _slot_a: WardrobeSlot = $HookSprite/SlotA
@onready var _slot_b: WardrobeSlot = $HookSprite/SlotB

func _ready() -> void:
	_update_slot_ids()

func _update_slot_ids() -> void:
	if slot_prefix.is_empty():
		return
	if _slot_a:
		_slot_a.slot_id = "%s_SlotA" % slot_prefix
	if _slot_b:
		_slot_b.slot_id = "%s_SlotB" % slot_prefix
