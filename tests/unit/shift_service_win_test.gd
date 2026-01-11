extends GdUnitTestSuite

const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")
const MagicConfigScript := preload("res://scripts/domain/magic/magic_config.gd")
const MagicSystemScript := preload("res://scripts/domain/magic/magic_system.gd")
const InspectionConfigScript := preload("res://scripts/domain/inspection/inspection_config.gd")
const InspectionSystemScript := preload("res://scripts/domain/inspection/inspection_system.gd")

func test_shift_wins_when_targets_met_even_with_active_clients() -> void:
	var shift_service := ShiftServiceScript.new()
	var magic_config := MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_FREE,
		MagicSystemScript.EMERGENCY_COST_DEBT,
		0,
		5,
		0,
		MagicSystemScript.SEARCH_EFFECT_REVEAL_SLOT
	)
	var inspection_config := InspectionConfigScript.new(
		InspectionSystemScript.MODE_PER_SHIFT,
		3,
		true,
		{}
	)
	shift_service.setup(
		null,
		magic_config,
		inspection_config,
		ShiftServiceScript.SHIFT_DEFAULT_CONFIG,
		{}
	)
	shift_service.start_shift()
	shift_service.configure_shift_targets(2, 2)
	shift_service.update_active_client_count(1)

	var won_payloads: Array = []
	shift_service.shift_won.connect(func(payload) -> void:
		won_payloads.append(payload)
	)

	shift_service.register_checkin_completed(StringName("Client_A"))
	assert_int(won_payloads.size()).is_equal(0)
	shift_service.register_checkout_completed(StringName("Client_A"))
	shift_service.register_checkin_completed(StringName("Client_B"))
	shift_service.update_active_client_count(0)
	shift_service.register_checkout_completed(StringName("Client_B"))
	assert_int(won_payloads.size()).is_equal(1)

func test_shift_wont_win_after_failure() -> void:
	var shift_service := ShiftServiceScript.new()
	var magic_config := MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_FREE,
		MagicSystemScript.EMERGENCY_COST_DEBT,
		0,
		5,
		0,
		MagicSystemScript.SEARCH_EFFECT_REVEAL_SLOT
	)
	var inspection_config := InspectionConfigScript.new(
		InspectionSystemScript.MODE_PER_SHIFT,
		3,
		true,
		{}
	)
	var shift_config := {
		"strikes_limit": 1,
		"patience_max": 1.0,
	}
	shift_service.setup(
		null,
		magic_config,
		inspection_config,
		shift_config,
		{}
	)
	shift_service.start_shift()
	shift_service.configure_shift_targets(1, 1)
	shift_service.configure_patience_clients([StringName("Client_A")])

	var won_payloads: Array = []
	shift_service.shift_won.connect(func(payload) -> void:
		won_payloads.append(payload)
	)

	shift_service.tick_patience([StringName("Client_A")], 1.0)
	shift_service.update_active_client_count(0)
	shift_service.register_checkin_completed(StringName("Client_A"))
	shift_service.register_checkout_completed(StringName("Client_A"))
	assert_int(won_payloads.size()).is_equal(0)

func test_shift_counters_dedup_by_client_id() -> void:
	var shift_service := ShiftServiceScript.new()
	var magic_config := MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_FREE,
		MagicSystemScript.EMERGENCY_COST_DEBT,
		0,
		5,
		0,
		MagicSystemScript.SEARCH_EFFECT_REVEAL_SLOT
	)
	var inspection_config := InspectionConfigScript.new(
		InspectionSystemScript.MODE_PER_SHIFT,
		3,
		true,
		{}
	)
	shift_service.setup(
		null,
		magic_config,
		inspection_config,
		ShiftServiceScript.SHIFT_DEFAULT_CONFIG,
		{}
	)
	shift_service.start_shift()
	shift_service.configure_shift_targets(2, 2)

	shift_service.register_checkin_completed(StringName("Client_A"))
	shift_service.register_checkin_completed(StringName("Client_A"))
	shift_service.register_checkout_completed(StringName("Client_A"))
	shift_service.register_checkout_completed(StringName("Client_A"))

	var snapshot: Dictionary = shift_service.get_queue_mix_snapshot()
	assert_int(int(snapshot.get("checkin_done", 0))).is_equal(1)
	assert_int(int(snapshot.get("checkout_done", 0))).is_equal(1)
