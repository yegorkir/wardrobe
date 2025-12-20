extends RefCounted

class_name DeskState

var desk_id: StringName
var desk_slot_id: StringName
var current_client_id: StringName = StringName()

func _init(id: StringName, slot_id: StringName) -> void:
	desk_id = id
	desk_slot_id = slot_id
