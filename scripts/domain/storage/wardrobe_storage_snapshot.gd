extends RefCounted

class_name WardrobeStorageSnapshot

var slots_by_id: Dictionary

func _init(slots_by_id_value: Dictionary) -> void:
	slots_by_id = slots_by_id_value.duplicate(true)

func duplicate_snapshot() -> WardrobeStorageSnapshot:
	return get_script().new(slots_by_id) as WardrobeStorageSnapshot
