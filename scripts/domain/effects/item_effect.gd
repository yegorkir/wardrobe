extends RefCounted
class_name ItemEffect

var type: int # ItemEffectTypes.Type
var source: int # ItemEffectTypes.Source
var intensity: float
var tags: Dictionary

func _init(p_type: int, p_source: int, p_intensity: float = 1.0, p_tags: Dictionary = {}) -> void:
	type = p_type
	source = p_source
	intensity = p_intensity
	tags = p_tags
