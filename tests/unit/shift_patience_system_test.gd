extends GdUnitTestSuite

const ShiftPatienceStateScript := preload("res://scripts/domain/shift/shift_patience_state.gd")
const ShiftPatienceSystemScript := preload("res://scripts/app/shift/shift_patience_system.gd")
const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")

func test_strike_increments_only_on_transition() -> void:
	var state := ShiftPatienceStateScript.new()
	var system := ShiftPatienceSystemScript.new()
	system.reset_for_shift(state, [StringName("Client_A")], 1.0, 3)

	var result := system.tick_patience(state, [StringName("Client_A")], 0.5)
	assert_int(state.strikes_current).is_equal(0)
	assert_float(state.get_patience_left(StringName("Client_A"))).is_equal(0.5)
	assert_int((result.get("strike_client_ids") as Array).size()).is_equal(0)

	result = system.tick_patience(state, [StringName("Client_A")], 0.6)
	assert_int(state.strikes_current).is_equal(1)
	assert_float(state.get_patience_left(StringName("Client_A"))).is_equal(0.0)
	assert_int((result.get("strike_client_ids") as Array).size()).is_equal(1)

	result = system.tick_patience(state, [StringName("Client_A")], 1.0)
	assert_int(state.strikes_current).is_equal(1)
	assert_int((result.get("strike_client_ids") as Array).size()).is_equal(0)

func test_no_strike_when_starting_at_zero() -> void:
	var state := ShiftPatienceStateScript.new()
	var system := ShiftPatienceSystemScript.new()
	system.reset_for_shift(state, [StringName("Client_A")], 0.0, 3)

	var result := system.tick_patience(state, [StringName("Client_A")], 1.0)
	assert_int(state.strikes_current).is_equal(0)
	assert_int((result.get("strike_client_ids") as Array).size()).is_equal(0)

func test_patience_ticks_only_for_active_clients() -> void:
	var state := ShiftPatienceStateScript.new()
	var system := ShiftPatienceSystemScript.new()
	system.reset_for_shift(state, [StringName("Client_A"), StringName("Client_B")], 1.0, 3)

	system.tick_patience(state, [StringName("Client_A")], 0.5)
	assert_float(state.get_patience_left(StringName("Client_A"))).is_equal(0.5)
	assert_float(state.get_patience_left(StringName("Client_B"))).is_equal(1.0)

func test_shift_service_fails_at_strike_limit() -> void:
	var shift_service := ShiftServiceScript.new()
	var shift_config := {
		"strikes_limit": 3,
		"patience_max": 1.0,
	}
	shift_service.setup(
		null,
		ShiftServiceScript.MAGIC_DEFAULT_CONFIG,
		ShiftServiceScript.INSPECTION_DEFAULT_CONFIG,
		shift_config,
		{}
	)
	shift_service.start_shift()
	shift_service.configure_patience_clients([
		StringName("Client_A"),
		StringName("Client_B"),
		StringName("Client_C"),
	])

	var failed_payloads: Array = []
	shift_service.shift_failed.connect(func(payload: Dictionary) -> void:
		failed_payloads.append(payload)
	)

	shift_service.tick_patience(
		[StringName("Client_A"), StringName("Client_B"), StringName("Client_C")],
		1.0
	)

	assert_int(failed_payloads.size()).is_equal(1)
	var failed_payload: Dictionary = failed_payloads[0]
	assert_that(failed_payload.get("reason")).is_equal("strikes")
	assert_int(int(failed_payload.get("strikes_current", 0))).is_equal(3)
