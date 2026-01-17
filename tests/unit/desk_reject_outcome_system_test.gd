extends GdUnitTestSuite

const DeskRejectOutcomeSystemScript := preload("res://scripts/app/desk/desk_reject_outcome_system.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

func test_reject_return_applies_patience_penalty() -> void:
	var system := DeskRejectOutcomeSystemScript.new()
	var penalty_calls: Array = []
	var apply_penalty := func(client_id: StringName, amount: float, reason_code: StringName) -> void:
		penalty_calls.append({
			"id": client_id,
			"amount": amount,
			"reason": reason_code,
		})
	system.configure(apply_penalty)
	var reject_event := {
		EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_DELIVER_RESULT_REJECT_RETURN,
		EventSchema.EVENT_KEY_PAYLOAD: {
			EventSchema.PAYLOAD_CLIENT_ID: StringName("Client_A"),
			EventSchema.PAYLOAD_PATIENCE_DELTA: 5.0,
			EventSchema.PAYLOAD_REASON_CODE: EventSchema.REASON_WRONG_ITEM,
		},
	}

	system.process_desk_events([reject_event])

	assert_int(penalty_calls.size()).is_equal(1)
	assert_that(penalty_calls[0]["id"]).is_equal(StringName("Client_A"))
	assert_that(penalty_calls[0]["amount"]).is_equal(5.0)
