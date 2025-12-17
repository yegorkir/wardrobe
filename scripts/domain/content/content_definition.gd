extends Resource

class_name ContentDefinition

@export var id: StringName
@export var payload: Dictionary = {}

func to_snapshot() -> Dictionary:
	return {
		"id": id,
		"payload": payload.duplicate(true),
	}
