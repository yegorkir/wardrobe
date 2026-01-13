extends RefCounted
class_name ZombieExposureState

var current_stage_exposure: float = 0.0
var stage_index: int = 0
var is_emitting_weak_aura: bool = false
var pending_transfers: Dictionary = {} # source_id: StringName -> remaining_time: float

func reset() -> void:
	current_stage_exposure = 0.0
	stage_index = 0
	is_emitting_weak_aura = false
	pending_transfers.clear()

func reset_exposure_only() -> void:
	current_stage_exposure = 0.0

func set_pending(source_id: StringName, time: float) -> void:
	pending_transfers[source_id] = time

func clear_pending(source_id: StringName) -> void:
	pending_transfers.erase(source_id)

func tick_pending(delta: float) -> void:
	for id in pending_transfers.keys():
		pending_transfers[id] = maxf(0.0, pending_transfers[id] - delta)

func is_active(source_id: StringName) -> bool:
	return pending_transfers.has(source_id) and pending_transfers[source_id] <= 0.0

func get_active_sources() -> Array[StringName]:
	var active: Array[StringName] = []
	for id in pending_transfers:
		if pending_transfers[id] <= 0.0:
			active.append(id)
	return active

func duplicate_state() -> ZombieExposureState:
	var dup = get_script().new()
	dup.current_stage_exposure = current_stage_exposure
	dup.stage_index = stage_index
	dup.is_emitting_weak_aura = is_emitting_weak_aura
	dup.pending_transfers = pending_transfers.duplicate()
	return dup
