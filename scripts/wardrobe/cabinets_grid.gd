extends Node2D

class_name CabinetsGrid

func get_ticket_slots() -> Array[WardrobeSlot]:
	var ticket_slots: Array[WardrobeSlot] = []
	for node in find_children("*", "WardrobeSlot", true, true):
		if node is WardrobeSlot:
			var slot := node as WardrobeSlot
			var slot_id := String(slot.get_slot_identifier())
			if slot_id.is_empty():
				continue
			if not slot_id.begins_with("Cab_"):
				continue
			if not (slot_id.ends_with("_SlotA") or slot_id.ends_with("_SlotB")):
				continue
			ticket_slots.append(slot)
	return ticket_slots
