extends GdUnitTestSuite

const ShiftLog := preload("res://scripts/app/logging/shift_log.gd")

func test_record_and_get_events_returns_copy() -> void:
	var event_log := ShiftLog.new()
	event_log.record(&"event_a", {"value": 1})
	event_log.record(&"event_b", {"value": 2})
	var events := event_log.get_events()
	assert_int(events.size()).is_equal(2)
	assert_that(events[0].event_type).is_equal(&"event_a")
	assert_that(events[0].payload.get("value")).is_equal(1)
	events.clear()
	assert_int(event_log.get_events().size()).is_equal(2)

func test_clear_removes_events() -> void:
	var event_log := ShiftLog.new()
	event_log.record(&"test", {})
	event_log.clear()
	assert_that(event_log.get_events()).is_empty()
