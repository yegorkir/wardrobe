extends GdUnitTestSuite

const PolicyScript := preload("res://scripts/app/desk/reject_consequence_policy.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")

func test_wrong_item_checkout_triggers_drop_and_penalty() -> void:
	var policy := PolicyScript.new()
	var result: Dictionary = policy.evaluate(EventSchema.REASON_WRONG_ITEM, ClientStateScript.PHASE_PICK_UP)

	assert_bool(bool(result.get("apply_patience_penalty", false))).is_true()
	assert_that(result.get("penalty_reason")).is_equal(EventSchema.REASON_WRONG_ITEM)

func test_wrong_item_checkin_triggers_drop_and_penalty() -> void:
	var policy := PolicyScript.new()
	var result: Dictionary = policy.evaluate(EventSchema.REASON_WRONG_ITEM, ClientStateScript.PHASE_DROP_OFF)

	assert_bool(bool(result.get("apply_patience_penalty", false))).is_true()
	assert_that(result.get("penalty_reason")).is_equal(EventSchema.REASON_WRONG_ITEM)

func test_other_reject_checkout_no_consequences() -> void:
	var policy := PolicyScript.new()
	var result: Dictionary = policy.evaluate(EventSchema.REASON_CLIENT_AWAY, ClientStateScript.PHASE_PICK_UP)

	assert_bool(bool(result.get("apply_patience_penalty", true))).is_false()

func test_other_reject_checkin_no_consequences() -> void:
	var policy := PolicyScript.new()
	var result: Dictionary = policy.evaluate(EventSchema.REASON_CLIENT_AWAY, ClientStateScript.PHASE_DROP_OFF)

	assert_bool(bool(result.get("apply_patience_penalty", true))).is_false()
