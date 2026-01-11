extends GdUnitTestSuite

const QueueMixPolicyScript := preload("res://scripts/app/queue/queue_mix_policy.gd")

func test_outstanding_zero_prefers_checkin() -> void:
	var policy := QueueMixPolicyScript.new()
	var result := policy.select_next_source({
		"need_in": 3,
		"need_out": 3,
		"outstanding": 0,
		"progress": 0.2,
	})
	assert_that(result).is_equal(QueueMixPolicyScript.SOURCE_CHECKIN)

func test_need_in_zero_prefers_checkout() -> void:
	var policy := QueueMixPolicyScript.new()
	var result := policy.select_next_source({
		"need_in": 0,
		"need_out": 2,
		"outstanding": 2,
		"progress": 0.4,
	})
	assert_that(result).is_equal(QueueMixPolicyScript.SOURCE_CHECKOUT)

func test_need_out_zero_prefers_checkin() -> void:
	var policy := QueueMixPolicyScript.new()
	var result := policy.select_next_source({
		"need_in": 2,
		"need_out": 0,
		"outstanding": 0,
		"progress": 0.4,
	})
	assert_that(result).is_equal(QueueMixPolicyScript.SOURCE_CHECKIN)

func test_late_progress_biases_checkout() -> void:
	var policy := QueueMixPolicyScript.new()
	var result := policy.select_next_source({
		"need_in": 2,
		"need_out": 2,
		"outstanding": 1,
		"progress": 0.9,
	})
	assert_that(result).is_equal(QueueMixPolicyScript.SOURCE_CHECKOUT)
