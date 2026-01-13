class_name ItemArchetypeDefinition

var id: StringName
var is_vampire: bool
var is_zombie: bool
var zombie_innate_stage: int # Replaces fixed radius; radius = innate_stage * config.radius_per_stage
var is_ghost: bool
var ghost_dark_alpha: float

# Config for Vampire exposure could go here too, but sticking to simple flags for now.

func _init(p_id: StringName, p_vampire: bool = false, p_zombie: bool = false, p_innate_stage: int = 0, p_is_ghost: bool = false, p_ghost_dark_alpha: float = 0.5) -> void:
	id = p_id
	is_vampire = p_vampire
	is_zombie = p_zombie
	zombie_innate_stage = p_innate_stage
	is_ghost = p_is_ghost
	ghost_dark_alpha = p_ghost_dark_alpha

static func from_json(data: Dictionary) -> ItemArchetypeDefinition:
	return ItemArchetypeDefinition.new(
		StringName(data.get("id", "")),
		bool(data.get("is_vampire", false)),
		bool(data.get("is_zombie", false)),
		int(data.get("zombie_innate_stage", 0)),
		bool(data.get("is_ghost", false)),
		float(data.get("ghost_dark_alpha", 0.5))
	)
