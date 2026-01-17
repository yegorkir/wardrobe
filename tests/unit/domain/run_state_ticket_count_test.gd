extends GdUnitTestSuite

const RunStateScript := preload("res://scripts/domain/run/run_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_register_item_counts_ticket_once() -> void:
	var run_state: RunState = RunStateScript.new()
	var ticket := ItemInstanceScript.new(
		StringName("ticket_1"),
		ItemInstanceScript.KIND_TICKET,
		StringName(),
		Color.WHITE
	)
	var coat := ItemInstanceScript.new(
		StringName("coat_1"),
		ItemInstanceScript.KIND_COAT,
		StringName(),
		Color.WHITE
	)

	run_state.register_item(ticket)
	run_state.register_item(ticket)
	run_state.register_item(coat)

	assert_that(run_state.get_total_tickets()).is_equal(1)
