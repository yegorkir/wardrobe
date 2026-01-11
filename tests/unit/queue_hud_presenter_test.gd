extends GdUnitTestSuite

const QueueHudPresenterScript := preload("res://scripts/app/queue/queue_hud_presenter.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_presenter_builds_remaining_counts_and_order() -> void:
	var presenter = QueueHudPresenterScript.new()
	var queue_state := ClientQueueStateScript.new()
	queue_state.enqueue_checkin(StringName("Client_A"))
	queue_state.enqueue_checkin(StringName("Client_B"))
	var clients := {
		StringName("Client_A"): _make_client(StringName("Client_A")),
		StringName("Client_B"): _make_client(StringName("Client_B")),
	}
	var queue_mix := {
		"need_in": 2,
		"need_out": 1,
	}
	var result = presenter.call(
		"build_result",
		queue_state,
		clients,
		queue_mix,
		{},
		1,
		3,
		8,
		{}
	)
	assert_object(result).is_not_null()
	assert_int(int(result.snapshot.remaining_checkin)).is_equal(2)
	assert_int(int(result.snapshot.remaining_checkout)).is_equal(1)
	var ids: Array[StringName] = result.snapshot.get_client_ids()
	assert_array(ids).is_equal([StringName("Client_A"), StringName("Client_B")])

func test_presenter_marks_timeouts_once() -> void:
	var presenter = QueueHudPresenterScript.new()
	var queue_state := ClientQueueStateScript.new()
	queue_state.enqueue_checkin(StringName("Client_A"))
	queue_state.enqueue_checkin(StringName("Client_B"))
	var clients := {
		StringName("Client_A"): _make_client(StringName("Client_A")),
		StringName("Client_B"): _make_client(StringName("Client_B")),
	}
	var patience_by := {
		StringName("Client_B"): 0.0,
	}
	var timed_out: Dictionary = {}
	var result = presenter.call(
		"build_result",
		queue_state,
		clients,
		{"need_in": 1, "need_out": 1},
		patience_by,
		0,
		0,
		8,
		timed_out
	)
	assert_array(result.timed_out_ids).is_equal([StringName("Client_B")])
	for client_id in result.timed_out_ids:
		timed_out[client_id] = true
	var second = presenter.call(
		"build_result",
		queue_state,
		clients,
		{"need_in": 1, "need_out": 1},
		patience_by,
		0,
		0,
		8,
		timed_out
	)
	assert_array(second.snapshot.get_client_ids()).is_equal([StringName("Client_A")])

func _make_client(client_id: StringName) -> ClientState:
	var coat := ItemInstanceScript.new(StringName("coat_%s" % client_id), ItemInstanceScript.KIND_COAT)
	var ticket := ItemInstanceScript.new(StringName("ticket_%s" % client_id), ItemInstanceScript.KIND_TICKET)
	return ClientStateScript.new(client_id, coat, ticket)
