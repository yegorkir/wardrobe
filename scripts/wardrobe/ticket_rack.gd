extends Node2D

class_name TicketRack

const GROUP := "ticket_rack"
const SLOT_GROUP := "ticket_rack_slot"
const WardrobeSlotScript := preload("res://scripts/wardrobe/slot.gd")
const SLOT_TEXTURE := preload("res://assets/sprites/placeholder/slot.png")
const SLOT_SCALE := Vector2(0.35, 0.35)
const DEFAULT_SLOT_POSITIONS: Array[Vector2] = [
	Vector2(-84, 0),
	Vector2(-56, 0),
	Vector2(-28, 0),
	Vector2(0, 0),
	Vector2(28, 0),
	Vector2(56, 0),
	Vector2(84, 0),
]

@export var jitter_radius: Vector2 = Vector2(10.0, 6.0)

var _slots: Array[WardrobeSlot] = []
var _jitter_by_ticket_id: Dictionary = {}

func _ready() -> void:
	add_to_group(GROUP)
	_collect_slots()
	_apply_default_layout()
	_apply_jitter_to_slots()

func _process(_delta: float) -> void:
	_apply_jitter_to_slots()

func get_slots() -> Array:
	return _slots

func refresh_slots() -> void:
	add_to_group(GROUP)
	_collect_slots()
	_apply_default_layout()
	_apply_jitter_to_slots()

func clear_ticket_offset(ticket_id: StringName) -> void:
	if ticket_id == StringName():
		return
	_jitter_by_ticket_id.erase(ticket_id)

func _collect_slots() -> void:
	_slots.clear()
	for node in find_children("*", "", true, false):
		if node is Node2D and node.get_script() == null and String(node.name).begins_with("TicketRack_"):
			node.set_script(WardrobeSlotScript)
		if node is WardrobeSlotScript:
			var slot := node as WardrobeSlot
			if slot.get_slot_identifier().is_empty():
				slot.slot_id = String(slot.name)
			slot.add_to_group(SLOT_GROUP)
			_slots.append(slot)
		elif node.has_method("get_slot_identifier"):
			var slot_node: WardrobeSlot = node as WardrobeSlot
			if slot_node != null:
				if slot_node.get_slot_identifier().is_empty():
					slot_node.slot_id = String(slot_node.name)
				slot_node.add_to_group(SLOT_GROUP)
				_slots.append(slot_node)

func _apply_default_layout() -> void:
	if _slots.is_empty():
		return
	_slots.sort_custom(func(a: WardrobeSlot, b: WardrobeSlot) -> bool:
		return String(a.name) < String(b.name)
	)
	var anchors: Dictionary = {}
	var has_duplicates := false
	for slot in _slots:
		if slot == null:
			continue
		var anchor := slot.get_item_anchor()
		if anchor == null:
			continue
		var key := Vector2(anchor.global_position.x, anchor.global_position.y)
		if anchors.has(key):
			has_duplicates = true
			break
		anchors[key] = true
	if has_duplicates:
		for index in range(_slots.size()):
			var slot := _slots[index]
			if slot == null:
				continue
			slot.position = DEFAULT_SLOT_POSITIONS[index % DEFAULT_SLOT_POSITIONS.size()]
			var anchor := slot.get_item_anchor()
			if anchor != null:
				anchor.position = Vector2.ZERO
	_ensure_slot_visuals()

func _ensure_slot_visuals() -> void:
	for slot in _slots:
		if slot == null:
			continue
		var sprite := slot.get_node_or_null("SlotSprite") as Sprite2D
		if sprite == null:
			continue
		if sprite.texture == null:
			sprite.texture = SLOT_TEXTURE
		if sprite.scale.length() < 0.01:
			sprite.scale = SLOT_SCALE
		sprite.position = Vector2.ZERO

func _apply_jitter_to_slots() -> void:
	for slot in _slots:
		if slot == null or not slot.has_item():
			continue
		var item := slot.get_item()
		if item == null:
			continue
		var item_id := StringName(item.item_id)
		var offset := _get_or_create_jitter(item_id)
		item.position = offset

func _get_or_create_jitter(ticket_id: StringName) -> Vector2:
	if _jitter_by_ticket_id.has(ticket_id):
		return _jitter_by_ticket_id.get(ticket_id, Vector2.ZERO)
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash_to_seed(String(ticket_id))
	var offset := Vector2(
		rng.randf_range(-jitter_radius.x, jitter_radius.x),
		rng.randf_range(-jitter_radius.y, jitter_radius.y)
	)
	_jitter_by_ticket_id[ticket_id] = offset
	return offset

func _hash_to_seed(text: String) -> int:
	var hash_value := 2166136261
	var data := text.to_utf8_buffer()
	for byte in data:
		hash_value = int((hash_value ^ int(byte)) * 16777619) & 0x7fffffff
	return hash_value
