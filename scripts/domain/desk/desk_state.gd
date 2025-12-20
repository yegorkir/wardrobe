extends RefCounted

class_name DeskState

const PHASE_DROP_OFF := StringName("DROP_OFF")
const PHASE_PICK_UP := StringName("PICK_UP")

var desk_id: StringName
var desk_slot_id: StringName
var phase: StringName = PHASE_DROP_OFF
var current_client_id: StringName = StringName()

var _dropoff_queue: Array[StringName] = []
var _pickup_queue: Array[StringName] = []

func _init(id: StringName, slot_id: StringName) -> void:
	desk_id = id
	desk_slot_id = slot_id

func set_dropoff_queue(client_ids: Array) -> void:
	_dropoff_queue = []
	for client_id in client_ids:
		_dropoff_queue.append(StringName(str(client_id)))

func set_pickup_queue(client_ids: Array) -> void:
	_pickup_queue = []
	for client_id in client_ids:
		_pickup_queue.append(StringName(str(client_id)))

func get_dropoff_queue_snapshot() -> Array[StringName]:
	return _dropoff_queue.duplicate()

func get_pickup_queue_snapshot() -> Array[StringName]:
	return _pickup_queue.duplicate()

func has_dropoff_clients() -> bool:
	return not _dropoff_queue.is_empty()

func has_pickup_clients() -> bool:
	return not _pickup_queue.is_empty()

func enqueue_pickup(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	_pickup_queue.append(client_id)

func pop_next_dropoff() -> StringName:
	if _dropoff_queue.is_empty():
		return StringName()
	return _dropoff_queue.pop_front()

func pop_next_pickup() -> StringName:
	if _pickup_queue.is_empty():
		return StringName()
	return _pickup_queue.pop_front()

func set_phase(new_phase: StringName) -> void:
	phase = new_phase
