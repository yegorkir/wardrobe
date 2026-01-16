extends RefCounted
class_name LandingBehaviorRegistry

const DefaultLandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/default_landing_behavior.gd")
const LandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/landing_behavior.gd")

var _default_behavior: LandingBehaviorScript = DefaultLandingBehaviorScript.new()
var _behaviors_by_kind: Dictionary = {}

func register(kind: StringName, behavior: LandingBehaviorScript) -> void:
	if kind.is_empty() or behavior == null:
		return
	_behaviors_by_kind[kind] = behavior

func get_behavior(kind: StringName) -> LandingBehaviorScript:
	if _behaviors_by_kind.has(kind):
		return _behaviors_by_kind[kind] as LandingBehaviorScript
	return _default_behavior

func set_default(behavior: LandingBehaviorScript) -> void:
	if behavior == null:
		return
	_default_behavior = behavior
