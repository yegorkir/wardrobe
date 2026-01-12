extends RefCounted
class_name WardrobeInteractionContext

const FloorResolverScript := preload("res://scripts/app/wardrobe/floor_resolver.gd")

var player: Node
var interaction_service: WardrobeInteractionService
var storage_state: WardrobeStorageState
var slots: Array[WardrobeSlot] = []
var slot_lookup: Dictionary = {}
var item_nodes: Dictionary = {}
var spawned_items: Array = []
var item_scene: PackedScene
var item_visuals: WardrobeItemVisualsAdapter
var physics_tick
var event_adapter: WardrobeInteractionEventAdapter
var interaction_events: WardrobeInteractionEventsAdapter
var desk_event_dispatcher: DeskEventDispatcher
var desk_states: Array = []
var desk_by_id: Dictionary = {}
var desk_by_slot_id: Dictionary = {}
var desk_system: DeskServicePointSystem
var client_queue_state: ClientQueueState
var clients: Dictionary = {}
var find_item_instance: Callable
var interaction_logger
var floor_resolver
var apply_patience_penalty: Callable
var register_item: Callable