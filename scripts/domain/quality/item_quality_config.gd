extends RefCounted
class_name ItemQualityConfig

var max_stars: int = 3
var allowed_steps: Array = [0.5, 1.0, 2.0]

func _init(p_max_stars: int = 3) -> void:
	max_stars = p_max_stars