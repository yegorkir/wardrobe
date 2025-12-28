extends "res://scripts/app/wardrobe/landing/landing_behavior.gd"
class_name DefaultLandingBehavior

func compute_outcome(_payload: Dictionary) -> LandingOutcomeScript:
	return _build_none()
