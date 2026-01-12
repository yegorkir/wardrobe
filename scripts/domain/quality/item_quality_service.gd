extends RefCounted
class_name ItemQualityService

const ItemQualityStateScript := preload("res://scripts/domain/quality/item_quality_state.gd")

class DamageResult:
	var old_stars: float
	var new_stars: float
	var delta: float
	var source: StringName
	
	func _init(p_old: float, p_new: float, p_source: StringName) -> void:
		old_stars = p_old
		new_stars = p_new
		delta = new_stars - old_stars
		source = p_source

# amount is abstract damage units, usually corresponding to star loss
static func apply_damage(state: RefCounted, source: StringName, amount: float) -> DamageResult:
	var old_stars := float(state.get("current_stars"))
	var allowed_steps: Array = state.get("config").get("allowed_steps")
	
	var loss := _quantize_loss(amount, allowed_steps)
	
	# Apply logic: prevent negative stars
	var max_stars: int = state.get("max_stars")
	var new_stars := clampf(old_stars - loss, 0.0, float(max_stars))
	
	state.set("current_stars", new_stars)
	
	return DamageResult.new(old_stars, new_stars, source)

static func _quantize_loss(amount: float, allowed_steps: Array) -> float:
	var best_step := 0.0
	for step in allowed_steps:
		if amount >= float(step):
			best_step = maxf(best_step, float(step))
	
	return best_step