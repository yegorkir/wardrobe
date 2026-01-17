class_name DeskServicePoint
extends Node2D

const DESK_GROUP := "wardrobe_desks"
const TRAY_GROUP := "sp_tray_slot"
const DROP_ZONE_GROUP := "sp_client_drop_zone"
const ClientDropZoneScript := preload("res://scripts/wardrobe/client_drop_zone.gd")
const TRAY_SLOT_TEXTURE := preload("res://assets/sprites/placeholder/slot.png")
const HIGHLIGHT_SHADER := preload("res://shaders/client_highlight.gdshader")
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
@export var layout_adapter_path: NodePath = NodePath("LayoutRoot/DeskLayout")
@export var client_visual_path: NodePath = NodePath("ClientVisual")

const HIGHLIGHT_PARAM := "highlight_strength"

var _tray_slots: Array[WardrobeSlot] = []
var _drop_zone: ClientDropZoneScript
var _layout_valid := true
var _layout_collect_attempts := 0
var _layout_adapter: Node
var _client_visual: CanvasItem

func _ready() -> void:
	add_to_group(DESK_GROUP)
	if desk_id == StringName():
		desk_id = StringName(name)
	if desk_slot_id == StringName():
		desk_slot_id = StringName("%s_Slot" % desk_id)
	_ensure_layout_root()
	_cache_client_visual()
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
	if layout_root_path != NodePath() and get_node_or_null(layout_root_path) != null:
		return
	if get_node_or_null("LayoutRoot") != null:
		return
	var root := Node2D.new()
	root.name = "LayoutRoot"
	add_child(root)

func ensure_layout_instanced() -> void:
	if get_node_or_null("LayoutRoot") == null:
		_ensure_layout_root()

func set_drop_highlight(enabled: bool) -> void:
	_cache_client_visual()
	if _client_visual == null:
		return
	var shader_material := _ensure_highlight_material()
	if shader_material == null:
		return
	var strength := 1.0 if enabled else 0.0
	shader_material.set_shader_parameter(HIGHLIGHT_PARAM, strength)

func _collect_layout_nodes() -> void:
	_layout_collect_attempts += 1
	_tray_slots.clear()
	_drop_zone = null
	var layout := _get_layout_adapter()
	if layout != null and layout.has_method("get_tray_slots"):
		var slots: Array = layout.call("get_tray_slots")
		for slot_entry in slots:
			if slot_entry is WardrobeSlot:
				var slot := slot_entry as WardrobeSlot
				if not slot.is_in_group(TRAY_GROUP):
					slot.add_to_group(TRAY_GROUP)
				_tray_slots.append(slot)
	if layout != null and layout.has_method("get_drop_zone"):
		var drop_zone = layout.call("get_drop_zone")
		if drop_zone is ClientDropZoneScript:
			_drop_zone = drop_zone as ClientDropZoneScript
			_drop_zone.service_point_id = desk_id
			_drop_zone.service_point_node = self
	_apply_tray_slot_ids()
	if _tray_slots.is_empty() and _layout_collect_attempts < 3:
		call_deferred("_collect_layout_nodes")

func _get_layout_root() -> Node2D:
	if layout_root_path != NodePath():
		var target := get_node_or_null(layout_root_path)
		if target is Node2D:
			return target as Node2D
	return get_node_or_null("LayoutRoot") as Node2D

func _cache_client_visual() -> void:
	if _client_visual != null and is_instance_valid(_client_visual):
		return
	if client_visual_path == NodePath():
		return
	var node := get_node_or_null(client_visual_path)
	if node is CanvasItem:
		_client_visual = node as CanvasItem

func _ensure_highlight_material() -> ShaderMaterial:
	if _client_visual == null:
		return null
	var shader_material := _client_visual.material as ShaderMaterial
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = HIGHLIGHT_SHADER
		shader_material.resource_local_to_scene = true
		_client_visual.material = shader_material
	elif not shader_material.resource_local_to_scene:
		shader_material = shader_material.duplicate() as ShaderMaterial
		if shader_material != null:
			shader_material.resource_local_to_scene = true
			_client_visual.material = shader_material
	return shader_material

func _get_layout_adapter() -> Node:
	if _layout_adapter != null and is_instance_valid(_layout_adapter):
		return _layout_adapter
	if layout_adapter_path == NodePath():
		_layout_adapter = null
		return null
	var target := get_node_or_null(layout_adapter_path)
	if target != null and target.get_script() == null:
		target.set_script(preload("res://scripts/wardrobe/desk_layout.gd"))
	_layout_adapter = target
	return _layout_adapter

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
		var slot_identifier := slot.get_slot_identifier()
		if slot_identifier.is_empty():
			slot.slot_id = String("%s_Tray_%d" % [desk_id, index])
			continue
		if slot_identifier == String(slot.name) and String(slot.name).begins_with("TraySlot_"):
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
