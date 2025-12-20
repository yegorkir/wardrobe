extends RefCounted

class_name ClientQueueSystem

const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")

func enqueue_new_client(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.enqueue(client_id)

func enqueue_clients(queue_state: ClientQueueState, client_ids: Array[StringName]) -> void:
	if queue_state == null:
		return
	queue_state.enqueue_many(client_ids)

func requeue_after_dropoff(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.enqueue(client_id)

func take_next_waiting_client(queue_state: ClientQueueState) -> StringName:
	if queue_state == null:
		return StringName()
	return queue_state.pop_next()

func remove_client(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.remove(client_id)
