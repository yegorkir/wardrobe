extends RefCounted

class_name ClientQueueSystem

const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const QueueMixPolicyScript := preload("res://scripts/app/queue/queue_mix_policy.gd")

var _mix_policy: QueueMixPolicy = QueueMixPolicyScript.new()
var _delayed_clients: Dictionary = {} # client_id -> { "remaining": float, "is_checkout": bool }
var _config: Dictionary = {}
var _seed: int = 0

func configure(config: Dictionary, seed_value: int) -> void:
	_config = config
	_seed = seed_value

func tick(queue_state: ClientQueueState, delta: float) -> void:
	if _delayed_clients.is_empty():
		return
	var to_enqueue: Array = []
	for client_id in _delayed_clients.keys():
		var entry: Dictionary = _delayed_clients[client_id]
		entry["remaining"] -= delta
		if entry["remaining"] <= 0.0:
			to_enqueue.append(client_id)
	
	for client_id in to_enqueue:
		var entry: Dictionary = _delayed_clients[client_id]
		_delayed_clients.erase(client_id)
		if entry["is_checkout"]:
			queue_state.enqueue_checkout(client_id)
		else:
			queue_state.enqueue_checkin(client_id)

func enqueue_new_client(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	var delay := _calculate_delay(client_id, false)
	if delay > 0.0:
		_add_delay(client_id, delay, false)
	else:
		queue_state.enqueue_checkin(client_id)

func enqueue_clients(queue_state: ClientQueueState, client_ids: Array[StringName]) -> void:
	if queue_state == null:
		return
	# Bulk enqueue usually happens at start of shift, assuming no delay for initial batch?
	# Or should we apply delay? Usually initial batch is "already there".
	# Let's keep it immediate for now to match legacy behavior, or maybe add small variance?
	# Plan didn't specify initial delay. Assuming immediate.
	queue_state.enqueue_many(client_ids)

func requeue_after_dropoff(queue_state: ClientQueueState, client_id: StringName) -> void:
	if queue_state == null:
		return
	var delay := _calculate_delay(client_id, true)
	if delay > 0.0:
		_add_delay(client_id, delay, true)
	else:
		queue_state.enqueue_checkout(client_id)

func _calculate_delay(client_id: StringName, is_checkout: bool) -> float:
	var min_delay: float
	var max_delay: float
	if is_checkout:
		min_delay = float(_config.get("queue_delay_checkout_min", 1.0))
		max_delay = float(_config.get("queue_delay_checkout_max", 3.0))
	else:
		min_delay = float(_config.get("queue_delay_checkin_min", 0.5))
		max_delay = float(_config.get("queue_delay_checkin_max", 1.5))
	
	if min_delay >= max_delay:
		return min_delay
		
	# Deterministic hash: abs(hash(client_id + seed))
	# Use string concatenation for hash input
	var hash_input := str(client_id) + "_" + str(_seed) + "_" + ("out" if is_checkout else "in")
	var hash_val := hash(hash_input)
	var ratio := float(hash_val & 0x7FFFFFFF) / 2147483647.0 # MAX_INT
	return lerp(min_delay, max_delay, ratio)

func _add_delay(client_id: StringName, delay: float, is_checkout: bool) -> void:
	_delayed_clients[client_id] = {
		"remaining": delay,
		"is_checkout": is_checkout
	}

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
