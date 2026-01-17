extends RefCounted

class_name ClientFlowService

signal request_spawn(request: RefCounted)

const ClientFlowSnapshotScript := preload("res://scripts/app/clients/client_flow_snapshot.gd")
const ClientSpawnRequestScript := preload("res://scripts/app/clients/client_spawn_request.gd")
const ClientFlowConfigScript := preload("res://scripts/app/clients/client_flow_config.gd")

var _get_snapshot: Callable
var _last_snapshot: RefCounted
var _elapsed: float = 0.0
var _tick_interval_sec: float = 0.2
var _spawn_cooldown: float = 0.0
var _config: RefCounted

func configure(get_snapshot: Callable, config: RefCounted = null) -> void:
	_get_snapshot = get_snapshot
	_elapsed = 0.0
	_config = config if config else ClientFlowConfigScript.new()
	var interval: Variant = _config.get("tick_interval_sec")
	_tick_interval_sec = max(0.0, float(interval) if interval != null else 0.2)
	_reset_cooldown()

func tick(delta: float) -> void:
	if not _get_snapshot.is_valid():
		return
	
	# Update cooldown every frame to ensure real-time scaling
	if _spawn_cooldown > 0.0:
		_spawn_cooldown -= delta
	
	# Guard for periodic metric sampling and director logic
	if _should_skip_tick(delta):
		return

	var snapshot = _get_snapshot.call()
	if snapshot == null:
		return
	_last_snapshot = snapshot

	# Only process spawn decisions if timer reached zero
	if _spawn_cooldown <= 0.0:
		_process_director_logic(snapshot)

func get_last_snapshot() -> RefCounted:
	return _last_snapshot.duplicate_snapshot() if _last_snapshot else null

func _should_skip_tick(delta: float) -> bool:
	if _tick_interval_sec > 0.0:
		_elapsed += delta
		if _elapsed < _tick_interval_sec:
			return true
		_elapsed = 0.0
	return false

func _process_director_logic(snapshot: RefCounted) -> void:
	# Hard Constraints
	if snapshot.get("queue_total") >= _config.get("max_queue_size"):
		return # Queue full
	
	if snapshot.call("get_free_hook_capacity") < _config.get("min_free_hooks"):
		# Only block if we plan to check-in (requires hook). 
		# But for simplicity, let's say "no free hooks" blocks everything 
		# OR we check type first. Let's block check-in later.
		pass

	# Decide Type
	var spawn_type = ClientSpawnRequestScript.Type.CHECKIN
	var reason = "default"
	
	# If no tickets taken (nobody has clothes stored), we MUST do check-in
	if snapshot.get("tickets_taken") <= 0:
		spawn_type = ClientSpawnRequestScript.Type.CHECKIN
		reason = "no_tickets_taken"
	else:
		# Balance logic
		var current_total = snapshot.get("queue_total")
		# Avoid division by zero
		var ratio = 0.0
		if current_total > 0:
			ratio = float(snapshot.get("queue_checkout")) / float(current_total)
		
		# If checkout ratio is below target -> prefer checkout
		# But ensure we have capacity for checkin if we choose checkin
		if ratio < _config.get("target_checkout_ratio"):
			spawn_type = ClientSpawnRequestScript.Type.CHECKOUT
			reason = "balance_checkout"
		else:
			spawn_type = ClientSpawnRequestScript.Type.CHECKIN
			reason = "balance_checkin"
	
	# Capacity check for CHECKIN
	if spawn_type == ClientSpawnRequestScript.Type.CHECKIN:
		if snapshot.call("get_free_hook_capacity") < _config.get("min_free_hooks"):
			return # Cannot spawn checkin, no hooks

	# All checks passed
	var request = ClientSpawnRequestScript.new(spawn_type, reason)
	request_spawn.emit(request)
	
	_reset_cooldown()

func _reset_cooldown() -> void:
	if _config:
		var range_val = _config.get("spawn_cooldown_range")
		_spawn_cooldown = randf_range(range_val.x, range_val.y)
	else:
		_spawn_cooldown = 2.0
