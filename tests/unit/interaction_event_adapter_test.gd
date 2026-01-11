extends GdUnitTestSuite

const Adapter := preload("res://scripts/wardrobe/interaction_event_adapter.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const InteractionEventScript := preload("res://scripts/domain/interaction/interaction_event.gd")

var _picked: Array = []
var _placed: Array = []
var _rejected: Array = []

func test_emit_events_routes_signals() -> void:
	var adapter := Adapter.new()
	_picked = []
	_placed = []
	_rejected = []
	adapter.item_picked.connect(_on_item_picked)
	adapter.item_placed.connect(_on_item_placed)
	adapter.action_rejected.connect(_on_action_rejected)

	var events := [
		InteractionEventScript.new(EventSchema.EVENT_ITEM_PICKED, {
			EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_A"),
			EventSchema.PAYLOAD_ITEM: {"id": StringName("coat_1")},
			EventSchema.PAYLOAD_TICK: 1,
		}),
		InteractionEventScript.new(EventSchema.EVENT_ITEM_PLACED, {
			EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_B"),
			EventSchema.PAYLOAD_ITEM: {"id": StringName("coat_2")},
			EventSchema.PAYLOAD_TICK: 2,
		}),
		InteractionEventScript.new(EventSchema.EVENT_ACTION_REJECTED, {
			EventSchema.PAYLOAD_SLOT_ID: StringName("Slot_D"),
			EventSchema.PAYLOAD_REASON: StringName("slot_missing"),
			EventSchema.PAYLOAD_TICK: 3,
		}),
	]

	adapter.emit_events(events)

	assert_int(_picked.size()).is_equal(1)
	assert_that(_picked[0][0]).is_equal(StringName("Slot_A"))
	assert_that((_picked[0][1] as Dictionary).get("id")).is_equal(StringName("coat_1"))

	assert_int(_placed.size()).is_equal(1)
	assert_that(_placed[0][0]).is_equal(StringName("Slot_B"))
	assert_that((_placed[0][1] as Dictionary).get("id")).is_equal(StringName("coat_2"))

	assert_int(_rejected.size()).is_equal(1)
	assert_that(_rejected[0][0]).is_equal(StringName("Slot_D"))
	assert_that(_rejected[0][1]).is_equal(StringName("slot_missing"))

func _on_item_picked(slot_id: StringName, item: Dictionary, tick: int) -> void:
	_picked.append([slot_id, item, tick])

func _on_item_placed(slot_id: StringName, item: Dictionary, tick: int) -> void:
	_placed.append([slot_id, item, tick])

func _on_action_rejected(slot_id: StringName, reason: StringName, tick: int) -> void:
	_rejected.append([slot_id, reason, tick])
