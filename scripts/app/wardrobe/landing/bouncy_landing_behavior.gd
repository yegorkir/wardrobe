extends "res://scripts/app/wardrobe/landing/landing_behavior.gd"
class_name BouncyLandingBehavior

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
var impact_threshold: float = 220.0
var bounce_multiplier: float = 0.6

func _init(threshold: float = 220.0, multiplier: float = 0.6) -> void:
	impact_threshold = threshold
	bounce_multiplier = multiplier

func compute_outcome(payload: Dictionary) -> LandingOutcomeScript:
	var impact := float(payload.get(EventSchema.PAYLOAD_IMPACT, 0.0))
	if impact >= impact_threshold:
		var outcome := LandingOutcomeScript.new()
		outcome.effects.append({
			LandingOutcomeScript.KEY_TYPE: LandingOutcomeScript.EFFECT_BOUNCE,
			LandingOutcomeScript.KEY_MULTIPLIER: bounce_multiplier,
		})
		return outcome
	return _build_none()
