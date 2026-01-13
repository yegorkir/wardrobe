class_name InteractionRules
extends RefCounted

const ItemArchetypeDefinitionScript := preload("res://scripts/domain/content/item_archetype_definition.gd")

## Determines if an item can be picked based on its archetype and environmental state.
## Returns true if the pick is allowed, false otherwise.
static func can_pick(archetype: ItemArchetypeDefinitionScript, is_in_light: bool) -> bool:
	if archetype == null:
		return true
		
	if archetype.is_ghost:
		# Ghost rule: Can only be picked if in light.
		# If in darkness, the hand passes through.
		if not is_in_light:
			return false
			
	return true
