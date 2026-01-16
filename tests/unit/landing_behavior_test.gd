extends GdUnitTestSuite

const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const LandingOutcomeScript := preload("res://scripts/app/wardrobe/landing/landing_outcome.gd")
const DefaultLandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/default_landing_behavior.gd")
const BouncyLandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/bouncy_landing_behavior.gd")
const BreakableLandingBehaviorScript := preload("res://scripts/app/wardrobe/landing/breakable_landing_behavior.gd")
const LandingServiceScript := preload("res://scripts/app/wardrobe/landing/landing_service.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")

func test_default_behavior_returns_none() -> void:
	var behavior := DefaultLandingBehaviorScript.new()
	var outcome := behavior.compute_outcome({})
	assert_int(outcome.effects.size()).is_equal(1)
	assert_str(str(outcome.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_NONE))

func test_bouncy_behavior_bounces_above_threshold() -> void:
	var behavior := BouncyLandingBehaviorScript.new(100.0, 0.8)
	var outcome_low := behavior.compute_outcome({EventSchema.PAYLOAD_IMPACT: 50.0})
	assert_int(outcome_low.effects.size()).is_equal(1)
	assert_str(str(outcome_low.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_NONE))
	var outcome_high := behavior.compute_outcome({EventSchema.PAYLOAD_IMPACT: 120.0})
	assert_int(outcome_high.effects.size()).is_equal(1)
	assert_str(str(outcome_high.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_BOUNCE))
	assert_float(float(outcome_high.effects[0].get(LandingOutcomeScript.KEY_MULTIPLIER, 0.0))).is_equal(0.8)

func test_breakable_behavior_breaks_above_threshold() -> void:
	var behavior := BreakableLandingBehaviorScript.new(200.0)
	var outcome_low := behavior.compute_outcome({EventSchema.PAYLOAD_IMPACT: 150.0})
	assert_int(outcome_low.effects.size()).is_equal(1)
	assert_str(str(outcome_low.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_NONE))
	var outcome_high := behavior.compute_outcome({EventSchema.PAYLOAD_IMPACT: 240.0})
	assert_int(outcome_high.effects.size()).is_equal(1)
	assert_str(str(outcome_high.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_BREAK))

func test_landing_service_registry_routes_kinds() -> void:
	var service := LandingServiceScript.new()
	var ticket_outcome := service.record_item_landed({
		EventSchema.PAYLOAD_ITEM_KIND: ItemInstanceScript.KIND_TICKET,
		EventSchema.PAYLOAD_IMPACT: 500.0,
	})
	assert_str(str(ticket_outcome.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_BOUNCE))
	var anchor_outcome := service.record_item_landed({
		EventSchema.PAYLOAD_ITEM_KIND: ItemInstanceScript.KIND_ANCHOR_TICKET,
		EventSchema.PAYLOAD_IMPACT: 500.0,
	})
	assert_str(str(anchor_outcome.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_BREAK))
	var coat_outcome := service.record_item_landed({
		EventSchema.PAYLOAD_ITEM_KIND: ItemInstanceScript.KIND_COAT,
		EventSchema.PAYLOAD_IMPACT: 500.0,
	})
	assert_str(str(coat_outcome.effects[0].get(LandingOutcomeScript.KEY_TYPE, StringName()))).is_equal(str(LandingOutcomeScript.EFFECT_NONE))
