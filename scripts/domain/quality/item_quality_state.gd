extends RefCounted
class_name ItemQualityState

const ItemQualityConfigScript := preload("res://scripts/domain/quality/item_quality_config.gd")

var config: RefCounted # ItemQualityConfig
var current_stars: float
var max_stars: int

func _init(p_config: RefCounted, p_current_stars: float = -1.0) -> void:
	config = p_config
	max_stars = config.max_stars
	if p_current_stars < 0:
		current_stars = float(max_stars)
	else:
		current_stars = clampf(p_current_stars, 0.0, float(max_stars))

func duplicate_state() -> ItemQualityState:
	return get_script().new(config, current_stars) as ItemQualityState

func to_snapshot() -> Dictionary:
	return {
		"current": current_stars,
		"max": max_stars
	}

func reduce_quality(amount: float) -> float:
	var old_stars = current_stars
	current_stars = clampf(current_stars - amount, 0.0, float(max_stars))
	return old_stars - current_stars
