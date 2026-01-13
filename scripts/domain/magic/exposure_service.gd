extends RefCounted
class_name ExposureService

const VampireExposureState := preload("res://scripts/domain/magic/vampire_exposure_state.gd")
const ZombieExposureState := preload("res://scripts/domain/magic/zombie_exposure_state.gd")
const VampireExposureSystem := preload("res://scripts/domain/magic/vampire_exposure_system.gd")
const ZombieExposureSystem := preload("res://scripts/domain/magic/zombie_exposure_system.gd")
const CorruptionAuraService := preload("res://scripts/domain/magic/corruption_aura_service.gd")
const ItemArchetypeDefinition := preload("res://scripts/domain/content/item_archetype_definition.gd")
const DebugFlags := preload("res://scripts/wardrobe/config/debug_flags.gd")
const ZombieExposureConfig := preload("res://scripts/domain/magic/zombie_exposure_config.gd")

const TRANSFER_SPEED := 100.0
const TRANSFER_TIME_MIN := 0.5
const TRANSFER_TIME_MAX := 2.0
const EMPTY_SOURCES: Array[StringName] = []

var _vampire_system: VampireExposureSystem
var _zombie_system: ZombieExposureSystem
var _corruption_service: CorruptionAuraService
var _shift_log: Callable
var _item_states: Dictionary = {} # { item_id: { vampire: State, zombie: State } }
var _zombie_config: ZombieExposureConfig
var _last_zombie_results: Dictionary = {}

func _init(shift_log: Callable = Callable(), zombie_config: ZombieExposureConfig = null) -> void:
	_shift_log = shift_log
	if zombie_config:
		_zombie_config = zombie_config
	else:
		_zombie_config = ZombieExposureConfig.new()
		
	_vampire_system = VampireExposureSystem.new(shift_log)
	_zombie_system = ZombieExposureSystem.new(_zombie_config, shift_log)
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
	
	# 1. Prepare Zombie Aura Sources
	var zombie_sources: Array[CorruptionAuraService.AuraSource] = []
	var target_stages: Dictionary = {}
	var source_stages: Dictionary = {}
	
	for item in items:
		register_item(item.id) # Ensure state exists
		
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinition
		var pos = positions.get(item.id, Vector2.ZERO)
		var z_state = _item_states[item.id]["zombie"] as ZombieExposureState
		
		# Effective stage = accumulated + innate (from archetype)
		var innate_stage = arch.zombie_innate_stage if arch else 0
		var effective_stage = z_state.stage_index + innate_stage
		
		target_stages[item.id] = effective_stage
		
		if drag_states.get(item.id, false):
			continue
			
		var radius = float(effective_stage) * _zombie_config.radius_per_stage
		
		if radius > 0.0:
			source_stages[item.id] = effective_stage
			zombie_sources.append(CorruptionAuraService.AuraSource.new(
				item.id,
				pos, 
				radius, 
				1.0
			))
	
	# 2. Update Transfer Delays and Calculate Rates
	var potential_map = _corruption_service.get_potential_sources(
		positions,
		zombie_sources,
		target_stages,
		source_stages
	)
	
	var zombie_results: Dictionary = {} # { item_id: ExposureResult }
	
	for item in items:
		var z_state = _item_states[item.id]["zombie"] as ZombieExposureState
		var potential: Array = potential_map.get(item.id, [])
		
		# Skip processing if dragging or fully corrupted
		var is_corrupted = item.quality_state and item.quality_state.current_stars <= 0.0
		if drag_states.get(item.id, false) or is_corrupted:
			if is_corrupted:
				# Clear any pending transfers so visuals stop immediately
				z_state.pending_transfers.clear()
			continue
			
		var current_potential_ids: Array[StringName] = []
		var total_exposure_in_tick := 0.0
		
		for source in potential:
			current_potential_ids.append(source.id)
			if not z_state.pending_transfers.has(source.id):
				var target_pos = positions.get(item.id, Vector2.ZERO)
				var dist = target_pos.distance_to(source.position)
				var t = clampf(dist / TRANSFER_SPEED, TRANSFER_TIME_MIN, TRANSFER_TIME_MAX)
				z_state.set_pending(source.id, t)
			
			var remaining = z_state.pending_transfers[source.id]
			var active_time = clampf(delta - remaining, 0.0, delta)
			total_exposure_in_tick += source.strength * active_time
		
		# Clear sources no longer in range
		var to_remove: Array[StringName] = []
		for source_id in z_state.pending_transfers:
			if not source_id in current_potential_ids:
				to_remove.append(source_id)
		for id in to_remove:
			z_state.clear_pending(id)
			
		# Tick delays
		z_state.tick_pending(delta)
		
		# Capping and calculating effective rate
		var max_exposure_in_tick = CorruptionAuraService.MAX_STACK_RATE * delta
		if total_exposure_in_tick > max_exposure_in_tick:
			total_exposure_in_tick = max_exposure_in_tick
			
		var effective_rate = total_exposure_in_tick / delta if delta > 0.0 else 0.0
		var active_sources = z_state.get_active_sources()
		zombie_results[item.id] = CorruptionAuraService.ExposureResult.new(effective_rate, active_sources, z_state.pending_transfers.duplicate())
	
	_last_zombie_results = zombie_results
	
	# 3. Tick Systems
	for item in items:
		var arch = archetype_provider.call(item.id) as ItemArchetypeDefinition
		var states = _item_states[item.id]
		
		# Vampire
		if arch:
			_vampire_system.tick(
				states["vampire"],
				item,
				arch,
				light_states.get(item.id, false),
				light_sources.get(item.id, EMPTY_SOURCES),
				drag_states.get(item.id, false),
				delta
			)
		
		var z_res = zombie_results.get(item.id, null)
		var z_rate = z_res.rate if z_res else 0.0
		var z_sources = z_res.sources if z_res else EMPTY_SOURCES
		var is_dragging: bool = drag_states.get(item.id, false)
		
		# Zombie: zombie archetypes emit aura but do not get corrupted themselves (unless they gain exposure from others?)
		# Current rule: zombie archetypes are sources. They might also receive exposure if we want them to rot further?
		# For now, keeping original logic: if arch.is_zombie, we might skip ticking exposure or tick it anyway?
		# The original code skipped tick if arch.is_zombie was true? No, it skipped if it WAS a zombie?
		# Original: if not arch or not arch.is_zombie: _zombie_system.tick(...)
		# This implies "True Zombies" do not get corrupted.
		if not arch or not arch.is_zombie:
			_zombie_system.tick(
				states["zombie"],
				item,
				z_rate,
				z_sources,
				is_dragging,
				delta
			)

func get_exposure_result(item_id: StringName) -> CorruptionAuraService.ExposureResult:
	return _last_zombie_results.get(item_id, null)

func get_item_aura_radius(item_id: StringName, archetype_provider: Callable) -> float:
	if not _item_states.has(item_id):
		return 0.0
	
	var arch = archetype_provider.call(item_id) as ItemArchetypeDefinition
	var z_state = _item_states[item_id]["zombie"] as ZombieExposureState
	var innate = arch.zombie_innate_stage if arch else 0
	
	return float(z_state.stage_index + innate) * _zombie_config.radius_per_stage
