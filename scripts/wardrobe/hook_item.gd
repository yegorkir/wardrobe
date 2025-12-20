class_name HookItem
extends Node2D

@export var slot_prefix := "Hook_0":
	set(value):
		slot_prefix = value
		_update_slot_ids()

@onready var _slot_a: WardrobeSlot = $HookSprite/SlotA
@onready var _slot_b: WardrobeSlot = $HookSprite/SlotB
@onready var _anchor_ticket: Sprite2D = $HookSprite/AnchorTicket

func _ready() -> void:
	_update_slot_ids()
	sync_anchor_ticket_color()

func _update_slot_ids() -> void:
	if slot_prefix.is_empty():
		return
	if _slot_a:
		_slot_a.slot_id = "%s_SlotA" % slot_prefix
	if _slot_b:
		_slot_b.slot_id = "%s_SlotB" % slot_prefix

func sync_anchor_ticket_color() -> void:
	if _anchor_ticket == null or _slot_a == null:
		return
	var item := _slot_a.get_item()
	if item == null:
		_anchor_ticket.modulate = Color.WHITE
		return
	var sprite := item.get_node_or_null("Sprite") as Sprite2D
	if sprite:
		_anchor_ticket.modulate = sprite.modulate
	else:
		_anchor_ticket.modulate = Color.WHITE
