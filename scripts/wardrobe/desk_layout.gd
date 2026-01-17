@tool
extends Node2D

class_name DeskLayout

const WardrobeSlotScript := preload("res://scripts/wardrobe/slot.gd")
const ClientDropZoneScript := preload("res://scripts/wardrobe/client_drop_zone.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

var _tray_slots: Array[WardrobeSlot] = []
var _drop_zone: ClientDropZoneScript

func _ready() -> void:
	_collect_layout_nodes()

func get_tray_slots() -> Array[WardrobeSlot]:
	if _tray_slots.is_empty():
		_collect_layout_nodes()
	return _tray_slots

func get_drop_zone() -> ClientDropZoneScript:
	if _drop_zone == null:
		_collect_layout_nodes()
	return _drop_zone

func get_free_tray_slot_ids(storage_state: WardrobeStorageState) -> Array[StringName]:
	var free_ids: Array[StringName] = []
	if storage_state == null:
		return free_ids
	for slot in get_tray_slots():
		if slot == null:
			continue
		var slot_id := StringName(slot.get_slot_identifier())
		if slot_id == StringName():
			continue
		if storage_state.get_slot_item(slot_id) != null:
			continue
		free_ids.append(slot_id)
	return free_ids

func place_item(item: ItemInstance, storage_state: WardrobeStorageState) -> StringName:
	if item == null or storage_state == null:
		return StringName()
	var free_ids := get_free_tray_slot_ids(storage_state)
	if free_ids.is_empty():
		return StringName()
	var slot_id := free_ids[0]
	var put_result := storage_state.put(slot_id, item)
	if not put_result.success:
		return StringName()
	return slot_id

func _collect_layout_nodes() -> void:
	_tray_slots.clear()
	_drop_zone = null
	for node in find_children("*", "WardrobeSlot", true, false):
		if node is WardrobeSlot:
			_tray_slots.append(node as WardrobeSlot)
	if _tray_slots.is_empty():
		for node in find_children("TraySlot_*", "", true, false):
			if node is Node2D and not (node is WardrobeSlot):
				node.set_script(WardrobeSlotScript)
			if node is WardrobeSlot:
				_tray_slots.append(node as WardrobeSlot)
	var drop_node := find_child("ClientDropZone", true, false)
	if drop_node != null and not (drop_node is ClientDropZoneScript):
		drop_node.set_script(ClientDropZoneScript)
	if drop_node is ClientDropZoneScript:
		_drop_zone = drop_node as ClientDropZoneScript
