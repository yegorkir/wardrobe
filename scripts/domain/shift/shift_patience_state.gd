extends RefCounted

class_name ShiftPatienceState

var strikes_current: int = 0
var strikes_limit: int = 0

var _patience_by_client_id: Dictionary = {}
var _patience_max_by_client_id: Dictionary = {}

func reset(client_ids: Array, patience_max: float, strikes_limit_value: int) -> void:
	_patience_by_client_id.clear()
	_patience_max_by_client_id.clear()
	strikes_current = 0
	strikes_limit = strikes_limit_value
	for client_id in client_ids:
		var typed_id := StringName(str(client_id))
		_patience_by_client_id[typed_id] = patience_max
		_patience_max_by_client_id[typed_id] = patience_max

func set_patience_left(client_id: StringName, value: float) -> void:
	_patience_by_client_id[client_id] = value

func get_patience_left(client_id: StringName) -> float:
	return float(_patience_by_client_id.get(client_id, 0.0))

func has_client(client_id: StringName) -> bool:
	return _patience_by_client_id.has(client_id)

func get_patience_max(client_id: StringName) -> float:
	return float(_patience_max_by_client_id.get(client_id, 0.0))

func get_patience_snapshot() -> Dictionary:
	return {
		"patience_by_client_id": _patience_by_client_id.duplicate(true),
		"patience_max_by_client_id": _patience_max_by_client_id.duplicate(true),
	}
