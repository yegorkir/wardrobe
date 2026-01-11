extends RefCounted

class_name QueueHudSnapshot

var upcoming_clients: Array = []
var remaining_checkin: int = 0
var remaining_checkout: int = 0
var strikes_current: int = 0
var strikes_limit: int = 0

func _init(
	clients: Array,
	remaining_in: int,
	remaining_out: int,
	current_strikes: int,
	limit_strikes: int
) -> void:
	upcoming_clients = clients.duplicate()
	remaining_checkin = remaining_in
	remaining_checkout = remaining_out
	strikes_current = current_strikes
	strikes_limit = limit_strikes

func duplicate_snapshot() -> QueueHudSnapshot:
	var clients_copy: Array = []
	for client in upcoming_clients:
		clients_copy.append(client.duplicate_vm())
	return get_script().new(
		clients_copy,
		remaining_checkin,
		remaining_checkout,
		strikes_current,
		strikes_limit
	) as QueueHudSnapshot

func get_client_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for client in upcoming_clients:
		result.append(client.client_id)
	return result
