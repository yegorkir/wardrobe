extends RefCounted

class_name MagicEvent

const TYPE_INSURANCE_LINK := StringName("insurance_link")
const TYPE_EMERGENCY_LOCATE := StringName("emergency_locate")

var event_type: StringName
var ticket_number: int
var items: Array[StringName]
var mode: StringName
var cost_type: StringName
var cost_value: int
var highlight: Variant

func _init(
	event_type_value: StringName,
	ticket_number_value: int,
	items_value: Array[StringName],
	mode_value: StringName,
	cost_type_value: StringName,
	cost_value_value: int,
	highlight_value: Variant
) -> void:
	event_type = event_type_value
	ticket_number = ticket_number_value
	items = items_value.duplicate(true)
	mode = mode_value
	cost_type = cost_type_value
	cost_value = cost_value_value
	highlight = highlight_value

func duplicate_event() -> MagicEvent:
	return get_script().new(
		event_type,
		ticket_number,
		items,
		mode,
		cost_type,
		cost_value,
		highlight
	) as MagicEvent
