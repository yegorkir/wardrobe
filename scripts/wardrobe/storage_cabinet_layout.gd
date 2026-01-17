@tool
class_name StorageCabinetLayout
extends Node2D

const CabinetSymbolAtlasScript := preload("res://scripts/wardrobe/cabinet_symbol_atlas.gd")
const CABINET_PLATE_TEXTURE := preload("res://assets/sprites/ankors.png")
const PLATE_ICON_NODE_NAME := "PlateIcon"

@export var cabinet_id: StringName = StringName()
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_update_visuals()
@onready var _slots_root: Node = $Slots
@onready var _cabinet_sprite: Sprite2D = $CabinetSprite

func _ready() -> void:
	_update_visuals()
	if not Engine.is_editor_hint():
		_assign_slot_ids()
	_update_plate_icons()

func _update_visuals() -> void:
	if _cabinet_sprite:
		_cabinet_sprite.flip_h = flip_h

func _assign_slot_ids() -> void:
	if cabinet_id == StringName():
		cabinet_id = StringName(name)
	if _slots_root == null:
		push_warning("StorageCabinetLayout missing Slots node: %s" % name)
		return
	var positions: Array[Node] = []
	for child in _slots_root.get_children():
		if child is Node and _has_slot_pair(child):
			positions.append(child)
	positions.sort_custom(Callable(self, "_compare_positions"))
	var index := 0
	for pos in positions:
		var slot_a := pos.get_node_or_null("SlotA") as WardrobeSlot
		var slot_b := pos.get_node_or_null("SlotB") as WardrobeSlot
		if slot_a == null or slot_b == null:
			continue
		var prefix := "%s_P%d" % [String(cabinet_id), index]
		slot_a.slot_id = "%s_SlotA" % prefix
		slot_b.slot_id = "%s_SlotB" % prefix
		index += 1
	
	var shelf_node := _slots_root.get_node_or_null("Shelf/ShelfSurface")
	if shelf_node and "shelf_id" in shelf_node:
		shelf_node.shelf_id = "%s_Shelf" % String(cabinet_id)

func _compare_positions(a: Node, b: Node) -> bool:
	return String(a.name) < String(b.name)

func _has_slot_pair(node: Node) -> bool:
	if node == null:
		return false
	return node.get_node_or_null("SlotA") is WardrobeSlot and node.get_node_or_null("SlotB") is WardrobeSlot

func refresh_plate_icons() -> void:
	_update_plate_icons()

func _update_plate_icons() -> void:
	if _slots_root == null:
		return
	for slot_position in _slots_root.get_children():
		if slot_position is Node and _has_slot_pair(slot_position):
			_update_slot_plate_icon(slot_position.get_node_or_null("SlotA") as WardrobeSlot)
			_update_slot_plate_icon(slot_position.get_node_or_null("SlotB") as WardrobeSlot)

func _update_slot_plate_icon(slot: WardrobeSlot) -> void:
	if slot == null:
		return
	var sprite := slot.get_node_or_null(PLATE_ICON_NODE_NAME) as Sprite2D
	if sprite == null:
		return
	sprite.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST
	if slot.ticket_symbol_index < 0:
		sprite.visible = false
		return
	var atlas := CabinetSymbolAtlasScript.make_atlas_texture(CABINET_PLATE_TEXTURE, slot.ticket_symbol_index)
	sprite.texture = atlas
	sprite.visible = atlas != null
