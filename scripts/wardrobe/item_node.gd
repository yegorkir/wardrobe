class_name ItemNode
extends Node2D

enum ItemType {
	COAT,
	TICKET,
	ANCHOR_TICKET,
}

@export var item_id: String = ""
@export var item_type: ItemType = ItemType.COAT
var ticket_number: int = -1
var durability: float = 100.0

func attach_to_anchor(anchor: Node2D) -> void:
	if anchor == null:
		return
	if get_parent():
		reparent(anchor)
	else:
		anchor.add_child(self)
	global_position = anchor.global_position
	global_rotation = 0.0
	global_scale = Vector2.ONE
	position = Vector2.ZERO
