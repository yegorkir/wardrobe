extends RefCounted
class_name ItemEffectResult

var accepted: bool
var quality_loss: float
var events: Array[Dictionary] # Domain events

func _init(p_accepted: bool = false, p_quality_loss: float = 0.0, p_events: Array[Dictionary] = []) -> void:
	accepted = p_accepted
	quality_loss = p_quality_loss
	events = p_events
