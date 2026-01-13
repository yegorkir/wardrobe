extends RefCounted
class_name ZombieExposureSystem

const ItemEffect := preload("res://scripts/domain/effects/item_effect.gd")
const ItemEffectResult := preload("res://scripts/domain/effects/item_effect_result.gd")
const ItemEffectTypes := preload("res://scripts/domain/effects/item_effect_types.gd")
const ZombieExposureState := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const ItemInstance := preload("res://scripts/domain/storage/item_instance.gd")

const EXPOSURE_THRESHOLD := 3.0
const QUALITY_LOSS_PER_STAGE := 1

var _logger: Callable

func _init(logger: Callable = Callable()) -> void:
	_logger = logger

func tick(state: ZombieExposureState, item: ItemInstance, exposure_rate: float, is_dragging: bool, delta: float) -> void:
	if is_dragging:
		state.reset()
		return
		
	if exposure_rate <= 0.0:
		state.reset()
		return
		
	state.current_stage_exposure += exposure_rate * delta
	
	if state.current_stage_exposure >= EXPOSURE_THRESHOLD:
		state.current_stage_exposure -= EXPOSURE_THRESHOLD
		state.stage_index += 1
		
		var effect = ItemEffect.new(
			ItemEffectTypes.Type.ZOMBIE_AURA,
			ItemEffectTypes.Source.ZOMBIE,
			float(QUALITY_LOSS_PER_STAGE)
		)
		
		var result = item.apply_effect(effect)
		
		if not state.is_emitting_weak_aura:
			state.is_emitting_weak_aura = true
			if _logger.is_valid():
				_logger.call("ZOMBIE_PROPAGATION_ENABLED", { "item_id": item.id })
		
		if _logger.is_valid():
			_logger.call("ZOMBIE_STAGE_COMPLETE", {
				"item_id": item.id,
				"stage": state.stage_index,
				"loss": result.quality_loss,
				"rate": exposure_rate
			})
