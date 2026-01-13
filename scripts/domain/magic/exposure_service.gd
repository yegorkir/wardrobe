extends RefCounted
class_name ExposureService

const WEAK_AURA_RADIUS := 100.0
const VampireExposureState := preload("res://scripts/domain/magic/vampire_exposure_state.gd")
const ZombieExposureState := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const VampireExposureSystem := preload("res://scripts/domain/magic/vampire_exposure_system.gd")
const ZombieExposureSystem := preload("res://scripts/domain/magic/zombie_exposure_system.gd")
const CorruptionAuraService := preload("res://scripts/domain/magic/corruption_aura_service.gd")
const ItemArchetypeDefinition := preload("res://scripts/domain/content/item_archetype_definition.gd")

var _vampire_system: VampireExposureSystem
var _zombie_system: ZombieExposureSystem
var _corruption_service: CorruptionAuraService
var _shift_log: Callable
var _item_states: Dictionary = {} # { item_id: { vampire: State, zombie: State } }

func _init(shift_log: Callable = Callable()) -> void:
	_shift_log = shift_log
	_vampire_system = VampireExposureSystem.new(shift_log)
	_zombie_system = ZombieExposureSystem.new(shift_log)
	_corruption_service = CorruptionAuraService.new()

func register_item(item_id: StringName) -> void:
	if not _item_states.has(item_id):
		_item_states[item_id] = {
			"vampire": VampireExposureState.new(),
			"zombie": ZombieExposureState.new()
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
	var zombie_sources: Array[CorruptionAuraService.AuraSource] = []
	
	for item in items:
		register_item(item.id) # Ensure state exists
		
		if drag_states.get(item.id, false):
			continue
			
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinition
		if not arch: continue
		
		var pos = positions.get(item.id, Vector2.ZERO)
		var z_state = _item_states[item.id]["zombie"] as ZombieExposureState
		
		var radius = arch.corruption_aura_radius
		var is_source = false
		
		if arch.is_zombie:
			is_source = true
		elif z_state.is_emitting_weak_aura:
			is_source = true
			if radius <= 0.0:
				radius = WEAK_AURA_RADIUS
		
		if is_source:
			zombie_sources.append(CorruptionAuraService.AuraSource.new(
				item.id,
				pos, 
				radius, 
				1.0
			))
	
	var zombie_results = _corruption_service.calculate_exposure_rates(positions, zombie_sources)
	
	# 2. Tick Systems
	for item in items:
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinition
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
		var z_res = zombie_results.get(item.id, null)
		var z_rate = z_res.rate if z_res else 0.0
		var z_sources = z_res.sources if z_res else []
		
		_zombie_system.tick(
			states["zombie"],
			item,
			z_rate,
			z_sources,
			drag_states.get(item.id, false),
			delta
		)

func is_emitting_weak_aura(item_id: StringName) -> bool:
	if _item_states.has(item_id):
		return _item_states[item_id]["zombie"].is_emitting_weak_aura
	return false
