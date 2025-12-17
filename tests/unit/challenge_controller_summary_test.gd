extends GdUnitTestSuite

const Controller := preload("res://scripts/app/challenge/challenge_controller.gd")
const Command := preload("res://scripts/app/interaction/interaction_command.gd")

func _make_definition() -> Dictionary:
	return {
		"id": "test_challenge",
		"seed_layout": [],
		"target_layout": [{"slot_id": "Slot_0", "item_id": "coat_1", "item_type": "COAT"}],
	}

func test_summary_counts_actions_from_shift_log() -> void:
	var controller := Controller.new()
	controller.configure(_make_definition(), {}, "fallback")
	controller.start_session()
	controller.clear_shift_log()
	var command := Command.build(Command.TYPE_PICK, 0, StringName("Slot_0"), "coat_1", "")
	controller.record_interaction_event(command, true, "pick_complete", "Slot_0")
	var summary := controller.get_summary_snapshot()
	assert_int(summary.get("actions", 0)).is_equal(1)
	assert_int(summary.get("picks", 0)).is_equal(1)
	assert_int(summary.get("puts", 0)).is_equal(0)
	assert_int(summary.get("swaps", 0)).is_equal(0)
