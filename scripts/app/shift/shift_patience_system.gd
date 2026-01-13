extends RefCounted

class_name ShiftPatienceSystem

const ShiftPatienceStateScript := preload("res://scripts/domain/shift/shift_patience_state.gd")

func reset_for_shift(state: ShiftPatienceState, client_ids: Array, patience_max: float, strikes_limit: int) -> void:
	if state == null:
		return
	state.reset(client_ids, patience_max, strikes_limit)

func tick_patience(
	state: ShiftPatienceState,
	active_client_ids: Array,
	queue_client_ids: Array,
	slot_decay_rate: float,
	queue_decay_multiplier: float,
	delta: float
) -> Dictionary:
	if state == null:
		return {
			"strike_client_ids": [],
		}
	var strike_client_ids: Array = []
	var visited: Dictionary = {}
	
	# Process active (slot) clients
	for raw_id in active_client_ids:
		var client_id := StringName(str(raw_id))
		if visited.has(client_id):
			continue
		visited[client_id] = true
		
		_apply_decay(state, client_id, delta * slot_decay_rate, strike_client_ids)
		
	# Process queue clients
	var queue_decay := delta * slot_decay_rate * queue_decay_multiplier
	for raw_id in queue_client_ids:
		var client_id := StringName(str(raw_id))
		if visited.has(client_id):
			continue # Already decayed as active
		visited[client_id] = true
		
		_apply_decay(state, client_id, queue_decay, strike_client_ids)

	return {
		"strike_client_ids": strike_client_ids,
	}

func _apply_decay(state: ShiftPatienceState, client_id: StringName, amount: float, strike_out: Array) -> void:
	var previous := state.get_patience_left(client_id)
	if previous <= 0.0:
		state.set_patience_left(client_id, 0.0)
		return
		
	var updated := maxf(previous - amount, 0.0)
	state.set_patience_left(client_id, updated)
	
	if previous > 0.0 and updated <= 0.0:
		state.strikes_current += 1
		strike_out.append(client_id)

func apply_penalty(state: ShiftPatienceState, client_id: StringName, amount: float) -> Dictionary:
	if state == null or client_id == StringName():
		return {
			"strike_client_ids": [],
		}
	if amount <= 0.0:
		return {
			"strike_client_ids": [],
		}
	if not state.has_client(client_id):
		return {
			"strike_client_ids": [],
		}
	var previous := state.get_patience_left(client_id)
	var updated := maxf(previous - amount, 0.0)
	state.set_patience_left(client_id, updated)
	var strike_client_ids: Array = []
	if previous > 0.0 and updated <= 0.0:
		state.strikes_current += 1
		strike_client_ids.append(client_id)
	return {
		"strike_client_ids": strike_client_ids,
	}
