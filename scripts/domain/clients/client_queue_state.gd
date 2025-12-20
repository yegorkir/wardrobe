extends RefCounted

class_name ClientQueueState

var _queue: Array[StringName] = []
var _index: Dictionary = {}

func clear() -> void:
	_queue.clear()
	_index.clear()

func enqueue(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	if _index.has(client_id):
		return
	_queue.append(client_id)
	_index[client_id] = true

func enqueue_many(client_ids: Array[StringName]) -> void:
	for client_id in client_ids:
		enqueue(client_id)

func pop_next() -> StringName:
	if _queue.is_empty():
		return StringName()
	var client_id: StringName = StringName(str(_queue.pop_front()))
	_index.erase(client_id)
	return client_id

func remove(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	if not _index.has(client_id):
		return
	_queue.erase(client_id)
	_index.erase(client_id)

func peek_next() -> StringName:
	if _queue.is_empty():
		return StringName()
	return _queue[0]

func get_count() -> int:
	return _queue.size()

func get_snapshot() -> Array[StringName]:
	return _queue.duplicate()
