extends RefCounted
class_name CorruptionAuraService

class AuraSource:
	var id: StringName
	var position: Vector2
	var radius: float
	var strength: float
	
	func _init(p_id: StringName, p_pos: Vector2, p_rad: float, p_str: float) -> void:
		id = p_id
		position = p_pos
		radius = p_rad
		strength = p_str

const MAX_STACK_RATE := 3.0

class ExposureResult:
	var rate: float
	var sources: Array[StringName]
	
	func _init(p_rate: float, p_sources: Array[StringName]) -> void:
		rate = p_rate
		sources = p_sources

func calculate_exposure_rates(
	target_positions: Dictionary,
	sources: Array[AuraSource],
	target_stages: Dictionary,
	source_stages: Dictionary
) -> Dictionary:
	# target_positions: { item_id: Vector2 }
	# returns: { item_id: ExposureResult }
	
	var results := {}
	
	for item_id in target_positions:
		var pos: Vector2 = target_positions[item_id]
		var target_stage: int = int(target_stages.get(item_id, 0))
		var total_rate := 0.0
		var affecting_sources: Array[StringName] = []
		
		for source in sources:
			if source.id == item_id:
				continue
			var source_stage: int = int(source_stages.get(source.id, 0))
			if source_stage <= target_stage:
				continue
			var dist_sq = pos.distance_squared_to(source.position)
			var rad_sq = source.radius * source.radius
			
			if dist_sq < rad_sq:
				total_rate += source.strength
				affecting_sources.append(source.id)
		
		if total_rate > MAX_STACK_RATE:
			total_rate = MAX_STACK_RATE
			
		results[item_id] = ExposureResult.new(total_rate, affecting_sources)
		
	return results
