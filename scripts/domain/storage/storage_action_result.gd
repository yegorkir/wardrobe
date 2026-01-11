extends RefCounted

class_name StorageActionResult

const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

var success: bool
var reason: StringName
var item: ItemInstance

func _init(success_value: bool, reason_value: StringName, item_value: ItemInstance) -> void:
	success = success_value
	reason = reason_value
	item = item_value

func duplicate_result() -> StorageActionResult:
	var item_copy: ItemInstance = item.duplicate_instance() if item else null
	return get_script().new(success, reason, item_copy) as StorageActionResult
