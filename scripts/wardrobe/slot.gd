class_name WardrobeSlot
extends Node2D

const SLOT_GROUP := "wardrobe_slots"

@export var slot_id: String = ""
@onready var _item_anchor: Node2D = $ItemAnchor
var _held_item: ItemNode

func _ready() -> void:
	add_to_group(SLOT_GROUP)

func has_item() -> bool:
	return _held_item != null

func get_item() -> ItemNode:
	return _held_item

func can_put(_item: ItemNode) -> bool:
	return _item != null and not has_item()

func put_item(item: ItemNode) -> bool:
	if not can_put(item):
		return false
	_held_item = item
	if item.get_parent():
		item.reparent(_item_anchor)
	else:
		_item_anchor.add_child(item)
	item.global_position = _item_anchor.global_position
	item.global_rotation = 0.0
	item.global_scale = Vector2.ONE
	item.position = Vector2.ZERO
	return true

func take_item() -> ItemNode:
	if _held_item == null:
		return null
	var item := _held_item
	_held_item = null
	return item

func clear_item(queue_item := true) -> void:
	if _held_item:
		if queue_item and is_instance_valid(_held_item):
			_held_item.queue_free()
		_held_item = null

func get_slot_identifier() -> String:
	return slot_id if slot_id.length() > 0 else String(name)
