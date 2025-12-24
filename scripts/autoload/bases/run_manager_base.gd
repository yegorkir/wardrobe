class_name RunManagerBase

extends Node

signal screen_requested(screen_id, payload)
signal run_state_changed(state_name)
signal hud_updated(snapshot)

const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")

const SCREEN_MAIN_MENU := "main_menu"
const SCREEN_WARDROBE := "wardrobe"
const SCREEN_WARDROBE_LEGACY := "wardrobe_legacy"
const SCREEN_SHIFT_SUMMARY := "shift_summary"

const RUN_STATE_MENU := "menu"
const RUN_STATE_SHIFT := "shift"
const RUN_STATE_SUMMARY := "summary"

var _current_state := RUN_STATE_MENU
var _meta_data: Dictionary = {}
var _save_manager
var _shift_service

func _ready() -> void:
	_save_manager = get_node_or_null("/root/SaveManager") as SaveManagerBase
	if _save_manager:
		_meta_data = _save_manager.load_meta()
	else:
		push_warning("SaveManager autoload not found; meta progress will not persist.")
		_meta_data = {}
	_shift_service = ShiftServiceScript.new()
	_shift_service.setup(_save_manager, ShiftService.MAGIC_DEFAULT_CONFIG, ShiftService.INSPECTION_DEFAULT_CONFIG, _meta_data)
	_shift_service.hud_updated.connect(_on_shift_hud_updated)
	_shift_service.shift_started.connect(func(_snapshot: Dictionary) -> void:
		emit_signal("run_state_changed", RUN_STATE_SHIFT)
	)
	_shift_service.shift_ended.connect(func(_summary: Dictionary) -> void:
		emit_signal("run_state_changed", RUN_STATE_SUMMARY)
	)
	_on_shift_hud_updated(_shift_service.get_hud_snapshot())
	_configure_input_map()
	call_deferred("go_to_menu")

func go_to_menu() -> void:
	_current_state = RUN_STATE_MENU
	emit_signal("run_state_changed", _current_state)
	emit_signal("screen_requested", SCREEN_MAIN_MENU, {})

func start_run() -> void:
	start_shift()

func start_shift() -> void:
	start_shift_with_screen(SCREEN_WARDROBE)

func start_shift_with_screen(screen_id: StringName) -> void:
	_current_state = RUN_STATE_SHIFT
	_shift_service.start_shift()
	emit_signal("screen_requested", screen_id, {})

func end_shift() -> void:
	_current_state = RUN_STATE_SUMMARY
	var summary: Dictionary = _shift_service.end_shift()
	emit_signal("screen_requested", SCREEN_SHIFT_SUMMARY, summary)

func get_hud_snapshot() -> Dictionary:
	return _shift_service.get_hud_snapshot()

func simulate_tick_for_demo() -> void:
	_shift_service.simulate_tick_for_demo()

func _reset_demo_hud() -> void:
	_shift_service.reset_demo_hud()

func adjust_demo_money(amount: int) -> void:
	_shift_service.adjust_demo_money(amount)

func record_demo_magic(value: int) -> void:
	_shift_service.record_demo_magic(value)

func get_last_summary() -> Dictionary:
	return _shift_service.get_last_summary()

func apply_insurance_link(ticket_number: int, item_ids: Array) -> Dictionary:
	return _shift_service.apply_insurance_link(ticket_number, item_ids)

func request_emergency_locate(ticket_number: int) -> Dictionary:
	return _shift_service.request_emergency_locate(ticket_number)

func record_entropy(amount: float) -> void:
	_shift_service.record_entropy(amount)

func _configure_input_map() -> void:
	_ensure_action_with_events("tap", _create_tap_events())
	_ensure_action_with_events("cancel", [_create_key_event(KEY_ESCAPE)])
	_ensure_action_with_events("debug_toggle", [_create_key_event(KEY_F1)])
	_ensure_action_with_events(
		"move_left",
		[_create_key_event(KEY_A), _create_key_event(KEY_LEFT)]
	)
	_ensure_action_with_events(
		"move_right",
		[_create_key_event(KEY_D), _create_key_event(KEY_RIGHT)]
	)
	_ensure_action_with_events(
		"move_up",
		[_create_key_event(KEY_W), _create_key_event(KEY_UP)]
	)
	_ensure_action_with_events(
		"move_down",
		[_create_key_event(KEY_S), _create_key_event(KEY_DOWN)]
	)
	_ensure_action_with_events("interact", [_create_key_event(KEY_E)])
	_ensure_action_with_events("debug_reset", [_create_key_event(KEY_R)])

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

func _on_shift_hud_updated(snapshot: Dictionary) -> void:
	emit_signal("hud_updated", snapshot)
