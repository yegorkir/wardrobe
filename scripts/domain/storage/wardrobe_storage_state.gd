extends RefCounted

class_name WardrobeStorageState

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const StorageActionResultScript := preload("res://scripts/domain/storage/storage_action_result.gd")
const WardrobeStorageSnapshotScript := preload("res://scripts/domain/storage/wardrobe_storage_snapshot.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const REASON_SLOT_MISSING := StringName("slot_missing")
const REASON_SLOT_EMPTY := StringName("slot_empty")
const REASON_SLOT_BLOCKED := StringName("slot_blocked")
const REASON_ITEM_MISSING := StringName("item_missing")
const REASON_OK := StringName("ok")

class SlotState:
	var id: StringName
	var item: ItemInstance

	func _init(slot_id: StringName) -> void:
		id = slot_id

var _slots: Dictionary = {}

func register_slot(slot_id: StringName) -> void:
	if slot_id.is_empty():
		return
	if _slots.has(slot_id):
		return
	_slots[slot_id] = SlotState.new(slot_id)

func clear() -> void:
	_slots.clear()

func has_slot(slot_id: StringName) -> bool:
	return _slots.has(slot_id)

func put(slot_id: StringName, item: ItemInstance) -> StorageActionResultScript:
	if item == null:
		if DebugLog.enabled():
			DebugLog.log("Storage put_fail slot=%s reason=item_missing" % [String(slot_id)])
		return _result(false, REASON_ITEM_MISSING, null)
	var slot := _slots.get(slot_id) as SlotState
	if slot == null:
		if DebugLog.enabled():
			DebugLog.log("Storage put_fail slot=%s reason=slot_missing" % [String(slot_id)])
		return _result(false, REASON_SLOT_MISSING, null)
	if slot.item != null:
		if DebugLog.enabled():
			DebugLog.log("Storage put_fail slot=%s reason=slot_blocked" % [String(slot_id)])
		return _result(false, REASON_SLOT_BLOCKED, null)
	slot.item = item
	return _result(true, REASON_OK, null)

func pick(slot_id: StringName) -> StorageActionResultScript:
	var slot := _slots.get(slot_id) as SlotState
	if slot == null:
		return _result(false, REASON_SLOT_MISSING, null)
	if slot.item == null:
		return _result(false, REASON_SLOT_EMPTY, null)
	var picked := slot.item
	slot.item = null
	return _result(true, REASON_OK, picked)

func pop_slot_item(slot_id: StringName) -> StorageActionResultScript:
	return pick(slot_id)

func get_slot_item(slot_id: StringName) -> ItemInstance:
	var slot := _slots.get(slot_id) as SlotState
	return slot.item if slot else null

func find_item_slot(item_id: StringName) -> StringName:
	if item_id.is_empty():
		return StringName()
	for key in _slots.keys():
		var slot := _slots[key] as SlotState
		if slot.item != null and slot.item.id == item_id:
			return slot.id
	return StringName()

func get_snapshot() -> WardrobeStorageSnapshotScript:
	var slots: Dictionary = {}
	for key in _slots.keys():
		var slot := _slots[key] as SlotState
		var item := slot.item
		if item != null:
			slots[key] = item.to_snapshot()
		else:
			slots[key] = null
	return WardrobeStorageSnapshotScript.new(slots)

func _result(success: bool, reason: StringName, item: ItemInstance) -> StorageActionResultScript:
	return StorageActionResultScript.new(success, reason, item)
