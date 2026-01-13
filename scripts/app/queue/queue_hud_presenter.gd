extends RefCounted

class_name QueueHudPresenter

const QueueHudClientVMScript := preload("res://scripts/app/queue/queue_hud_client_vm.gd")
const QueueHudSnapshotScript := preload("res://scripts/app/queue/queue_hud_snapshot.gd")
const QueueHudBuildResultScript := preload("res://scripts/app/queue/queue_hud_build_result.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")

const STATUS_QUEUED := StringName("queued")
const STATUS_LEAVING_RED := StringName("leaving_red")

func build_result(
	queue_state: ClientQueueState,
	clients: Dictionary,
	queue_mix: Dictionary,
	patience_by: Dictionary,
	patience_max_by: Dictionary,
	strikes_current: int,
	strikes_limit: int,
	max_visible: int,
	timed_out_ids: Dictionary
) -> RefCounted:
	var upcoming: Array = []
	var new_timeouts: Array[StringName] = []
	var queue_ids: Array[StringName] = []
	if queue_state:
		queue_ids = queue_state.get_snapshot()
	for client_id in queue_ids:
		if upcoming.size() >= max_visible:
			break
		if timed_out_ids.has(client_id):
			continue
		var client_state: ClientState = clients.get(client_id, null) as ClientState
		var portrait_key := _resolve_portrait_key(client_state)
		var status := STATUS_QUEUED
		var patience_left := float(patience_by.get(client_id, 1.0))
		var patience_max := float(patience_max_by.get(client_id, 30.0))
		
		if patience_left <= 0.0:
			status = STATUS_LEAVING_RED
			new_timeouts.append(client_id)
			
		var ratio := 1.0
		if patience_max > 0.0:
			ratio = clampf(patience_left / patience_max, 0.0, 1.0)
			
		var vm := QueueHudClientVMScript.new(
			client_id,
			portrait_key,
			[],
			status,
			ratio
		)
		upcoming.append(vm)
	var remaining_checkin := int(queue_mix.get("need_in", 0))
	var remaining_checkout := int(queue_mix.get("need_out", 0))
	var snapshot := QueueHudSnapshotScript.new(
		upcoming,
		remaining_checkin,
		remaining_checkout,
		strikes_current,
		strikes_limit
	)
	return QueueHudBuildResultScript.new(snapshot, new_timeouts)

func _resolve_portrait_key(client_state: ClientState) -> StringName:
	if client_state == null:
		return StringName()
	if client_state.portrait_key != StringName():
		return client_state.portrait_key
	if client_state.client_def_id != StringName():
		return client_state.client_def_id
	if client_state.archetype_id != StringName():
		return client_state.archetype_id
	return client_state.color_id
