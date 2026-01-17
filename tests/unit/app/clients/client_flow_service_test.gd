extends GdUnitTestSuite

const ClientFlowServiceScript := preload("res://scripts/app/clients/client_flow_service.gd")
const ClientFlowSnapshotScript := preload("res://scripts/app/clients/client_flow_snapshot.gd")
const ClientFlowConfigScript := preload("res://scripts/app/clients/client_flow_config.gd")
const ClientSpawnRequestScript := preload("res://scripts/app/clients/client_spawn_request.gd")

var _snapshot_calls: int = 0
var _test_snapshot: RefCounted = null
var _spawn_requests: Array = []

func before_test() -> void:
	_snapshot_calls = 0
	_test_snapshot = null
	_spawn_requests.clear()

func _build_snapshot() -> RefCounted:
	_snapshot_calls += 1
	return _test_snapshot

func _on_request_spawn(request: ClientSpawnRequest) -> void:
	_spawn_requests.append(request)

func test_tick_respects_interval() -> void:
	var service = ClientFlowServiceScript.new()
	var config = ClientFlowConfigScript.new()
	# Set huge cooldown so logic doesn't block tick, or small config
	# Actually, tick interval controls when logic runs.
	config.tick_interval_sec = 0.5
	service.configure(Callable(self, "_build_snapshot"), config)
	
	# Mock snapshot
	_test_snapshot = ClientFlowSnapshotScript.new(10, 0, 0, 0, 0, 0, 0, 0)

	service.tick(0.1)
	assert_that(_snapshot_calls).is_equal(0)
	service.tick(0.4)
	assert_that(_snapshot_calls).is_equal(1)

func test_spawn_cooldown_blocks_requests() -> void:
	var service = ClientFlowServiceScript.new()
	service.request_spawn.connect(_on_request_spawn)
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.0 # Tick logic immediately
	config.spawn_cooldown_range = Vector2(10.0, 10.0) # 10 sec cooldown
	service.configure(Callable(self, "_build_snapshot"), config)
	
	_test_snapshot = ClientFlowSnapshotScript.new(10, 0, 0, 0, 0, 0, 0, 0)

	# First tick -> Cooldown is active (10s), but snapshot should update? 
	# With interval 0.0, snapshot updates every tick.
	# But logic won't spawn.
	
	service.tick(0.1)
	assert_that(_spawn_requests).is_empty()
	assert_that(_snapshot_calls).is_equal(1) # Snapshot collected!
	
	# Advance time by 5s. Cooldown should be 4.9s.
	service.tick(5.0)
	assert_that(_spawn_requests).is_empty()
	assert_that(_snapshot_calls).is_equal(2)
	
	# Advance time by 5s. Cooldown should be expired (-0.1s).
	service.tick(5.0)
	assert_that(_spawn_requests).is_not_empty()
	assert_that(_snapshot_calls).is_equal(3)

func test_logic_queue_full_no_spawn() -> void:
	var service = ClientFlowServiceScript.new()
	service.request_spawn.connect(_on_request_spawn)
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.0
	config.spawn_cooldown_range = Vector2(0.0, 0.0) # No cooldown
	config.max_queue_size = 2
	service.configure(Callable(self, "_build_snapshot"), config)
	
	# Queue is full (2)
	_test_snapshot = ClientFlowSnapshotScript.new(10, 0, 2, 1, 1, 0, 0, 0)
	
	# We need to manually reset cooldown because configure sets it random
	# But we set range 0,0 so it should be 0.
	
	service.tick(0.1)
	assert_that(_spawn_requests).is_empty()

func test_logic_no_tickets_taken_forces_checkin() -> void:
	var service = ClientFlowServiceScript.new()
	service.request_spawn.connect(_on_request_spawn)
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.0
	config.spawn_cooldown_range = Vector2(0.0, 0.0)
	service.configure(Callable(self, "_build_snapshot"), config)
	
	# 0 tickets taken -> MUST be checkin
	_test_snapshot = ClientFlowSnapshotScript.new(10, 0, 0, 0, 0, 5, 0, 0)
	
	service.tick(0.1)
	assert_that(_spawn_requests).has_size(1)
	assert_that(_spawn_requests[0].type).is_equal(ClientSpawnRequestScript.Type.CHECKIN)

func test_logic_balance_prefers_checkout() -> void:
	var service = ClientFlowServiceScript.new()
	service.request_spawn.connect(_on_request_spawn)
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.0
	config.spawn_cooldown_range = Vector2(0.0, 0.0)
	config.target_checkout_ratio = 0.8 # Want 80% checkout
	service.configure(Callable(self, "_build_snapshot"), config)
	
	# Current: 1 checkin, 0 checkout. Ratio = 0.0 < 0.8.
	# Tickets taken = 5 (so checkout is possible)
	_test_snapshot = ClientFlowSnapshotScript.new(10, 0, 1, 1, 0, 5, 5, 0)
	
	service.tick(0.1)
	assert_that(_spawn_requests).has_size(1)
	assert_that(_spawn_requests[0].type).is_equal(ClientSpawnRequestScript.Type.CHECKOUT)