extends GdUnitTestSuite

const LightService := preload("res://scripts/app/light/light_service.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")

var _service: LightService
var _last_event: StringName
var _last_payload: Dictionary

func before_test() -> void:
	_service = LightService.new(Callable(self, "_on_log"))
	_last_event = StringName()
	_last_payload = {}

func _on_log(event: StringName, payload: Dictionary) -> void:
	_last_event = event
	_last_payload = payload.duplicate()

func test_curtain_control() -> void:
	assert_float(_service.get_curtain_open_ratio()).is_equal(0.0)
	
	_service.set_curtain_open_ratio(0.5, "source_1")
	assert_float(_service.get_curtain_open_ratio()).is_equal(0.5)
	
	assert_str(_last_event).is_equal(EventSchema.EVENT_LIGHT_ADJUSTED)
	assert_str(_last_payload[EventSchema.PAYLOAD_SOURCE_ID]).is_equal("source_1")
	assert_float(_last_payload[EventSchema.PAYLOAD_OPEN_RATIO]).is_equal(0.5)
	
	# Clamping
	_service.set_curtain_open_ratio(1.5, "source_1")
	assert_float(_service.get_curtain_open_ratio()).is_equal(1.0)
	
	_service.set_curtain_open_ratio(-0.5, "source_1")
	assert_float(_service.get_curtain_open_ratio()).is_equal(0.0)

func test_bulb_control() -> void:
	assert_bool(_service.is_bulb_on(0)).is_false()
	
	_service.toggle_bulb(0, "bulb_0")
	assert_bool(_service.is_bulb_on(0)).is_true()
	
	assert_str(_last_event).is_equal(EventSchema.EVENT_LIGHT_TOGGLED)
	assert_str(_last_payload[EventSchema.PAYLOAD_SOURCE_ID]).is_equal("bulb_0")
	assert_bool(_last_payload[EventSchema.PAYLOAD_IS_ON]).is_true()
	assert_int(_last_payload[EventSchema.PAYLOAD_ROW_INDEX]).is_equal(0)
	
	_service.toggle_bulb(0, "bulb_0")
	assert_bool(_service.is_bulb_on(0)).is_false()
	
	# Independent rows
	_service.toggle_bulb(1, "bulb_1")
	assert_bool(_service.is_bulb_on(1)).is_true()
	assert_bool(_service.is_bulb_on(0)).is_false()
