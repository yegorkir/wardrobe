extends RefCounted

class_name ShiftService

signal hud_updated(snapshot: Dictionary)
signal shift_started(snapshot: Dictionary)
signal shift_ended(summary: Dictionary)

const MagicSystemScript := preload("res://scripts/domain/magic/magic_system.gd")
const InspectionSystemScript := preload("res://scripts/domain/inspection/inspection_system.gd")

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

var _save_manager
var _magic_system := MagicSystemScript.new()
var _inspection_system := InspectionSystemScript.new()
var _run_state: Dictionary = {}
var _hud_snapshot: Dictionary = {}
var _last_summary: Dictionary = {}
var _meta_data: Dictionary = {}

func setup(
	save_manager,
	magic_config: Dictionary = MAGIC_DEFAULT_CONFIG,
	inspection_config: Dictionary = INSPECTION_DEFAULT_CONFIG,
	meta_data: Dictionary = {}
) -> void:
	_save_manager = save_manager
	_meta_data = meta_data.duplicate(true)
	_magic_system.setup(magic_config)
	_inspection_system.setup(inspection_config)
	_initialize_run_state()
	_reset_demo_hud()

func start_shift() -> Dictionary:
	_prepare_shift_state()
	_reset_demo_hud()
	emit_signal("shift_started", get_hud_snapshot())
	return get_hud_snapshot()

func end_shift() -> Dictionary:
	var inspection_report := _inspection_system.build_inspection_report(
		_run_state,
		_run_state.get("shift_index", 1)
	)
	_last_summary = {
		"money": _hud_snapshot.get("money", 0),
		"notes": ["Prototype summary placeholder"],
		"cleanliness": _run_state.get("cleanliness_or_entropy", 0.0),
		"inspector_risk": _run_state.get("inspector_risk", 0.0),
		"inspection_report": inspection_report,
	}
	_meta_data["total_currency"] = _meta_data.get("total_currency", 0) + int(_hud_snapshot.get("money", 0))
	if _save_manager:
		_save_manager.save_meta(_meta_data)
	emit_signal("shift_ended", _last_summary.duplicate(true))
	return _last_summary.duplicate(true)

func get_hud_snapshot() -> Dictionary:
	return _hud_snapshot.duplicate(true)

func reset_demo_hud() -> void:
	_reset_demo_hud()

func get_last_summary() -> Dictionary:
	return _last_summary.duplicate(true)

func simulate_tick_for_demo() -> void:
	_hud_snapshot["time"] = max(0, _hud_snapshot.get("time", 0) - 1)
	emit_signal("hud_updated", get_hud_snapshot())

func adjust_demo_money(amount: int) -> void:
	_hud_snapshot["money"] = int(_hud_snapshot.get("money", 0)) + amount
	emit_signal("hud_updated", get_hud_snapshot())

func record_demo_magic(value: int) -> void:
	_hud_snapshot["magic"] = value
	emit_signal("hud_updated", get_hud_snapshot())

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

func _reset_demo_hud() -> void:
	_hud_snapshot = {
		"wave": 1,
		"time": 180,
		"money": 42,
		"magic": 3,
		"debt": _run_state.get("shift_payout_debt", 0),
	}
	emit_signal("hud_updated", get_hud_snapshot())

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
