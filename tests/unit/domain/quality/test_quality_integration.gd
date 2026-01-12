extends GdUnitTestSuite

const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

func test_fall_damage_integration() -> void:
	var service := ShiftServiceScript.new()
	service.setup(null)
	service.start_shift()
	
	var item_id := StringName("test_coat")
	var item := ItemInstanceScript.new(item_id, ItemInstanceScript.KIND_COAT)
	service.register_item(item)
	
	# Initial quality 3.0
	assert_float(item.quality_state.current_stars).is_equal(3.0)
	
	# Land with impact 100.0 (should cause 1.0 damage)
	var payload := {
		EventSchema.PAYLOAD_ITEM_ID: item_id,
		EventSchema.PAYLOAD_IMPACT: 100.0,
		EventSchema.PAYLOAD_ITEM_KIND: ItemInstanceScript.KIND_COAT,
		EventSchema.PAYLOAD_SURFACE_KIND: EventSchema.SURFACE_KIND_FLOOR,
	}
	
	var outcome = service.record_item_landed(payload)
	
	assert_float(item.quality_state.current_stars).is_equal(2.0)
	assert_float(outcome.get("quality_delta")).is_equal(-1.0)
	
	# Verify log
	var log_events := service.get_shift_log().get_events()
	var quality_change_found := false
	for event in log_events:
		if event.event_type == EventSchema.EVENT_ITEM_QUALITY_CHANGED:
			quality_change_found = true
			var p = event.payload
			assert_str(p[EventSchema.PAYLOAD_ITEM_ID]).is_equal("test_coat")
			assert_float(p[EventSchema.PAYLOAD_OLD_VALUE]).is_equal(3.0)
			assert_float(p[EventSchema.PAYLOAD_NEW_VALUE]).is_equal(2.0)
	
	assert_bool(quality_change_found).is_true()

func test_fall_damage_quantization() -> void:
	var service := ShiftServiceScript.new()
	service.setup(null)
	service.start_shift()
	
	var item_id := StringName("test_coat_q")
	var item := ItemInstanceScript.new(item_id, ItemInstanceScript.KIND_COAT)
	service.register_item(item)
	
	# allowed steps are [0.5, 1.0, 2.0] by default in ItemQualityConfig
	
	# Impact 70.0 -> damage 0.7 -> should lose 0.5
	service.record_item_landed({
		EventSchema.PAYLOAD_ITEM_ID: item_id,
		EventSchema.PAYLOAD_IMPACT: 70.0,
	})
	assert_float(item.quality_state.current_stars).is_equal(2.5)
	
	# Impact 40.0 -> damage 0.4 -> should lose 0.0
	service.record_item_landed({
		EventSchema.PAYLOAD_ITEM_ID: item_id,
		EventSchema.PAYLOAD_IMPACT: 40.0,
	})
	assert_float(item.quality_state.current_stars).is_equal(2.5)
