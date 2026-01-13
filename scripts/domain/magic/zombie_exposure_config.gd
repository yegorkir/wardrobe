extends RefCounted
class_name ZombieExposureConfig

var radius_per_stage: float
var quality_loss_per_stage: float
var exposure_threshold: float

func _init(p_radius: float = 50.0, p_loss: float = 0.5, p_threshold: float = 3.0) -> void:
	radius_per_stage = p_radius
	quality_loss_per_stage = p_loss
	exposure_threshold = p_threshold