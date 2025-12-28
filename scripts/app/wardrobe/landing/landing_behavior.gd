extends RefCounted
class_name LandingBehavior

const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")

func compute_outcome(_payload: Dictionary) -> LandingOutcomeScript:
	return _build_none()

func _build_none() -> LandingOutcomeScript:
	var outcome := LandingOutcomeScript.new()
	outcome.effects.append({
		LandingOutcomeScript.KEY_TYPE: LandingOutcomeScript.EFFECT_NONE,
	})
	return outcome
