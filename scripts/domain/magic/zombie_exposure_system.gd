extends RefCounted
class_name ZombieExposureSystem

const ItemEffect := preload("res://scripts/domain/effects/item_effect.gd")
const ItemEffectTypes := preload("res://scripts/domain/effects/item_effect_types.gd")
const ZombieExposureState := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const ItemInstance := preload("res://scripts/domain/storage/item_instance.gd")
const ZombieExposureConfig := preload("res://scripts/domain/magic/zombie_exposure_config.gd")

var _logger: Callable
var _config: ZombieExposureConfig

func _init(config: ZombieExposureConfig, logger: Callable = Callable()) -> void:
	_config = config
	_logger = logger

func tick(state: ZombieExposureState, item: ItemInstance, exposure_rate: float, source_ids: Array[StringName], is_dragging: bool, delta: float) -> void:
	if is_dragging:
		state.reset_exposure_only()
		return
		
	if exposure_rate <= 0.0:
		state.reset_exposure_only()
		return
		
	# Stop processing if item is already fully corrupted
	if item.quality_state.current_stars <= 0.0:
		state.reset_exposure_only()
		return

	state.current_stage_exposure += exposure_rate * delta
	
	if state.current_stage_exposure >= _config.exposure_threshold:
		state.current_stage_exposure -= _config.exposure_threshold
		state.stage_index += 1
		
		var effect = ItemEffect.new(
			ItemEffectTypes.Type.ZOMBIE_AURA,
			ItemEffectTypes.Source.ZOMBIE,
			_config.quality_loss_per_stage
		)
		
		var result = item.apply_effect(effect)
		
		# "Weak aura" is now implicit (stage > 0), so no need to set a flag.
		if state.stage_index == 1:
			if _logger.is_valid():
				_logger.call("ZOMBIE_PROPAGATION_ENABLED", { "item_id": item.id })
		
		if _logger.is_valid():
			_logger.call("ZOMBIE_STAGE_COMPLETE", {
				"item_id": item.id,
				"stage": state.stage_index,
				"loss": result.quality_loss,
				"rate": exposure_rate,
				"sources": source_ids
			})
