extends RefCounted
class_name VampireExposureSystem

const ItemEffectScript := preload("res://scripts/domain/effects/item_effect.gd")
const ItemEffectTypesScript := preload("res://scripts/domain/effects/item_effect_types.gd")
const VampireExposureStateScript := preload("res://scripts/domain/magic/vampire_exposure_state.gd")
const ItemInstanceScript := preload("res://scripts/domain/storage/item_instance.gd")
const ItemArchetypeDefinitionScript := preload("res://scripts/domain/content/item_archetype_definition.gd")
const EXPOSURE_THRESHOLD := 2.0 
const QUALITY_LOSS_PER_STAGE := 0.5

var _logger: Callable

func _init(logger: Callable = Callable()) -> void:
	_logger = logger

func tick(
	state: VampireExposureState,
	item: ItemInstance,
	archetype: ItemArchetypeDefinition,
	is_in_light: bool,
	light_sources: Array[StringName],
	is_dragging: bool,
	delta: float
) -> void:
	if not archetype.is_vampire:
		return
		
	if is_dragging or not is_in_light:
		state.reset()
		return
		
	state.current_stage_exposure += delta
	
	if state.current_stage_exposure >= EXPOSURE_THRESHOLD:
		state.current_stage_exposure -= EXPOSURE_THRESHOLD
		state.stage_index += 1
		
		var effect = ItemEffectScript.new(
			ItemEffectTypesScript.Type.LIGHT_CORROSION,
			ItemEffectTypesScript.Source.LIGHT,
			float(QUALITY_LOSS_PER_STAGE)
		)
		
		var result = item.apply_effect(effect)
		
		if _logger.is_valid():
			_logger.call("VAMPIRE_STAGE_COMPLETE", {
				"item_id": item.id,
				"stage": state.stage_index,
				"loss": result.quality_loss,
				"sources": light_sources
			})
