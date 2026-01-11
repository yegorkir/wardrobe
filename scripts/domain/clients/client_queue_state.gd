extends RefCounted

class_name ClientQueueState

var _queue: Array[StringName] = []
var _index: Dictionary = {}
var _checkout_queue: Array[StringName] = []
var _checkout_index: Dictionary = {}

func clear() -> void:
	_queue.clear()
	_index.clear()
	_checkout_queue.clear()
	_checkout_index.clear()

func enqueue(client_id: StringName) -> void:
	enqueue_checkin(client_id)

func enqueue_checkin(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	if _index.has(client_id) or _checkout_index.has(client_id):
		return
	_queue.append(client_id)
	_index[client_id] = true

func enqueue_many(client_ids: Array[StringName]) -> void:
	for client_id in client_ids:
		enqueue(client_id)

func pop_next() -> StringName:
	return pop_next_checkin()

func pop_next_checkin() -> StringName:
	if _queue.is_empty():
		return StringName()
	var client_id: StringName = StringName(str(_queue.pop_front()))
	_index.erase(client_id)
	return client_id

func pop_next_checkout() -> StringName:
	if _checkout_queue.is_empty():
		return StringName()
	var client_id: StringName = StringName(str(_checkout_queue.pop_front()))
	_checkout_index.erase(client_id)
	return client_id

func enqueue_checkout(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	if _index.has(client_id) or _checkout_index.has(client_id):
		return
	_checkout_queue.append(client_id)
	_checkout_index[client_id] = true

func remove(client_id: StringName) -> void:
	if client_id.is_empty():
		return
	if _index.has(client_id):
		_queue.erase(client_id)
		_index.erase(client_id)
	if _checkout_index.has(client_id):
		_checkout_queue.erase(client_id)
		_checkout_index.erase(client_id)

func peek_next() -> StringName:
	return peek_next_checkin()

func peek_next_checkin() -> StringName:
	if _queue.is_empty():
		return StringName()
	return _queue[0]

func peek_next_checkout() -> StringName:
	if _checkout_queue.is_empty():
		return StringName()
	return _checkout_queue[0]

func get_count() -> int:
	return _queue.size() + _checkout_queue.size()

func get_checkin_count() -> int:
	return _queue.size()

func get_checkout_count() -> int:
	return _checkout_queue.size()

func get_snapshot() -> Array[StringName]:
	var snapshot: Array[StringName] = _queue.duplicate()
	snapshot.append_array(_checkout_queue)
	return snapshot

func get_checkin_snapshot() -> Array[StringName]:
	return _queue.duplicate()

func get_checkout_snapshot() -> Array[StringName]:
	return _checkout_queue.duplicate()
