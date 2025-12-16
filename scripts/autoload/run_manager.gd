extends Node

signal screen_requested(screen_id, payload)
signal run_state_changed(state_name)
signal hud_updated(snapshot)

const SCREEN_MAIN_MENU := "main_menu"
const SCREEN_WARDROBE := "wardrobe"
const SCREEN_SHIFT_SUMMARY := "shift_summary"

const RUN_STATE_MENU := "menu"
const RUN_STATE_SHIFT := "shift"
const RUN_STATE_SUMMARY := "summary"

var _current_state := RUN_STATE_MENU
var _hud_snapshot := {
	"wave": 1,
	"time": 180,
	"money": 0,
	"magic": 3,
	"debt": 0,
}
var _last_summary := {}
var _meta_data: Dictionary = {}
var _save_manager: SaveManager

func _ready() -> void:
	_save_manager = get_node_or_null("/root/SaveManager")
	if _save_manager:
		_meta_data = _save_manager.load_meta()
	else:
		push_warning("SaveManager autoload not found; meta progress will not persist.")
		_meta_data = {}
	_configure_input_map()
	call_deferred("go_to_menu")

func _configure_input_map() -> void:
	_ensure_action_with_events("tap", _create_tap_events())
	_ensure_action_with_events("cancel", [_create_key_event(KEY_ESCAPE)])
	_ensure_action_with_events("debug_toggle", [_create_key_event(KEY_F1)])

func _create_tap_events() -> Array:
	var events: Array = []
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = MouseButton.MOUSE_BUTTON_LEFT
	events.append(mouse_event)

	var touch_event := InputEventScreenTouch.new()
	touch_event.index = 0
	events.append(touch_event)
	return events

func _create_key_event(key_code: Key) -> InputEventKey:
	var key_event := InputEventKey.new()
	key_event.keycode = key_code
	key_event.physical_keycode = key_code
	return key_event

func _ensure_action_with_events(action_name: StringName, events: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in events:
		if not _action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)

func _action_has_event(action_name: StringName, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action_name):
		if existing.is_action(action_name) and existing.is_match(event, true):
			return true
	return false

func go_to_menu() -> void:
	_current_state = RUN_STATE_MENU
	emit_signal("run_state_changed", _current_state)
	emit_signal("screen_requested", SCREEN_MAIN_MENU, {})

func start_run() -> void:
	start_shift()

func start_shift() -> void:
	_current_state = RUN_STATE_SHIFT
	_reset_demo_hud()
	emit_signal("run_state_changed", _current_state)
	emit_signal("screen_requested", SCREEN_WARDROBE, {})

func end_shift() -> void:
	_current_state = RUN_STATE_SUMMARY
	emit_signal("run_state_changed", _current_state)
	_last_summary = {
		"money": _hud_snapshot["money"],
		"notes": ["Prototype summary placeholder"]
	}
	_meta_data["total_currency"] = _meta_data.get("total_currency", 0) + int(_hud_snapshot["money"])
	if _save_manager:
		_save_manager.save_meta(_meta_data)
	emit_signal("screen_requested", SCREEN_SHIFT_SUMMARY, _last_summary)

func get_hud_snapshot() -> Dictionary:
	return _hud_snapshot.duplicate(true)

func simulate_tick_for_demo() -> void:
	_hud_snapshot["time"] = max(0, _hud_snapshot["time"] - 1)
	emit_signal("hud_updated", get_hud_snapshot())

func _reset_demo_hud() -> void:
	_hud_snapshot = {
		"wave": 1,
		"time": 180,
		"money": 42,
		"magic": 3,
		"debt": 0,
	}
	emit_signal("hud_updated", get_hud_snapshot())

func adjust_demo_money(amount: int) -> void:
	_hud_snapshot["money"] += amount
	emit_signal("hud_updated", get_hud_snapshot())

func record_demo_magic(value: int) -> void:
	_hud_snapshot["magic"] = value
	emit_signal("hud_updated", get_hud_snapshot())

func get_last_summary() -> Dictionary:
	return _last_summary.duplicate(true)
