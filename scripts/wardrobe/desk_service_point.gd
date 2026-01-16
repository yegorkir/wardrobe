class_name DeskServicePoint
extends Node2D

const DESK_GROUP := "wardrobe_desks"
const TRAY_GROUP := "sp_tray_slot"
const DROP_ZONE_GROUP := "sp_client_drop_zone"
const ClientDropZoneScript := preload("res://scripts/wardrobe/client_drop_zone.gd")
const WardrobeSlotScript := preload("res://scripts/wardrobe/slot.gd")
const TRAY_SLOT_TEXTURE := preload("res://assets/sprites/placeholder/slot.png")
const TRAY_SLOT_SCALE := Vector2(0.35, 0.35)
const DEFAULT_TRAY_POSITIONS: Array[Vector2] = [
	Vector2(-48, 20),
	Vector2(-16, 20),
	Vector2(16, 20),
	Vector2(48, 20),
]
const DEFAULT_DROP_ZONE_POS := Vector2(0, -90)

@export var desk_id: StringName = StringName()
@export var desk_slot_id: StringName = StringName()
@export var layout_root_path: NodePath = NodePath()

var _tray_slots: Array[WardrobeSlot] = []
var _drop_zone: ClientDropZoneScript
var _layout_valid := true
var _layout_collect_attempts := 0

func _ready() -> void:
	add_to_group(DESK_GROUP)
	if desk_id == StringName():
		desk_id = StringName(name)
	if desk_slot_id == StringName():
		desk_slot_id = StringName("%s_Slot" % desk_id)
	_ensure_layout_root()
	call_deferred("_finish_layout_setup")

func get_slot_id() -> StringName:
	return desk_slot_id

func get_tray_slots() -> Array[WardrobeSlot]:
	if _layout_valid:
		return _tray_slots
	var empty: Array[WardrobeSlot] = []
	return empty

func get_tray_slot_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if not _layout_valid:
		return ids
	for slot in _tray_slots:
		if slot == null:
			continue
		ids.append(StringName(slot.get_slot_identifier()))
	return ids

func get_drop_zone() -> ClientDropZoneScript:
	return _drop_zone if _layout_valid else null

func _ensure_layout_root() -> void:
	if get_node_or_null("LayoutRoot") != null:
		return
	var root := Node2D.new()
	root.name = "LayoutRoot"
	add_child(root)

func ensure_layout_instanced() -> void:
	if get_node_or_null("LayoutRoot") == null:
		_ensure_layout_root()

func _collect_layout_nodes() -> void:
	_layout_collect_attempts += 1
	_tray_slots.clear()
	_drop_zone = null
	var root := _get_layout_root()
	if root == null:
		return
	for node in root.find_children("*", "WardrobeSlot", true, false):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			if not slot.is_in_group(TRAY_GROUP):
				slot.add_to_group(TRAY_GROUP)
			_tray_slots.append(slot)
	if _tray_slots.is_empty():
		for node in root.find_children("TraySlot_*", "", true, false):
			if node is Node2D and not (node is WardrobeSlot):
				node.set_script(WardrobeSlotScript)
			if node is WardrobeSlot:
				var slot := node as WardrobeSlot
				if not slot.is_in_group(TRAY_GROUP):
					slot.add_to_group(TRAY_GROUP)
				_tray_slots.append(slot)
	for node in root.get_tree().get_nodes_in_group(DROP_ZONE_GROUP):
		if node is ClientDropZoneScript and root.is_ancestor_of(node):
			_drop_zone = node
			_drop_zone.service_point_id = desk_id
			break
	if _drop_zone == null:
		var drop_node := root.find_child("ClientDropZone", true, false) as Node
		if drop_node != null and not (drop_node is ClientDropZoneScript):
			drop_node.set_script(ClientDropZoneScript)
		if drop_node is ClientDropZoneScript:
			_drop_zone = drop_node as ClientDropZoneScript
			_drop_zone.service_point_id = desk_id
	_apply_tray_slot_ids()
	if _tray_slots.is_empty() and _layout_collect_attempts < 3:
		call_deferred("_collect_layout_nodes")

func _get_layout_root() -> Node2D:
	if layout_root_path != NodePath():
		var target := get_node_or_null(layout_root_path)
		if target is Node2D:
			return target as Node2D
	return get_node_or_null("LayoutRoot") as Node2D

func _apply_tray_slot_ids() -> void:
	if _tray_slots.is_empty():
		return
	_tray_slots.sort_custom(func(a: WardrobeSlot, b: WardrobeSlot) -> bool:
		return String(a.name) < String(b.name)
	)
	for index in range(_tray_slots.size()):
		var slot := _tray_slots[index]
		if slot == null:
			continue
		if slot.get_slot_identifier().is_empty():
			slot.slot_id = String("%s_Tray_%d" % [desk_id, index])

func _validate_layout() -> void:
	if _tray_slots.size() != 4:
		push_error("DeskServicePoint %s expected 4 tray slots, got %d." % [desk_id, _tray_slots.size()])
		_layout_valid = false
	if _drop_zone == null:
		push_error("DeskServicePoint %s missing client drop zone." % desk_id)
		_layout_valid = false
	var anchors: Dictionary = {}
	for slot in _tray_slots:
		if slot == null:
			continue
		var anchor := slot.get_item_anchor()
		if anchor == null:
			continue
		var key := Vector2(anchor.global_position.x, anchor.global_position.y)
		if anchors.has(key):
			push_error("DeskServicePoint %s tray slot anchors must be unique." % desk_id)
			_layout_valid = false
			break
		anchors[key] = true

func _finish_layout_setup() -> void:
	_collect_layout_nodes()
	_apply_default_layout_fallbacks()
	if not _tray_slots.is_empty() or _layout_collect_attempts >= 3:
		_validate_layout()
		_validate_dropzone_overlap()

func _apply_default_layout_fallbacks() -> void:
	if _tray_slots.is_empty():
		return
	var anchors: Dictionary = {}
	var has_duplicates := false
	for slot in _tray_slots:
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
		for index in range(_tray_slots.size()):
			var slot := _tray_slots[index]
			if slot == null:
				continue
			slot.position = DEFAULT_TRAY_POSITIONS[index % DEFAULT_TRAY_POSITIONS.size()]
			var anchor := slot.get_item_anchor()
			if anchor != null:
				anchor.position = Vector2.ZERO
			_ensure_tray_slot_visuals(slot)
	else:
		for slot in _tray_slots:
			if slot == null:
				continue
			_ensure_tray_slot_visuals(slot)
	if _drop_zone != null and _drop_zone.position == Vector2.ZERO:
		_drop_zone.position = DEFAULT_DROP_ZONE_POS

func _ensure_tray_slot_visuals(slot: WardrobeSlot) -> void:
	if slot == null:
		return
	var sprite := slot.get_node_or_null("SlotSprite") as Sprite2D
	if sprite == null:
		return
	if sprite.texture == null:
		sprite.texture = TRAY_SLOT_TEXTURE
	if sprite.scale.length() < 0.01:
		sprite.scale = TRAY_SLOT_SCALE
	sprite.position = Vector2.ZERO

func _validate_dropzone_overlap() -> void:
	if _drop_zone == null:
		return
	if not _drop_zone.monitoring:
		_drop_zone.monitoring = true
	var overlaps: Array = _drop_zone.get_overlapping_areas()
	for area in overlaps:
		if area is Area2D:
			push_error("DeskServicePoint %s drop zone overlaps another area: %s" % [desk_id, area.name])
			_layout_valid = false
			return
