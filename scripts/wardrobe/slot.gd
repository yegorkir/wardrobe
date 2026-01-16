class_name WardrobeSlot
extends Node2D

const SLOT_GROUP := "wardrobe_slots"

@export var slot_id: String = ""
@onready var _item_anchor: Node2D = get_node_or_null("ItemAnchor") as Node2D
var _held_item: ItemNode
var _reserved_item_id: StringName = StringName()

func _ready() -> void:
	add_to_group(SLOT_GROUP)
	_ensure_item_anchor()

func has_item() -> bool:
	return _held_item != null

func get_item() -> ItemNode:
	return _held_item

func can_put(_item: ItemNode) -> bool:
	if _item == null:
		return false
	if has_item():
		return false
	if _reserved_item_id == StringName():
		return true
	return _reserved_item_id == StringName(_item.item_id)

func put_item(item: ItemNode) -> bool:
	if not can_put(item):
		return false
	_ensure_item_anchor()
	if _item_anchor == null:
		push_warning("WardrobeSlot %s missing ItemAnchor" % name)
		return false
	_held_item = item
	item.prepare_for_slot_anchor()
	item.freeze = true
	item.collision_layer = 0
	item.collision_mask = 0
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

func reserve(item_instance_id: StringName) -> void:
	if item_instance_id == StringName():
		return
	_reserved_item_id = item_instance_id

func release_reservation() -> void:
	_reserved_item_id = StringName()

func is_reserved_by(item_instance_id: StringName) -> bool:
	if _reserved_item_id == StringName():
		return false
	return _reserved_item_id == item_instance_id

func has_reservation() -> bool:
	return _reserved_item_id != StringName()

func get_item_anchor() -> Node2D:
	_ensure_item_anchor()
	return _item_anchor

func _ensure_item_anchor() -> void:
	if _item_anchor != null:
		return
	_item_anchor = get_node_or_null("ItemAnchor") as Node2D
	if _item_anchor != null:
		return
	_item_anchor = Node2D.new()
	_item_anchor.name = "ItemAnchor"
	add_child(_item_anchor)

func get_slot_identifier() -> String:
	return slot_id if slot_id.length() > 0 else String(name)
