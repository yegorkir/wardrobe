extends "res://scripts/app/wardrobe/landing/landing_behavior.gd"
class_name BreakableLandingBehavior

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
var impact_threshold: float = 360.0

func _init(threshold: float = 360.0) -> void:
	impact_threshold = threshold

func compute_outcome(payload: Dictionary) -> LandingOutcomeScript:
	var impact := float(payload.get(EventSchema.PAYLOAD_IMPACT, 0.0))
	if impact >= impact_threshold:
		var outcome := LandingOutcomeScript.new()
		outcome.effects.append({
			LandingOutcomeScript.KEY_TYPE: LandingOutcomeScript.EFFECT_BREAK,
		})
		return outcome
	return _build_none()
