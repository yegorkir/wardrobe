extends GdUnitTestSuite

const Adapter := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const EventSchema := preload("res://scripts/domain/interaction/interaction_event_schema.gd")

var _picked: Array = []
var _placed: Array = []
var _swapped: Array = []
var _rejected: Array = []

func test_emit_events_routes_signals() -> void:
	var adapter := Adapter.new()
	_picked = []
	_placed = []
	_swapped = []
	_rejected = []
	adapter.item_picked.connect(_on_item_picked)
	adapter.item_placed.connect(_on_item_placed)
	adapter.item_swapped.connect(_on_item_swapped)
	adapter.action_rejected.connect(_on_action_rejected)

	var events := [
		{
			EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ITEM_PICKED,
			EventSchema.EVENT_KEY_PAYLOAD: {
				EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_A"),
				EventSchema.PAYLOAD_ITEM: {"id": StringName("coat_1")},
				EventSchema.PAYLOAD_TICK: 1,
			},
		},
		{
			EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ITEM_PLACED,
			EventSchema.EVENT_KEY_PAYLOAD: {
				EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_B"),
				EventSchema.PAYLOAD_ITEM: {"id": StringName("coat_2")},
				EventSchema.PAYLOAD_TICK: 2,
			},
		},
		{
			EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ITEM_SWAPPED,
			EventSchema.EVENT_KEY_PAYLOAD: {
				EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_C"),
				EventSchema.PAYLOAD_INCOMING_ITEM: {"id": StringName("coat_hand")},
				EventSchema.PAYLOAD_OUTGOING_ITEM: {"id": StringName("coat_slot")},
				EventSchema.PAYLOAD_TICK: 3,
			},
		},
		{
			EventSchema.EVENT_KEY_TYPE: EventSchema.EVENT_ACTION_REJECTED,
			EventSchema.EVENT_KEY_PAYLOAD: {
				EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_D"),
				EventSchema.PAYLOAD_REASON: StringName("slot_missing"),
				EventSchema.PAYLOAD_TICK: 4,
			},
		},
	]

	adapter.emit_events(events)

	assert_int(_picked.size()).is_equal(1)
	assert_that(_picked[0][0]).is_equal(StringName("Slot_A"))
	assert_that((_picked[0][1] as Dictionary).get("id")).is_equal(StringName("coat_1"))

	assert_int(_placed.size()).is_equal(1)
	assert_that(_placed[0][0]).is_equal(StringName("Slot_B"))
	assert_that((_placed[0][1] as Dictionary).get("id")).is_equal(StringName("coat_2"))

	assert_int(_swapped.size()).is_equal(1)
	assert_that(_swapped[0][0]).is_equal(StringName("Slot_C"))
	assert_that((_swapped[0][1] as Dictionary).get("id")).is_equal(StringName("coat_hand"))
	assert_that((_swapped[0][2] as Dictionary).get("id")).is_equal(StringName("coat_slot"))

	assert_int(_rejected.size()).is_equal(1)
	assert_that(_rejected[0][0]).is_equal(StringName("Slot_D"))
	assert_that(_rejected[0][1]).is_equal(StringName("slot_missing"))

func _on_item_picked(slot_id: StringName, item: Dictionary, tick: int) -> void:
	_picked.append([slot_id, item, tick])

func _on_item_placed(slot_id: StringName, item: Dictionary, tick: int) -> void:
	_placed.append([slot_id, item, tick])

func _on_item_swapped(slot_id: StringName, incoming_item: Dictionary, outgoing_item: Dictionary, tick: int) -> void:
	_swapped.append([slot_id, incoming_item, outgoing_item, tick])

func _on_action_rejected(slot_id: StringName, reason: StringName, tick: int) -> void:
	_rejected.append([slot_id, reason, tick])
