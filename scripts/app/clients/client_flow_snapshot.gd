extends RefCounted

class_name ClientFlowSnapshot

var total_hook_slots: int = 0
var client_items_on_scene: int = 0
var queue_total: int = 0
var queue_checkin: int = 0
var queue_checkout: int = 0
var tickets_on_scene: int = 0
var tickets_taken: int = 0
var active_clients: int = 0

func _init(
	total_hook_slots_value: int,
	client_items_on_scene_value: int,
	queue_total_value: int,
	queue_checkin_value: int,
	queue_checkout_value: int,
	tickets_on_scene_value: int,
	tickets_taken_value: int,
	active_clients_value: int
) -> void:
	total_hook_slots = max(0, total_hook_slots_value)
	client_items_on_scene = max(0, client_items_on_scene_value)
	queue_total = max(0, queue_total_value)
	queue_checkin = max(0, queue_checkin_value)
	queue_checkout = max(0, queue_checkout_value)
	tickets_on_scene = max(0, tickets_on_scene_value)
	tickets_taken = max(0, tickets_taken_value)
	active_clients = max(0, active_clients_value)

func duplicate_snapshot() -> ClientFlowSnapshot:
	return get_script().new(
		total_hook_slots,
		client_items_on_scene,
		queue_total,
		queue_checkin,
		queue_checkout,
		tickets_on_scene,
		tickets_taken,
		active_clients
	) as ClientFlowSnapshot

func get_free_hook_capacity() -> int:
	return max(0, total_hook_slots - client_items_on_scene)
