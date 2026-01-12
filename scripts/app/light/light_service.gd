class_name LightService
extends RefCounted

signal curtain_changed(ratio: float)
signal bulb_changed(row_index: int, is_on: bool)

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")

# Maps row_index (int) -> is_on (bool)
var _bulb_states: Dictionary = {}
var _curtain_open_ratio: float = 0.0
var _log_callback: Callable

func _init(log_callback: Callable = Callable()) -> void:
	_log_callback = log_callback

func set_curtain_open_ratio(ratio: float, source_id: StringName) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(_curtain_open_ratio, clamped):
		return
	
	_curtain_open_ratio = clamped
	curtain_changed.emit(_curtain_open_ratio)
	
	var payload := {
		EventSchema.PAYLOAD_SOURCE_ID: source_id,
		EventSchema.PAYLOAD_OPEN_RATIO: _curtain_open_ratio
	}
	_emit_log(EventSchema.EVENT_LIGHT_ADJUSTED, payload)
	DebugLog.event(EventSchema.EVENT_LIGHT_ADJUSTED, payload)

func toggle_bulb(row_index: int, source_id: StringName) -> void:
	var was_on: bool = _bulb_states.get(row_index, false)
	var new_state := not was_on
	_bulb_states[row_index] = new_state
	bulb_changed.emit(row_index, new_state)
	
	var payload := {
		EventSchema.PAYLOAD_SOURCE_ID: source_id,
		EventSchema.PAYLOAD_IS_ON: new_state,
		EventSchema.PAYLOAD_ROW_INDEX: row_index
	}
	_emit_log(EventSchema.EVENT_LIGHT_TOGGLED, payload)
	DebugLog.event(EventSchema.EVENT_LIGHT_TOGGLED, payload)

func get_curtain_open_ratio() -> float:
	return _curtain_open_ratio

func is_bulb_on(row_index: int) -> bool:
	return _bulb_states.get(row_index, false)

func _emit_log(event_type: StringName, payload: Dictionary) -> void:
	if _log_callback.is_valid():
		_log_callback.call(event_type, payload)
