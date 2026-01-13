extends RefCounted
class_name ZombieExposureState

var current_stage_exposure: float = 0.0
var stage_index: int = 0
var is_emitting_weak_aura: bool = false

func reset() -> void:
	current_stage_exposure = 0.0
	stage_index = 0
	# is_emitting_weak_aura usually persists until reset? 
	# "exposure resets...". If exposure resets, does aura stop?
	# "After first zombie stage, the affected item emits a weak aura".
	# If exposure resets (e.g. dragging?), does it stop emitting?
	# Plan: "Drag rule: while item is dragged... does not accumulate exposure and does not affect others."
	# So yes, while dragging, it shouldn't emit. But if dropped? 
	# Analysis says "Zombie items lose quality... exposure resets when...?" 
	# Wait, Vampire resets when leaving light. Zombie resets when?
	# "Accumulate exposure from nearby sources... reset on removal (from aura?)"
	# If I walk away from aura, exposure might decay or reset.
	# For iteration 7, let's assume simple reset if rate is 0?
	# Or maybe it stays?
	# "Vampire exposure: accumulate/reset... Zombie aura: ... reset on removal"
	# I'll implement reset if rate is 0 in the system.
	is_emitting_weak_aura = false

func reset_exposure_only() -> void:
	current_stage_exposure = 0.0

func duplicate_state() -> ZombieExposureState:
	var dup = get_script().new()
	dup.current_stage_exposure = current_stage_exposure
	dup.stage_index = stage_index
	dup.is_emitting_weak_aura = is_emitting_weak_aura
	return dup
