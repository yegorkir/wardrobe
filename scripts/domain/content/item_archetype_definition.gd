class_name ItemArchetypeDefinition

var id: StringName
var is_vampire: bool
var is_zombie: bool
var zombie_innate_stage: int # Replaces fixed radius; radius = innate_stage * config.radius_per_stage

# Config for Vampire exposure could go here too, but sticking to simple flags for now.

func _init(p_id: StringName, p_vampire: bool = false, p_zombie: bool = false, p_innate_stage: int = 0) -> void:
	id = p_id
	is_vampire = p_vampire
	is_zombie = p_zombie
	zombie_innate_stage = p_innate_stage
