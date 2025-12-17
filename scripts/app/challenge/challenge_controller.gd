extends RefCounted

class_name WardrobeChallengeController

const WardrobeShiftLogScript := preload("res://scripts/app/logging/shift_log.gd")
const WardrobeInteractionCommandScript := preload("res://scripts/app/interaction/interaction_command.gd")

var _challenge_id := ""
var _challenge_enabled := false
var _seed_entries: Array = []
var _orders: Array = []
var _par_actions := -1

var _current_order_index := -1
var _challenge_active := false
var _challenge_completed := false
var _restart_count := 0
var _elapsed := 0.0
var _metric_actions_total := 0
var _metric_picks := 0
var _metric_puts := 0
var _metric_swaps := 0
var _metric_move_distance := 0.0

var _best_results: Dictionary = {}
var _best_results_dirty := false
var _shift_log := WardrobeShiftLogScript.new()

func configure(definition: Variant, best_results: Variant, fallback_id: String) -> void:
	_challenge_id = fallback_id
	_challenge_enabled = false
	_seed_entries = []
	_orders = []
	_par_actions = -1
	if typeof(definition) == TYPE_DICTIONARY:
		var challenge := definition as Dictionary
		var seeds_variant: Variant = challenge.get("seed_layout", [])
		var orders_variant: Variant = challenge.get("target_layout", challenge.get("orders", []))
		if seeds_variant is Array and orders_variant is Array and (orders_variant as Array).size() > 0:
			_seed_entries = (seeds_variant as Array).duplicate(true)
			_orders = (orders_variant as Array).duplicate(true)
			_challenge_id = str(challenge.get("id", fallback_id))
			_par_actions = int(challenge.get("par_actions", -1))
			_challenge_enabled = true
	_best_results = best_results if typeof(best_results) == TYPE_DICTIONARY else {}
	_best_results_dirty = false
	_current_order_index = -1
	_challenge_active = false
	_challenge_completed = false
	_restart_count = 0
	_elapsed = 0.0
	_metric_actions_total = 0
	_metric_picks = 0
	_metric_puts = 0
	_metric_swaps = 0
	_metric_move_distance = 0.0

func is_enabled() -> bool:
	return _challenge_enabled

func is_active() -> bool:
	return _challenge_active

func is_completed() -> bool:
	return _challenge_completed

func get_challenge_id() -> String:
	return _challenge_id

func get_seed_entries() -> Array:
	return _seed_entries.duplicate(true)

func start_session() -> void:
	if not _challenge_enabled:
		return
	_restart_count = 0
	_prepare_session()

func restart_session() -> void:
	if not _challenge_enabled:
		return
	_restart_count += 1
	_prepare_session()

func _prepare_session() -> void:
	_current_order_index = -1
	_challenge_completed = false
	_challenge_active = true
	_elapsed = 0.0
	_metric_actions_total = 0
	_metric_picks = 0
	_metric_puts = 0
	_metric_swaps = 0
	_metric_move_distance = 0.0
	if _shift_log:
		_shift_log.clear()

func get_current_order() -> Dictionary:
	if _current_order_index < 0 or _current_order_index >= _orders.size():
		return {}
	var order := _orders[_current_order_index] as Dictionary
	return order.duplicate(true)

func get_current_order_index() -> int:
	return _current_order_index

func is_current_target_slot(slot_id: String) -> bool:
	if _current_order_index < 0 or _current_order_index >= _orders.size():
		return false
	var order := _orders[_current_order_index] as Dictionary
	return str(order.get("slot_id", "")) == slot_id

func advance_to_next_order() -> Dictionary:
	if not _challenge_enabled:
		return _make_advance_result(false, null, false)
	if not _challenge_active:
		return _make_advance_result(_challenge_completed, null, false)
	_current_order_index += 1
	if _current_order_index >= _orders.size():
		_challenge_active = false
		_challenge_completed = true
		var best_updated := _update_best_results()
		return _make_advance_result(true, null, best_updated)
	var next_order := _orders[_current_order_index] as Dictionary
	return _make_advance_result(false, next_order.duplicate(true), false)

