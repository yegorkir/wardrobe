extends RefCounted

class_name ClientQueueSystem

const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const QueueMixPolicyScript := preload("res://scripts/app/queue/queue_mix_policy.gd")

var _mix_policy = QueueMixPolicyScript.new()

func enqueue_new_client(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.enqueue_checkin(client_id)

func enqueue_clients(queue_state: ClientQueueState, client_ids: Array[StringName]) -> void:
	if queue_state == null:
		return
	queue_state.enqueue_many(client_ids)

func requeue_after_dropoff(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.enqueue_checkout(client_id)

func take_next_waiting_client(queue_state: ClientQueueState, mix_snapshot: Dictionary = {}) -> StringName:
	if queue_state == null:
		return StringName()
	var source: StringName = _mix_policy.select_next_source(mix_snapshot)
	if source == QueueMixPolicyScript.SOURCE_CHECKOUT:
		var checkout_id := queue_state.pop_next_checkout()
		if not checkout_id.is_empty():
			return checkout_id
		return queue_state.pop_next_checkin()
	var checkin_id := queue_state.pop_next_checkin()
	if not checkin_id.is_empty():
		return checkin_id
	return queue_state.pop_next_checkout()

func remove_client(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	queue_state.remove(client_id)
