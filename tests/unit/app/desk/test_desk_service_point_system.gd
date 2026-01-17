extends GdUnitTestSuite

const DeskServicePointSystemScript := preload("res://scripts/app/desk/desk_service_point_system.gd")
const DeskStateScript := preload("res://scripts/domain/desk/desk_state.gd")
const ClientQueueStateScript := preload("res://scripts/domain/clients/client_queue_state.gd")
const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const WardrobeStorageStateScript := preload("res://scripts/domain/storage/wardrobe_storage_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_checkout_client_dropoff_spawns_ticket() -> void:
	var system := DeskServicePointSystemScript.new()
	var desk_state := DeskStateScript.new(StringName("Desk_A"), StringName("Desk_A_Slot"))
	var queue_state := ClientQueueStateScript.new()
	var storage_state := WardrobeStorageStateScript.new()
	var tray_slot := StringName("Desk_A_Tray_0")
	system.register_tray_slots(desk_state.desk_id, [tray_slot])
	storage_state.register_slot(tray_slot)

	var ticket := ItemInstanceScript.new(StringName("ticket_1"), ItemInstanceScript.KIND_TICKET)
	var client := ClientStateScript.new(StringName("client_out_0"), null, ticket)
	var clients := { client.client_id: client }
	queue_state.enqueue_checkout(client.client_id)

	var events: Array = system.assign_next_client_to_desk(
		desk_state,
		queue_state,
		clients,
		storage_state
	)

	assert_that(events.is_empty()).is_false()
	assert_that(storage_state.get_slot_item(tray_slot)).is_equal(ticket)
