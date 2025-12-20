extends GdUnitTestSuite

const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")

func test_enqueue_and_pop_preserves_order() -> void:
	var queue := ClientQueueStateScript.new()
	var client_a := StringName("Client_A")
	var client_b := StringName("Client_B")

	queue.enqueue(client_a)
	queue.enqueue(client_b)

	assert_that(queue.peek_next()).is_equal(client_a)
	assert_that(queue.pop_next()).is_equal(client_a)
	assert_that(queue.pop_next()).is_equal(client_b)
	assert_that(queue.pop_next()).is_equal(StringName())

func test_enqueue_deduplicates_and_remove() -> void:
	var queue := ClientQueueStateScript.new()
	var client_a := StringName("Client_A")

	queue.enqueue(client_a)
	queue.enqueue(client_a)

	assert_that(queue.get_count()).is_equal(1)
	queue.remove(client_a)
	assert_that(queue.get_count()).is_equal(0)
