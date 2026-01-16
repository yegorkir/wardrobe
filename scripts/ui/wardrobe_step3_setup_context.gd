extends RefCounted
class_name WardrobeStep3SetupContext

var root: Node
var clear_spawned_items: Callable
var collect_desks: Callable
var desk_nodes: Array
var desk_states: Array
var desk_by_id: Dictionary
var desk_by_slot_id: Dictionary
var clients: Dictionary
var client_queue_state: ClientQueueState
var desk_system: DeskServicePointSystem
var queue_system: ClientQueueSystem
var storage_state: WardrobeStorageState
var get_ticket_slots: Callable
var get_cabinet_ticket_slots: Callable
var place_item_instance_in_slot: Callable
var apply_desk_events: Callable
var register_item: Callable
