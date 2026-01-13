extends RefCounted
class_name CorruptionAuraService

class AuraSource:
	var position: Vector2
	var radius: float
	var strength: float
	
	func _init(p_pos: Vector2, p_rad: float, p_str: float) -> void:
		position = p_pos
		radius = p_rad
		strength = p_str

const MAX_STACK_RATE := 3.0

func calculate_exposure_rates(target_positions: Dictionary, sources: Array[AuraSource]) -> Dictionary:
	# target_positions: { item_id: Vector2 }
	# returns: { item_id: float }
	
	var rates := {}
	
	for item_id in target_positions:
		var pos: Vector2 = target_positions[item_id]
		var rate := 0.0
		
		for source in sources:
			var dist_sq = pos.distance_squared_to(source.position)
			var rad_sq = source.radius * source.radius
			
			if dist_sq < rad_sq:
				rate += source.strength
		
		if rate > MAX_STACK_RATE:
			rate = MAX_STACK_RATE
			
		rates[item_id] = rate
		
	return rates
