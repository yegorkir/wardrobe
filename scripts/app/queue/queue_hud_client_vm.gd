extends RefCounted

class_name QueueHudClientVM

var client_id: StringName
var portrait_key: StringName
var tiny_props: Array[StringName] = []
var status: StringName
var patience_ratio: float = 1.0

func _init(
	id: StringName,
	portrait: StringName,
	props: Array[StringName],
	status_value: StringName,
	patience: float = 1.0
) -> void:
	client_id = id
	portrait_key = portrait
	tiny_props = props.duplicate()
	status = status_value
	patience_ratio = patience

func duplicate_vm() -> QueueHudClientVM:
	return get_script().new(
		client_id,
		portrait_key,
		tiny_props.duplicate(),
		status,
		patience_ratio
	) as QueueHudClientVM
