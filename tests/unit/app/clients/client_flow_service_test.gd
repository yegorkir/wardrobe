extends GdUnitTestSuite

const ClientFlowServiceScript := preload("res://scripts/app/clients/client_flow_service.gd")
const ClientFlowSnapshotScript := preload("res://scripts/app/clients/client_flow_snapshot.gd")
const ClientFlowConfigScript := preload("res://scripts/app/clients/client_flow_config.gd")

var _snapshot_calls: int = 0

func _build_snapshot() -> RefCounted:
	_snapshot_calls += 1
	return ClientFlowSnapshotScript.new(
		10,
		2,
		3,
		1,
		2,
		1,
		0,
		1
	)

func test_tick_respects_interval() -> void:
	_snapshot_calls = 0
	var service = ClientFlowServiceScript.new()
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.5
	service.configure(Callable(self, "_build_snapshot"), config)

	service.tick(0.1)
	assert_that(_snapshot_calls).is_equal(0)
	service.tick(0.4)
	assert_that(_snapshot_calls).is_equal(1)
	assert_that(service.get_last_snapshot()).is_not_null()

func test_tick_immediate_when_interval_zero() -> void:
	_snapshot_calls = 0
	var service = ClientFlowServiceScript.new()
	var config = ClientFlowConfigScript.new()
	config.tick_interval_sec = 0.0
	service.configure(Callable(self, "_build_snapshot"), config)

	service.tick(0.1)
	assert_that(_snapshot_calls).is_equal(1)
