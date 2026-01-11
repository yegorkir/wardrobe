class_name RunManagerBase

extends Node

const ShiftServiceScript := preload("res://scripts/app/shift/shift_service.gd")
const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")
const ShiftHudSnapshotScript := preload("res://scripts/app/shift/shift_hud_snapshot.gd")
const ShiftSummaryScript := preload("res://scripts/app/shift/shift_summary.gd")
const ShiftFailurePayloadScript := preload("res://scripts/app/shift/shift_failure_payload.gd")
const ShiftWinPayloadScript := preload("res://scripts/app/shift/shift_win_payload.gd")
const MagicEventScript := preload("res://scripts/domain/magic/magic_event.gd")

signal screen_requested(screen_id, payload)
signal run_state_changed(state_name)
signal hud_updated(snapshot)

const SCREEN_MAIN_MENU := "main_menu"
const SCREEN_WARDROBE := "wardrobe"
const SCREEN_WARDROBE_LEGACY := "wardrobe_legacy"
const SCREEN_WARDROBE_DEBUG := "wardrobe_debug"
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
	_shift_service.setup(
		_save_manager,
		null,
		null,
		{},
		_meta_data
	)
	_shift_service.hud_updated.connect(_on_shift_hud_updated)
	_shift_service.shift_started.connect(func(_snapshot) -> void:
		emit_signal("run_state_changed", RUN_STATE_SHIFT)
	)
	_shift_service.shift_ended.connect(func(_summary) -> void:
		emit_signal("run_state_changed", RUN_STATE_SUMMARY)
	)
	_shift_service.shift_failed.connect(func(_payload) -> void:
		if _current_state != RUN_STATE_SHIFT:
			return
		end_shift()
	)
	_shift_service.shift_won.connect(func(_payload) -> void:
		if _current_state != RUN_STATE_SHIFT:
			return
		end_shift()
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
	var summary: RefCounted = _shift_service.end_shift()
	emit_signal("screen_requested", SCREEN_SHIFT_SUMMARY, summary)

func get_hud_snapshot() -> RefCounted:
	return _shift_service.get_hud_snapshot()

func simulate_tick_for_demo() -> void:
	_shift_service.simulate_tick_for_demo()

func _reset_demo_hud() -> void:
	_shift_service.reset_demo_hud()

func adjust_demo_money(amount: int) -> void:
	_shift_service.adjust_demo_money(amount)

func record_demo_magic(value: int) -> void:
	_shift_service.record_demo_magic(value)

func get_last_summary() -> RefCounted:
	return _shift_service.get_last_summary()

func apply_insurance_link(ticket_number: int, item_ids: Array[StringName]) -> RefCounted:
	return _shift_service.apply_insurance_link(ticket_number, item_ids)

func request_emergency_locate(ticket_number: int) -> RefCounted:
	return _shift_service.request_emergency_locate(ticket_number)

func record_entropy(amount: float) -> void:
	_shift_service.record_entropy(amount)

func record_item_landed(payload: Dictionary) -> RefCounted:
	return _shift_service.record_item_landed(payload)

func get_shift_log() -> WardrobeShiftLog:
	return _shift_service.get_shift_log()

func configure_patience_clients(client_ids: Array) -> Dictionary:
	if _shift_service:
		return _shift_service.configure_patience_clients(client_ids)
	return {
		"patience_by_client_id": {},
		"patience_max_by_client_id": {},
	}

func configure_shift_clients(total_clients: int) -> void:
	if _shift_service:
		_shift_service.configure_shift_clients(total_clients)

func configure_shift_targets(target_checkin: int, target_checkout: int) -> void:
	if _shift_service:
		_shift_service.configure_shift_targets(target_checkin, target_checkout)

func register_checkin_completed() -> void:
	if _shift_service:
		_shift_service.register_checkin_completed()

func register_checkout_completed() -> void:
	if _shift_service:
		_shift_service.register_checkout_completed()

func update_active_client_count(active_clients: int) -> void:
	if _shift_service:
		_shift_service.update_active_client_count(active_clients)

func get_patience_snapshot() -> Dictionary:
	if _shift_service:
		return _shift_service.get_patience_snapshot()
	return {
		"patience_by_client_id": {},
		"patience_max_by_client_id": {},
	}

func tick_patience(active_client_ids: Array, delta: float) -> Dictionary:
	if _shift_service:
		return _shift_service.tick_patience(active_client_ids, delta)
	return {}

func apply_patience_penalty(client_id: StringName, amount: float, reason_code: StringName) -> Dictionary:
	if _shift_service:
		return _shift_service.apply_patience_penalty(client_id, amount, reason_code)
	return {}

func get_queue_mix_snapshot() -> Dictionary:
	if _shift_service:
		return _shift_service.get_queue_mix_snapshot()
	return {}

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

func _on_shift_hud_updated(snapshot) -> void:
	emit_signal("hud_updated", snapshot)
