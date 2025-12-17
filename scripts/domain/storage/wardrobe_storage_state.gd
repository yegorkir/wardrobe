extends RefCounted

class_name WardrobeStorageState

const ItemInstance := preload("res://scripts/domain/storage/item_instance.gd")

const RESULT_KEY_SUCCESS := "success"
const RESULT_KEY_REASON := "reason"
const RESULT_KEY_ITEM := "item"
const RESULT_KEY_OUTGOING := "outgoing_item"
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

func put(slot_id: StringName, item: ItemInstance) -> Dictionary:
	if item == null:
		return _result(false, REASON_ITEM_MISSING, null)
	var slot := _slots.get(slot_id) as SlotState
	if slot == null:
		return _result(false, REASON_SLOT_MISSING, null)
	if slot.item != null:
		return _result(false, REASON_SLOT_BLOCKED, null)
	slot.item = item
	return _result(true, REASON_OK, null)

func pick(slot_id: StringName) -> Dictionary:
	var slot := _slots.get(slot_id) as SlotState
	if slot == null:
		return _result(false, REASON_SLOT_MISSING, null)
	if slot.item == null:
		return _result(false, REASON_SLOT_EMPTY, null)
	var picked := slot.item
	slot.item = null
	return _result(true, REASON_OK, picked)

func swap(slot_id: StringName, incoming: ItemInstance) -> Dictionary:
	if incoming == null:
		return _result(false, REASON_ITEM_MISSING, null)
	var slot := _slots.get(slot_id) as SlotState
	if slot == null:
		return _result(false, REASON_SLOT_MISSING, null)
	if slot.item == null:
		return _result(false, REASON_SLOT_EMPTY, null)
	var outgoing := slot.item
	slot.item = incoming
	return {
		RESULT_KEY_SUCCESS: true,
		RESULT_KEY_REASON: REASON_OK,
		RESULT_KEY_ITEM: incoming,
		RESULT_KEY_OUTGOING: outgoing,
	}

func get_slot_item(slot_id: StringName) -> ItemInstance:
	var slot := _slots.get(slot_id) as SlotState
	return slot.item if slot else null

func get_snapshot() -> Dictionary:
	var slots: Dictionary = {}
	for key in _slots.keys():
		var slot := _slots[key] as SlotState
		var item := slot.item
		if item != null:
			slots[key] = item.to_snapshot()
		else:
			slots[key] = null
	return {"slots": slots}

func _result(success: bool, reason: StringName, item: ItemInstance) -> Dictionary:
	return {
		RESULT_KEY_SUCCESS: success,
		RESULT_KEY_REASON: reason,
		RESULT_KEY_ITEM: item,
	}
