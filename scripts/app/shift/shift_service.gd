extends RefCounted

class_name ShiftService

const MagicSystemScript := preload("res://scripts/domain/magic/magic_system.gd")
const MagicConfigScript := preload("res://scripts/domain/magic/magic_config.gd")
const MagicEventScript := preload("res://scripts/domain/magic/magic_event.gd")
const InspectionSystemScript := preload("res://scripts/domain/inspection/inspection_system.gd")
const InspectionConfigScript := preload("res://scripts/domain/inspection/inspection_config.gd")
const InspectionReportScript := preload("res://scripts/domain/inspection/inspection_report.gd")
const LandingServiceScript := preload("res://scripts/app/wardrobe/landing/landing_service.gd")
const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")
const ItemQualityServiceScript := preload("res://scripts/domain/quality/item_quality_service.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const ShiftLogScript := preload("res://scripts/app/logging/shift_log.gd")
const ShiftHudSnapshotScript := preload("res://scripts/app/shift/shift_hud_snapshot.gd")
const ShiftSummaryScript := preload("res://scripts/app/shift/shift_summary.gd")
const ShiftFailurePayloadScript := preload("res://scripts/app/shift/shift_failure_payload.gd")
const ShiftWinPayloadScript := preload("res://scripts/app/shift/shift_win_payload.gd")
const ShiftWinResultScript := preload("res://scripts/app/shift/shift_win_result.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ShiftPatienceStateScript := preload("res://scripts/domain/shift/shift_patience_state.gd")
const ShiftPatienceSystemScript := preload("res://scripts/app/shift/shift_patience_system.gd")
const ShiftWinPolicyScript := preload("res://scripts/app/shift/shift_win_policy.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

signal hud_updated(snapshot)
signal shift_started(snapshot)
signal shift_ended(summary)
signal shift_failed(payload)
signal shift_won(payload)
const SHIFT_DEFAULT_CONFIG := {
	"strikes_limit": 3,
	"patience_max": 30.0,
}
const FALL_IMPACT_TO_DAMAGE_DIVISOR := 100.0

var _save_manager
var _magic_system := MagicSystemScript.new()
var _inspection_system := InspectionSystemScript.new()
var _landing_service := LandingServiceScript.new()
var _shift_log: WardrobeShiftLog = ShiftLogScript.new()
var _run_state: RunState
var _patience_state: ShiftPatienceState = ShiftPatienceStateScript.new()
var _patience_system: ShiftPatienceSystem = ShiftPatienceSystemScript.new()
var _win_policy = ShiftWinPolicyScript.new()
var _hud_snapshot: RefCounted
var _last_summary: RefCounted
var _meta_data: Dictionary = {}
var _shift_config: Dictionary = SHIFT_DEFAULT_CONFIG.duplicate(true)

func setup(
	save_manager,
	magic_config: RefCounted = null,
	inspection_config: RefCounted = null,
	shift_config: Dictionary = {},
	meta_data: Dictionary = {}
) -> void:
	_save_manager = save_manager
	_meta_data = meta_data.duplicate(true)
	if shift_config.is_empty():
		_shift_config = SHIFT_DEFAULT_CONFIG.duplicate(true)
	else:
		_shift_config = shift_config.duplicate(true)
	var resolved_magic: RefCounted = magic_config if magic_config else build_default_magic_config()
	var resolved_inspection: RefCounted = inspection_config if inspection_config else build_default_inspection_config()
	_magic_system.setup(resolved_magic)
	_inspection_system.setup(resolved_inspection)
	_initialize_run_state()
	_reset_demo_hud()

static func build_default_magic_config() -> RefCounted:
	return MagicConfigScript.new(
		MagicSystemScript.INSURANCE_MODE_FREE,
		MagicSystemScript.EMERGENCY_COST_DEBT,
		0,
		5,
		0,
		MagicSystemScript.SEARCH_EFFECT_REVEAL_SLOT
	)

static func build_default_inspection_config() -> RefCounted:
	return InspectionConfigScript.new(
		InspectionSystemScript.MODE_PER_SHIFT,
		3,
		true,
		{}
	)

func start_shift() -> RefCounted:
	_shift_log.clear()
	_prepare_shift_state()
	_reset_patience_state()
	_reset_demo_hud()
	emit_signal("shift_started", get_hud_snapshot())
	return get_hud_snapshot()

func end_shift() -> RefCounted:
	if _run_state and _run_state.shift_status == RunState.SHIFT_STATUS_RUNNING:
		_run_state.shift_status = RunState.SHIFT_STATUS_SUCCESS
	var inspection_report: RefCounted = _inspection_system.build_inspection_report(
		_run_state,
		_run_state.shift_index if _run_state else 1
	)
	_last_summary = ShiftSummaryScript.new(
		_hud_snapshot.money if _hud_snapshot else 0,
		["Prototype summary placeholder"],
		_run_state.cleanliness_or_entropy if _run_state else 0.0,
		_run_state.inspector_risk if _run_state else 0.0,
		_run_state.shift_status if _run_state else RunState.SHIFT_STATUS_SUCCESS,
		_patience_state.strikes_current,
		_patience_state.strikes_limit,
		inspection_report,
		_collect_end_reasons()
	)
	_meta_data["total_currency"] = _meta_data.get("total_currency", 0) + (_hud_snapshot.money if _hud_snapshot else 0)
	if _save_manager:
		_save_manager.save_meta(_meta_data)
	emit_signal("shift_ended", _last_summary.duplicate_summary())
	return _last_summary.duplicate_summary()

func get_hud_snapshot() -> RefCounted:
	return _hud_snapshot.duplicate_snapshot() if _hud_snapshot else null

func get_patience_snapshot() -> Dictionary:
	return _patience_state.get_patience_snapshot()

func get_queue_mix_snapshot() -> Dictionary:
	if _run_state == null:
		return {}
	var total_targets: int = max(1, _run_state.target_checkin + _run_state.target_checkout)
	var progress: float = float(_run_state.checkin_done + _run_state.checkout_done) / float(total_targets)
	return {
		"checkin_done": _run_state.checkin_done,
		"checkout_done": _run_state.checkout_done,
		"target_checkin": _run_state.target_checkin,
		"target_checkout": _run_state.target_checkout,
		"need_in": _run_state.get_need_checkin(),
		"need_out": _run_state.get_need_checkout(),
		"outstanding": _run_state.get_outstanding_checkout(),
		"progress": clamp(progress, 0.0, 1.0),
	}

func reset_demo_hud() -> void:
	_reset_demo_hud()

func get_last_summary() -> RefCounted:
	return _last_summary.duplicate_summary() if _last_summary else null

func simulate_tick_for_demo() -> void:
	if _hud_snapshot == null:
		return
	_hud_snapshot.time = max(0, _hud_snapshot.time - 1)
	emit_signal("hud_updated", get_hud_snapshot())

func adjust_demo_money(amount: int) -> void:
	if _hud_snapshot == null:
		return
	_hud_snapshot.money = _hud_snapshot.money + amount
	emit_signal("hud_updated", get_hud_snapshot())

func record_demo_magic(value: int) -> void:
	if _hud_snapshot == null:
		return
	_hud_snapshot.magic = value
	emit_signal("hud_updated", get_hud_snapshot())

func apply_insurance_link(ticket_number: int, item_ids: Array[StringName]) -> RefCounted:
	var result := _magic_system.apply_insurance(_run_state, ticket_number, item_ids)
	_log_magic_event(result)
	return result

func request_emergency_locate(ticket_number: int) -> RefCounted:
	var result := _magic_system.request_emergency_locate(_run_state, ticket_number)
	_process_emergency_cost(result)
	_log_magic_event(result)
	return result

func record_entropy(amount: float) -> void:
	_inspection_system.record_entropy(_run_state, amount)

func register_item(item: ItemInstanceScript) -> void:
	if _run_state == null:
		return
	_run_state.register_item(item)

func find_item(item_id: StringName) -> ItemInstanceScript:
	if _run_state == null:
		return null
	return _run_state.find_item(item_id)

func record_item_landed(payload: Dictionary) -> RefCounted:
	_shift_log.record(EventSchema.EVENT_ITEM_LANDED, payload)
	
	var outcome := _landing_service.record_item_landed(payload)
	
	# Apply quality damage if item exists in domain
	if _run_state:
		var item_id: StringName = payload.get(EventSchema.PAYLOAD_ITEM_ID, StringName())
		var impact: float = float(payload.get(EventSchema.PAYLOAD_IMPACT, 0.0))
		var damage_amount := impact / FALL_IMPACT_TO_DAMAGE_DIVISOR
		var instance := _run_state.find_item(item_id)
		if instance and instance.quality_state:
			var result := ItemQualityServiceScript.apply_damage(
				instance.quality_state,
				StringName("Fall"),
				damage_amount
			)
			if result and result.delta != 0:
				outcome.quality_delta = result.delta
				if DebugLog.enabled():
					DebugLog.logf("ITEM_QUALITY_CHANGED item=%s delta=%.1f old=%.1f new=%.1f source=%s", [
						item_id, result.delta, result.old_stars, result.new_stars, result.source
					])
				_shift_log.record(EventSchema.EVENT_ITEM_QUALITY_CHANGED, {
					EventSchema.PAYLOAD_ITEM_ID: item_id,
					EventSchema.PAYLOAD_OLD_VALUE: result.old_stars,
					EventSchema.PAYLOAD_NEW_VALUE: result.new_stars,
					EventSchema.PAYLOAD_SOURCE: result.source,
				})
				
	return outcome

func get_shift_log() -> WardrobeShiftLog:
	return _shift_log

func configure_patience_clients(client_ids: Array) -> Dictionary:
	var patience_max := float(_shift_config.get("patience_max", 30.0))
	var strikes_limit := int(_shift_config.get("strikes_limit", 3))
	_patience_system.reset_for_shift(_patience_state, client_ids, patience_max, strikes_limit)
	_update_strikes_hud()
	return _patience_state.get_patience_snapshot()

func configure_shift_clients(total_clients: int) -> void:
	if _run_state == null:
		return
	_run_state.total_clients = max(0, total_clients)
	_run_state.served_clients = 0
	_run_state.active_clients = 0
	_try_finish_shift_success()

func configure_shift_targets(target_checkin: int, target_checkout: int) -> void:
	if _run_state == null:
		return
	_run_state.configure_shift_targets(target_checkin, target_checkout)
	_try_finish_shift_success()

func register_checkin_completed(client_id: StringName) -> void:
	if _run_state == null:
		return
	_run_state.register_checkin_completed(client_id)
	_try_finish_shift_success()

func register_checkout_completed(client_id: StringName) -> void:
	if _run_state == null:
		return
	_run_state.register_checkout_completed(client_id)
	_try_finish_shift_success()

func update_active_client_count(active_clients: int) -> void:
	if _run_state == null:
		return
	_run_state.active_clients = max(0, active_clients)

func tick_patience(active_client_ids: Array, delta: float) -> Dictionary:
	var result: Dictionary = _patience_system.tick_patience(_patience_state, active_client_ids, delta)
	var strike_clients: Array = result.get("strike_client_ids", [])
	if strike_clients.is_empty():
		return result
	_record_patience_zero_events(strike_clients)
	return result

func apply_patience_penalty(client_id: StringName, amount: float, reason_code: StringName) -> Dictionary:
	var result: Dictionary = _patience_system.apply_penalty(_patience_state, client_id, amount)
	if amount > 0.0:
		_shift_log.record(EventSchema.EVENT_CLIENT_PATIENCE_PENALIZED, {
			EventSchema.PAYLOAD_CLIENT_ID: client_id,
			EventSchema.PAYLOAD_REASON_CODE: reason_code,
			EventSchema.PAYLOAD_AMOUNT: amount,
			EventSchema.PAYLOAD_STRIKES_CURRENT: _patience_state.strikes_current,
			EventSchema.PAYLOAD_STRIKES_LIMIT: _patience_state.strikes_limit,
		})
	var strike_clients: Array = result.get("strike_client_ids", [])
	if not strike_clients.is_empty():
		_record_patience_zero_events(strike_clients)
	return result

func _initialize_run_state() -> void:
	_run_state = RunState.new()
	_run_state.magic_config = _magic_system.get_config()
	_run_state.inspection_config = _inspection_system.get_config()

func _prepare_shift_state() -> void:
	if _run_state == null:
		_initialize_run_state()
	_run_state.reset_for_shift()

func _reset_demo_hud() -> void:
	_hud_snapshot = ShiftHudSnapshotScript.new(
		1,
		180,
		42,
		3,
		_run_state.shift_payout_debt if _run_state else 0,
		_patience_state.strikes_current,
		_patience_state.strikes_limit
	)
	emit_signal("hud_updated", get_hud_snapshot())

func _process_emergency_cost(event_data: RefCounted) -> void:
	if event_data == null:
		return
	var cost_type: StringName = event_data.cost_type
	var value: int = event_data.cost_value
	if cost_type == MagicSystemScript.EMERGENCY_COST_DEBT and value != 0:
		var debt: int = _run_state.shift_payout_debt + value
		_run_state.shift_payout_debt = debt
		if _hud_snapshot:
			_hud_snapshot.debt = debt
		emit_signal("hud_updated", get_hud_snapshot())

func _log_magic_event(event_data: RefCounted) -> void:
	print("MagicSystem event:", event_data)

func _reset_patience_state() -> void:
	var patience_max := float(_shift_config.get("patience_max", 30.0))
	var strikes_limit := int(_shift_config.get("strikes_limit", 3))
	_patience_state.reset([], patience_max, strikes_limit)

func _update_strikes_hud() -> void:
	if _hud_snapshot == null:
		return
	_hud_snapshot.strikes_current = _patience_state.strikes_current
	_hud_snapshot.strikes_limit = _patience_state.strikes_limit
	emit_signal("hud_updated", get_hud_snapshot())

func _record_patience_zero_events(strike_clients: Array) -> void:
	for client_id in strike_clients:
		_shift_log.record(EventSchema.EVENT_CLIENT_PATIENCE_ZERO, {
			EventSchema.PAYLOAD_CLIENT_ID: client_id,
			EventSchema.PAYLOAD_STRIKES_CURRENT: _patience_state.strikes_current,
			EventSchema.PAYLOAD_STRIKES_LIMIT: _patience_state.strikes_limit,
		})
	_update_strikes_hud()
	_apply_strike_failure_if_needed()

func _apply_strike_failure_if_needed() -> void:
	if _run_state == null:
		return
	if _run_state.shift_status == RunState.SHIFT_STATUS_FAILED:
		return
	if _patience_state.strikes_limit <= 0:
		return
	if _patience_state.strikes_current < _patience_state.strikes_limit:
		return
	_run_state.shift_status = RunState.SHIFT_STATUS_FAILED
	_shift_log.record(EventSchema.EVENT_SHIFT_FAILED, {
		EventSchema.PAYLOAD_STRIKES_CURRENT: _patience_state.strikes_current,
		EventSchema.PAYLOAD_STRIKES_LIMIT: _patience_state.strikes_limit,
	})
	emit_signal(
		"shift_failed",
		ShiftFailurePayloadScript.new(
			StringName("strikes"),
			_patience_state.strikes_current,
			_patience_state.strikes_limit
		)
	)

func _try_finish_shift_success() -> void:
	if _run_state == null:
		return
	if _run_state.shift_status != RunState.SHIFT_STATUS_RUNNING:
		return
	var result: RefCounted = _win_policy.evaluate(_run_state)
	if result == null or not result.can_win:
		return
	_run_state.shift_status = RunState.SHIFT_STATUS_SUCCESS
	_shift_log.record(EventSchema.EVENT_SHIFT_WON, {
		EventSchema.PAYLOAD_CHECKIN_DONE: _run_state.checkin_done,
		EventSchema.PAYLOAD_CHECKOUT_DONE: _run_state.checkout_done,
		EventSchema.PAYLOAD_TARGET_CHECKIN: _run_state.target_checkin,
		EventSchema.PAYLOAD_TARGET_CHECKOUT: _run_state.target_checkout,
	})
	emit_signal(
		"shift_won",
		ShiftWinPayloadScript.new(
			_run_state.checkin_done,
			_run_state.checkout_done,
			_run_state.target_checkin,
			_run_state.target_checkout
		)
	)

func _collect_end_reasons() -> Array:
	var reasons: Array = []
	for event in _shift_log.get_events():
		var event_type: StringName = event.event_type
		if event_type == EventSchema.EVENT_SHIFT_WON:
			reasons.append("SHIFT_WON")
		elif event_type == EventSchema.EVENT_SHIFT_FAILED:
			reasons.append("SHIFT_FAILED")
	return reasons