func register_manual_action() -> void:
	if _challenge_active:
		_metric_actions_total += 1

func register_action_result(action: String) -> void:
	if not _challenge_active:
		return
	match action:
		"PICK":
			_metric_picks += 1
		"PUT":
			_metric_puts += 1
		"SWAP":
			_metric_swaps += 1

func update_elapsed(delta: float) -> void:
	if _challenge_active:
		_elapsed += delta

func add_move_distance(distance: float) -> void:
	if _challenge_active:
		_metric_move_distance += distance

func get_overlay_snapshot() -> Dictionary:
	return {
		"visible": _challenge_enabled,
		"state": _get_overlay_state(),
		"elapsed": _elapsed,
		"actions": _metric_actions_total,
	}

func get_summary_snapshot() -> Dictionary:
	if not _challenge_enabled:
		return {}
	var metrics := _build_log_metrics()
	return {
		"elapsed": _elapsed,
		"actions": metrics.actions,
		"picks": metrics.picks,
		"puts": metrics.puts,
		"swaps": metrics.swaps,
		"distance": _metric_move_distance,
		"attempts": _restart_count,
		"best_data": _get_best_data_copy(),
	}

func get_best_results() -> Dictionary:
	return _best_results.duplicate(true)

func has_best_results_update() -> bool:
	return _best_results_dirty

func mark_best_results_saved() -> void:
	_best_results_dirty = false

func get_shift_log_events() -> Array:
	return _shift_log.get_events() if _shift_log else []

func record_interaction_event(command: Dictionary, success: bool, reason: String, slot_id: String) -> void:
	if _shift_log == null:
		return
	var payload := command.duplicate(true) if command else {}
	payload["success"] = success
	payload["reason"] = reason
	payload["slot_id"] = slot_id
	_shift_log.record(StringName("interaction_performed") if success else StringName("interaction_rejected"), payload)

func clear_shift_log() -> void:
	if _shift_log:
		_shift_log.clear()

func _build_log_metrics() -> Dictionary:
	var metrics := {
		"actions": 0,
		"picks": 0,
		"puts": 0,
		"swaps": 0,
	}
	if _shift_log == null:
		return metrics
	for event in _shift_log.get_events():
		var payload_variant: Variant = event.get("payload", {})
		if typeof(payload_variant) != TYPE_DICTIONARY:
			continue
		var payload := payload_variant as Dictionary
		if not payload.get("success", false):
			continue
		metrics.actions += 1
		var command_type: StringName = payload.get(WardrobeInteractionCommandScript.KEY_TYPE, StringName())
		match command_type:
			WardrobeInteractionCommandScript.TYPE_PICK:
				metrics.picks += 1
			WardrobeInteractionCommandScript.TYPE_PUT:
				metrics.puts += 1
			WardrobeInteractionCommandScript.TYPE_SWAP:
				metrics.swaps += 1
	return metrics

func _get_overlay_state() -> String:
	if _challenge_completed:
		return "completed"
	if _challenge_active:
		return "active"
	return "ready"

func _get_best_data() -> Dictionary:
	var best_variant: Variant = _best_results.get(_challenge_id, {})
	return best_variant if best_variant is Dictionary else {}

func _get_best_data_copy() -> Dictionary:
	var best_data := _get_best_data()
	return best_data.duplicate(true) if not best_data.is_empty() else best_data

func _update_best_results() -> bool:
	if not _challenge_enabled:
		return false
	var best_data := _get_best_data()
	var updated := false
	var best_time: float = float(best_data.get("best_time", -1.0))
	if best_time < 0 or _elapsed < best_time:
		best_data["best_time"] = _elapsed
		updated = true
	var best_actions: int = int(best_data.get("best_actions", -1))
	if best_actions < 0 or _metric_actions_total < best_actions:
		best_data["best_actions"] = _metric_actions_total
		updated = true
	if updated:
		_best_results[_challenge_id] = best_data
		_best_results_dirty = true
	return updated

func _make_advance_result(completed: bool, next_order: Variant, best_dirty: bool) -> Dictionary:
	return {
		"completed": completed,
		"next_order": next_order,
		"best_results_dirty": best_dirty,
	}
