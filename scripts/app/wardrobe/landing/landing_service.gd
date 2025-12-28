extends RefCounted
class_name LandingService

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")
const LandingBehaviorRegistry := preload("res://scripts/app/wardrobe/landing/landing_behavior_registry.gd")
const LandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/landing_behavior.gd")
const DefaultLandingBehavior := preload("res://scripts/app/wardrobe/landing/default_landing_behavior.gd")
const BouncyLandingBehavior := preload("res://scripts/app/wardrobe/landing/bouncy_landing_behavior.gd")
const BreakableLandingBehavior := preload("res://scripts/app/wardrobe/landing/breakable_landing_behavior.gd")

var _registry: LandingBehaviorRegistry = LandingBehaviorRegistry.new()

func _init() -> void:
	_registry.set_default(DefaultLandingBehavior.new())
	_registry.register(ItemInstanceScript.KIND_TICKET, BouncyLandingBehavior.new())
	_registry.register(ItemInstanceScript.KIND_ANCHOR_TICKET, BreakableLandingBehavior.new())

func record_item_landed(payload: Dictionary) -> LandingOutcomeScript:
	var item_kind: StringName = payload.get(EventSchema.PAYLOAD_ITEM_KIND, StringName())
	var behavior: LandingBehaviorScript = _registry.get_behavior(item_kind)
	if behavior == null:
		var outcome := LandingOutcomeScript.new()
		outcome.effects.append({
			LandingOutcomeScript.KEY_TYPE: LandingOutcomeScript.EFFECT_NONE,
		})
		return outcome
	return behavior.compute_outcome(payload)
