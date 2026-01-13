extends RefCounted
class_name ExposureService

const VampireExposureStateScript := preload("res://scripts/domain/magic/vampire_exposure_state.gd")
const ZombieExposureStateScript := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const VampireExposureSystemScript := preload("res://scripts/domain/magic/vampire_exposure_system.gd")
const ZombieExposureSystemScript := preload("res://scripts/domain/magic/zombie_exposure_system.gd")
const CorruptionAuraServiceScript := preload("res://scripts/domain/magic/corruption_aura_service.gd")
const ItemArchetypeDefinitionScript := preload("res://scripts/domain/content/item_archetype_definition.gd")

var _vampire_system: VampireExposureSystemScript
var _zombie_system: ZombieExposureSystemScript
var _corruption_service: CorruptionAuraServiceScript
var _shift_log: Callable
var _item_states: Dictionary = {} # { item_id: { vampire: State, zombie: State } }

func _init(shift_log: Callable = Callable()) -> void:
	_shift_log = shift_log
	_vampire_system = VampireExposureSystemScript.new(shift_log)
	_zombie_system = ZombieExposureSystemScript.new(shift_log)
	_corruption_service = CorruptionAuraServiceScript.new()

func register_item(item_id: StringName) -> void:
	if not _item_states.has(item_id):
		_item_states[item_id] = {
			"vampire": VampireExposureStateScript.new(),
			"zombie": ZombieExposureStateScript.new()
		}

func tick(
	items: Array,
	positions: Dictionary,
	drag_states: Dictionary,
	light_states: Dictionary,
	light_sources: Dictionary,
	archetype_provider: Callable,
	delta: float
) -> void:
	# items: Array[ItemInstance]
	
	# 1. Calculate Zombie Aura Rates
	var zombie_sources: Array[CorruptionAuraServiceScript.AuraSource] = []
	
	for item in items:
		register_item(item.id) # Ensure state exists
		
		if drag_states.get(item.id, false):
			continue
			
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinitionScript
		if not arch: continue
		
		var pos = positions.get(item.id, Vector2.ZERO)
		
		# Archetype source
		if arch.is_zombie:
			zombie_sources.append(CorruptionAuraServiceScript.AuraSource.new(
				pos, 
				arch.corruption_aura_radius, 
				1.0
			))
		
		# State source (propagation)
		var z_state = _item_states[item.id]["zombie"] as ZombieExposureStateScript
		if z_state.is_emitting_weak_aura:
			zombie_sources.append(CorruptionAuraServiceScript.AuraSource.new(
				pos, 
				arch.corruption_aura_radius, 
				1.0 
			))
	
	var zombie_rates = _corruption_service.calculate_exposure_rates(positions, zombie_sources)
	
	# 2. Tick Systems
	for item in items:
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinitionScript
		if not arch: continue
		
		var states = _item_states[item.id]
		
		# Vampire
		_vampire_system.tick(
			states["vampire"],
			item,
			arch,
			light_states.get(item.id, false),
			light_sources.get(item.id, []),
			drag_states.get(item.id, false),
			delta
		)
		
		# Zombie
		_zombie_system.tick(
			states["zombie"],
			item,
			zombie_rates.get(item.id, 0.0),
			drag_states.get(item.id, false),
			delta
		)

func is_emitting_weak_aura(item_id: StringName) -> bool:
	if _item_states.has(item_id):
		return _item_states[item_id]["zombie"].is_emitting_weak_aura
	return false
