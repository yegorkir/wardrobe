extends RefCounted
class_name ItemArchetypeDefinition

var id: StringName
var is_vampire: bool
var is_zombie: bool
var corruption_aura_radius: float
# Config for Vampire exposure could go here too, but sticking to simple flags for now.

func _init(p_id: StringName, p_is_vampire: bool = false, p_is_zombie: bool = false, p_radius: float = 0.0) -> void:
	id = p_id
	is_vampire = p_is_vampire
	is_zombie = p_is_zombie
	corruption_aura_radius = p_radius
