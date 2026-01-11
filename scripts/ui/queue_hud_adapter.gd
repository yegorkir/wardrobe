extends RefCounted

class_name QueueHudAdapter

const QueueHudPresenterScript := preload("res://scripts/app/queue/queue_hud_presenter.gd")
const QueueHudSnapshotScript := preload("res://scripts/app/queue/queue_hud_snapshot.gd")
const QueueHudViewScript := preload("res://scripts/ui/queue_hud_view.gd")
const DebugLogScript := preload("res://scripts/wardrobe/debug/debug_log.gd")

const EVENT_RENDER := StringName("HUD_QUEUE_RENDER")
const EVENT_APPEND := StringName("HUD_QUEUE_APPEND")
const EVENT_POP := StringName("HUD_QUEUE_POP")
const EVENT_TIMEOUT := StringName("HUD_QUEUE_TIMEOUT")

var _presenter = QueueHudPresenterScript.new()
var _view
var _queue_state: ClientQueueState
var _clients: Dictionary = {}
var _run_manager: RunManagerBase
var _patience_by: Dictionary = {}
var _max_visible: int = 6
var _timed_out_ids: Dictionary = {}
var _prev_ids: Array[StringName] = []
var _debug_snapshot
var _use_debug_snapshot := false

func configure(
	view,
	queue_state: ClientQueueState,
	clients: Dictionary,
	run_manager: RunManagerBase,
	patience_by: Dictionary,
	max_visible: int = 6
) -> void:
	_view = view
	_queue_state = queue_state
	_clients = clients
	_run_manager = run_manager
	_patience_by = patience_by
	_max_visible = max(0, max_visible)

func set_debug_snapshot(snapshot, enabled: bool = true) -> void:
	_debug_snapshot = snapshot
	_use_debug_snapshot = enabled and snapshot != null

func update() -> void:
	if _view == null:
		return
	var snapshot: RefCounted = _build_snapshot()
	if snapshot == null:
		return
	_view.apply_snapshot(snapshot)
	_log_diff(snapshot)

func _build_snapshot():
	if _use_debug_snapshot and _debug_snapshot:
		return _debug_snapshot.duplicate_snapshot()
	var queue_mix: Dictionary = {}
	var strikes_current := 0
	var strikes_limit := 0
	if _run_manager:
		queue_mix = _run_manager.get_queue_mix_snapshot()
		var hud_snapshot: RefCounted = _run_manager.get_hud_snapshot()
		if hud_snapshot:
			strikes_current = hud_snapshot.strikes_current
			strikes_limit = hud_snapshot.strikes_limit
	var result := _presenter.build_result(
		_queue_state,
		_clients,
		queue_mix,
		_patience_by,
		strikes_current,
		strikes_limit,
		_max_visible,
		_timed_out_ids
	)
	if result == null:
		return null
	for client_id in result.timed_out_ids:
		if _timed_out_ids.has(client_id):
			continue
		_timed_out_ids[client_id] = true
		DebugLogScript.event(EVENT_TIMEOUT, {"client_id": client_id})
	return result.snapshot

func _log_diff(snapshot) -> void:
	var ids: Array[StringName] = snapshot.get_client_ids()
	DebugLogScript.event(EVENT_RENDER, {
		"count": ids.size(),
		"ids": ids,
	})
	for client_id in ids:
		if not _prev_ids.has(client_id):
			DebugLogScript.event(EVENT_APPEND, {"client_id": client_id})
	for client_id in _prev_ids:
		if not ids.has(client_id):
			DebugLogScript.event(EVENT_POP, {"client_id": client_id})
	_prev_ids = ids.duplicate()
