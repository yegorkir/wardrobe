class_name PhysicsPlacementGate
extends RefCounted

const PhysicsGateResultScript := preload("res://scripts/wardrobe/physics/physics_gate_result.gd")

enum Decision {
	ALLOW,
	ALLOW_NUDGE,
	REJECT,
}

var max_affected: int
var max_area_ratio: float
var max_push_per_item_px: float
var max_push_total_px: float
var min_push_px: float
var ignore_push_px: float

func _init(
	max_affected_value: int,
	max_area_ratio_value: float,
	max_push_per_item_value: float,
	max_push_total_value: float,
	min_push_value: float,
	ignore_push_value: float
) -> void:
	max_affected = max_affected_value
	max_area_ratio = max_area_ratio_value
	max_push_per_item_px = max_push_per_item_value
	max_push_total_px = max_push_total_value
	min_push_px = min_push_value
	ignore_push_px = ignore_push_value

func decide_overlap(metrics: Dictionary, would_push_out_of_bounds: bool) -> PhysicsGateResult:
	var affected: int = int(metrics.get("affected_count", 0))
	var max_push: float = float(metrics.get("max_push_px", 0.0))
	var total_push: float = float(metrics.get("total_push_px", 0.0))
	var max_ratio: float = float(metrics.get("max_area_ratio", 0.0))
	if affected > max_affected:
		return _decision(Decision.REJECT, &"reject_big_overlap_affected", metrics)
	if max_ratio > max_area_ratio:
		return _decision(Decision.REJECT, &"reject_big_overlap_area", metrics)
	if max_push > max_push_per_item_px:
		return _decision(Decision.REJECT, &"reject_big_overlap_push_item", metrics)
	if total_push > max_push_total_px:
		return _decision(Decision.REJECT, &"reject_big_overlap_push_total", metrics)
	if would_push_out_of_bounds:
		return _decision(Decision.REJECT, &"reject_big_overlap_bounds", metrics)
	if max_push < ignore_push_px:
		return _decision(Decision.ALLOW, StringName(), metrics)
	return _decision(Decision.ALLOW_NUDGE, StringName(), metrics)

func _decision(decision: int, reason: StringName, metrics: Dictionary) -> PhysicsGateResult:
	return PhysicsGateResultScript.new(decision, reason, metrics)
