extends RefCounted
class_name ZombieExposureConfig

const DEFAULT_RADIUS := 30.0
const DEFAULT_LOSS := 0.5
const DEFAULT_THRESHOLD := 10.0

var radius_per_stage: float
var quality_loss_per_stage: float
var exposure_threshold: float

func _init(p_radius: float = DEFAULT_RADIUS, p_loss: float = DEFAULT_LOSS, p_threshold: float = DEFAULT_THRESHOLD) -> void:
	radius_per_stage = p_radius
	quality_loss_per_stage = p_loss
	exposure_threshold = p_threshold
	print("ZombieExposureConfig INIT: radius=", radius_per_stage, " loss=", quality_loss_per_stage, " threshold=", exposure_threshold)