extends RefCounted

class_name ClientFlowService

const ClientFlowSnapshotScript := preload("res://scripts/app/clients/client_flow_snapshot.gd")

var _get_snapshot: Callable
var _last_snapshot
var _elapsed: float = 0.0
var _tick_interval_sec: float = 0.2

func configure(get_snapshot: Callable, config: RefCounted = null) -> void:
	_get_snapshot = get_snapshot
	_elapsed = 0.0
	if config != null:
		_tick_interval_sec = max(0.0, float(config.tick_interval_sec))

func tick(delta: float) -> void:
	if not _get_snapshot.is_valid():
		return
	if _tick_interval_sec > 0.0:
		_elapsed += delta
		if _elapsed < _tick_interval_sec:
			return
		_elapsed = 0.0
	var snapshot = _get_snapshot.call()
	if snapshot == null:
		return
	_last_snapshot = snapshot

func get_last_snapshot() -> RefCounted:
	return _last_snapshot.duplicate_snapshot() if _last_snapshot else null
