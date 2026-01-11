extends GdUnitTestSuite

const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")

func test_shift_wins_when_all_served_and_no_active_clients() -> void:
	var shift_service := ShiftServiceScript.new()
	shift_service.setup(
		null,
		ShiftServiceScript.MAGIC_DEFAULT_CONFIG,
		ShiftServiceScript.INSPECTION_DEFAULT_CONFIG,
		ShiftServiceScript.SHIFT_DEFAULT_CONFIG,
		{}
	)
	shift_service.start_shift()
	shift_service.configure_shift_clients(2)
	shift_service.update_active_client_count(1)

	var won_payloads: Array = []
	shift_service.shift_won.connect(func(payload: Dictionary) -> void:
		won_payloads.append(payload)
	)

	shift_service.register_client_completed()
	assert_int(won_payloads.size()).is_equal(0)
	shift_service.update_active_client_count(0)
	shift_service.register_client_completed()
	assert_int(won_payloads.size()).is_equal(1)

func test_shift_wont_win_after_failure() -> void:
	var shift_service := ShiftServiceScript.new()
	var shift_config := {
		"strikes_limit": 1,
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
	shift_service.configure_shift_clients(1)
	shift_service.configure_patience_clients([StringName("Client_A")])

	var won_payloads: Array = []
	shift_service.shift_won.connect(func(payload: Dictionary) -> void:
		won_payloads.append(payload)
	)

	shift_service.tick_patience([StringName("Client_A")], 1.0)
	shift_service.update_active_client_count(0)
	shift_service.register_client_completed()
	assert_int(won_payloads.size()).is_equal(0)
