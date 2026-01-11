extends RefCounted

class_name QueueHudClientVM

var client_id: StringName
var portrait_key: StringName
var tiny_props: Array[StringName] = []
var status: StringName

func _init(
	id: StringName,
	portrait: StringName,
	props: Array[StringName],
	status_value: StringName
) -> void:
	client_id = id
	portrait_key = portrait
	tiny_props = props.duplicate()
	status = status_value

func duplicate_vm() -> QueueHudClientVM:
	return get_script().new(
		client_id,
		portrait_key,
		tiny_props.duplicate(),
		status
	) as QueueHudClientVM
