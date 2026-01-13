extends GdUnitTestSuite

const InteractionRules := preload("res://scripts/domain/interaction/interaction_rules.gd")
const ItemArchetypeDefinition := preload("res://scripts/domain/content/item_archetype_definition.gd")

func test_can_pick_ghost_in_light() -> void:
	var arch = ItemArchetypeDefinition.new("ghost", false, false, 0, true)
	var result = InteractionRules.can_pick(arch, true)
	assert_bool(result).is_true()

func test_can_pick_ghost_in_dark() -> void:
	var arch = ItemArchetypeDefinition.new("ghost", false, false, 0, true)
	var result = InteractionRules.can_pick(arch, false)
	assert_bool(result).is_false()

func test_can_pick_normal_item_in_light() -> void:
	var arch = ItemArchetypeDefinition.new("coat")
	var result = InteractionRules.can_pick(arch, true)
	assert_bool(result).is_true()

func test_can_pick_normal_item_in_dark() -> void:
	var arch = ItemArchetypeDefinition.new("coat")
	var result = InteractionRules.can_pick(arch, false)
	assert_bool(result).is_true()

func test_can_pick_null_archetype() -> void:
	var result = InteractionRules.can_pick(null, false)
	assert_bool(result).is_true()
