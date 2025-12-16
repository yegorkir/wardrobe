extends Node

signal screen_requested(screen_id, payload)
signal run_state_changed(state_name)
signal hud_updated(snapshot)

const MagicSystemScript := preload("res://scripts/sim/magic_system.gd")
const InspectionSystemScript := preload("res://scripts/sim/inspection_system.gd")

const SCREEN_MAIN_MENU := "main_menu"
const SCREEN_WARDROBE := "wardrobe"
const SCREEN_SHIFT_SUMMARY := "shift_summary"

const RUN_STATE_MENU := "menu"
const RUN_STATE_SHIFT := "shift"
const RUN_STATE_SUMMARY := "summary"

const MAGIC_DEFAULT_CONFIG := {
	"insurance_mode": MagicSystemScript.INSURANCE_MODE_FREE,
	"emergency_cost_mode": MagicSystemScript.EMERGENCY_COST_DEBT,
	"insurance_cost": 0,
	"emergency_cost_value": 5,
	"soft_limit": 0,
	"search_effect": "REVEAL_SLOT",
}

const INSPECTION_DEFAULT_CONFIG := {
	"inspection_mode": InspectionSystemScript.MODE_PER_SHIFT,
	"inspection_interval": 3,
	"mvp_emulation": true,
	"thresholds": {},
}

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
var _magic_system := MagicSystemScript.new()
var _inspection_system := InspectionSystemScript.new()
var _run_state: Dictionary = {}

func _ready() -> void:
	_save_manager = get_node_or_null("/root/SaveManager")
	if _save_manager:
		_meta_data = _save_manager.load_meta()
	else:
		push_warning("SaveManager autoload not found; meta progress will not persist.")
		_meta_data = {}
	_magic_system.setup(MAGIC_DEFAULT_CONFIG)
	_inspection_system.setup(INSPECTION_DEFAULT_CONFIG)
	_initialize_run_state()
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
	_prepare_shift_state()
	_reset_demo_hud()
	emit_signal("run_state_changed", _current_state)
	emit_signal("screen_requested", SCREEN_WARDROBE, {})

func end_shift() -> void:
	_current_state = RUN_STATE_SUMMARY
	emit_signal("run_state_changed", _current_state)
	var inspection_report := _inspection_system.build_inspection_report(
		_run_state,
		_run_state.get("shift_index", 1)
	)
	_last_summary = {
		"money": _hud_snapshot["money"],
		"notes": ["Prototype summary placeholder"],
		"cleanliness": _run_state.get("cleanliness_or_entropy", 0.0),
		"inspector_risk": _run_state.get("inspector_risk", 0.0),
		"inspection_report": inspection_report,
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
		"debt": _run_state.get("shift_payout_debt", 0),
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

func apply_insurance_link(ticket_number: int, item_ids: Array) -> Dictionary:
	var result := _magic_system.apply_insurance(_run_state, ticket_number, item_ids)
	_log_magic_event(result)
	return result

func request_emergency_locate(ticket_number: int) -> Dictionary:
	var result := _magic_system.request_emergency_locate(_run_state, ticket_number)
	_process_emergency_cost(result)
	_log_magic_event(result)
	return result

func record_entropy(amount: float) -> void:
	_inspection_system.record_entropy(_run_state, amount)

func _initialize_run_state() -> void:
	_run_state = {
		"shift_index": 0,
		"wave_index": 0,
		"cleanliness_or_entropy": 0.0,
		"inspector_risk": 0.0,
		"magic_links": {},
		"shift_payout_debt": 0,
		"magic_config": _magic_system.get_config(),
		"inspection_config": _inspection_system.get_config(),
	}

func _prepare_shift_state() -> void:
	_run_state["shift_index"] = _run_state.get("shift_index", 0) + 1
	_run_state["wave_index"] = 1
	_run_state["cleanliness_or_entropy"] = 0.0
	_run_state["inspector_risk"] = 0.0
	_run_state["shift_payout_debt"] = 0
	var links: Dictionary = _run_state.get("magic_links", {})
	links.clear()
	_run_state["magic_links"] = links

func _process_emergency_cost(event_data: Dictionary) -> void:
	var cost_type: String = event_data.get("cost_type", "")
	var value: int = int(event_data.get("cost_value", 0))
	if cost_type == MagicSystemScript.EMERGENCY_COST_DEBT and value != 0:
		var debt: int = int(_run_state.get("shift_payout_debt", 0)) + value
		_run_state["shift_payout_debt"] = debt
		_hud_snapshot["debt"] = debt
		emit_signal("hud_updated", get_hud_snapshot())

func _log_magic_event(event_data: Dictionary) -> void:
	print("MagicSystem event:", event_data)
