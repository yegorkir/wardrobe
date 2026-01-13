extends GdUnitTestSuite

const ShiftPatienceSystem := preload("res://scripts/app/shift/shift_patience_system.gd")
const ShiftPatienceState := preload("res://scripts/domain/shift/shift_patience_state.gd")

var _system: ShiftPatienceSystem
var _state: ShiftPatienceState

func before_test() -> void:
	_system = ShiftPatienceSystem.new()
	_state = ShiftPatienceState.new()
	_state.reset(["c1", "c2", "c3"], 30.0, 3)

func test_tick_patience_decay_rates() -> void:
	# c1 is active (slot)
	# c2 is queued
	# c3 is pool (neither)
	
	var active = ["c1"]
	var queued = ["c2"]
	var slot_rate = 1.0
	var queue_mult = 0.5
	var delta = 1.0
	
	_system.tick_patience(_state, active, queued, slot_rate, queue_mult, delta)
	
	# c1: 30 - 1.0 * 1.0 = 29.0
	assert_float(_state.get_patience_left("c1")).is_equal(29.0)
	
	# c2: 30 - 1.0 * 1.0 * 0.5 = 29.5
	assert_float(_state.get_patience_left("c2")).is_equal(29.5)
	
	# c3: 30 (no decay)
	assert_float(_state.get_patience_left("c3")).is_equal(30.0)

func test_strikes_on_zero() -> void:
	_state.set_patience_left("c1", 0.5)
	
	var active = ["c1"]
	var queued = []
	
	var result = _system.tick_patience(_state, active, queued, 1.0, 0.5, 1.0)
	
	assert_float(_state.get_patience_left("c1")).is_equal(0.0)
	assert_int(_state.strikes_current).is_equal(1)
	assert_array(result["strike_client_ids"]).contains_exactly(["c1"])

func test_no_double_strike() -> void:
	_state.set_patience_left("c1", 0.0)
	_state.strikes_current = 0
	
	var active = ["c1"]
	var queued = []
	
	var result = _system.tick_patience(_state, active, queued, 1.0, 0.5, 1.0)
	
	assert_float(_state.get_patience_left("c1")).is_equal(0.0)
	assert_int(_state.strikes_current).is_equal(0) # Already at 0, no new strike
	assert_array(result["strike_client_ids"]).is_empty()
