extends RefCounted

class_name WardrobeInteractionTarget

var player: WardrobePlayerController
var slots: Dictionary = {}

func set_player(value: WardrobePlayerController) -> void:
	player = value

func clear_slots() -> void:
	slots.clear()

func register_slot(slot: WardrobeSlot) -> void:
	slots[slot.get_slot_identifier()] = slot

func get_slot(slot_id: String) -> WardrobeSlot:
	return slots.get(slot_id, null)

func get_hand_item(expected_id: String) -> ItemNode:
	if player == null:
		return null
	var item := player.get_active_hand_item()
	if expected_id.is_empty() or item == null:
		return item
	return item if item.item_id == expected_id else null

func get_slot_item(slot: WardrobeSlot, expected_id: String) -> ItemNode:
	if slot == null:
		return null
	var item := slot.get_item()
	if expected_id.is_empty() or item == null:
		return item
	return item if item.item_id == expected_id else null

func perform_pick(slot: WardrobeSlot) -> Dictionary:
	if slot == null:
		return {"success": false, "reason": "slot_missing"}
	var picked := slot.take_item()
	if picked and player:
		player.hold_item(picked)
		return {"success": true, "reason": "pick_complete"}
	return {"success": false, "reason": "slot_take_failed"}

func perform_put(slot: WardrobeSlot) -> Dictionary:
	if slot == null:
		return {"success": false, "reason": "slot_missing"}
	if player == null:
		return {"success": false, "reason": "player_missing"}
	var held := player.take_item_from_hand()
	if held == null:
		return {"success": false, "reason": "hand_empty"}
	if slot.put_item(held):
		return {"success": true, "reason": "put_complete"}
	player.hold_item(held)
	return {"success": false, "reason": "slot_blocked"}

func perform_swap(slot: WardrobeSlot) -> Dictionary:
	if slot == null or player == null:
		return {"success": false, "reason": "slot_or_player_missing"}
	var incoming := slot.take_item()
	var outgoing := player.take_item_from_hand()
	if incoming == null or outgoing == null:
		if incoming:
			slot.put_item(incoming)
		if outgoing:
			player.hold_item(outgoing)
		return {"success": false, "reason": "swap_precondition_failed"}
	if not slot.put_item(outgoing):
		slot.put_item(incoming)
		player.hold_item(outgoing)
		return {"success": false, "reason": "slot_rejected_outgoing"}
	player.hold_item(incoming)
	return {"success": true, "reason": "swap_complete"}
