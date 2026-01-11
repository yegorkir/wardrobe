extends RefCounted

class_name FloorResolver

var _floor_ids: Array[StringName] = []
var _default_floor_id: StringName = StringName()
var _desk_floor_map: Dictionary = {}

func configure(floor_ids: Array, default_floor_id: StringName, desk_floor_map: Dictionary = {}) -> void:
	_floor_ids.clear()
	for floor_id in floor_ids:
		var typed_id := StringName(str(floor_id))
		if typed_id == StringName():
			continue
		if not _floor_ids.has(typed_id):
			_floor_ids.append(typed_id)
	_floor_ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	_default_floor_id = default_floor_id
	_desk_floor_map = desk_floor_map.duplicate(true)

func resolve_floor_for_desk(desk_slot_id: StringName) -> StringName:
	if _desk_floor_map.has(desk_slot_id):
		var mapped := StringName(str(_desk_floor_map.get(desk_slot_id, "")))
		if mapped != StringName():
			return mapped
	if _floor_ids.is_empty():
		return _default_floor_id
	if desk_slot_id == StringName():
		return _default_floor_id if _default_floor_id != StringName() else _floor_ids[0]
	var index := _hash_to_index(String(desk_slot_id), _floor_ids.size())
	return _floor_ids[index]

func _hash_to_index(text: String, modulo: int) -> int:
	if modulo <= 0:
		return 0
	var bytes := text.to_utf8_buffer()
	var sum := 0
	for value in bytes:
		sum += int(value)
	return sum % modulo
