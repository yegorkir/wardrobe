class_name PhysicsGateResult
extends RefCounted

var decision: int
var reason: StringName = StringName()
var metrics: Dictionary = {}

func _init(decision_value: int, reason_value: StringName = StringName(), metrics_value: Dictionary = {}) -> void:
	decision = decision_value
	reason = reason_value
	metrics = metrics_value
