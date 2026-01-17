extends Node2D

class_name CabinetsGrid

const CabinetSymbolAtlasScript := preload("res://scripts/wardrobe/cabinet_symbol_atlas.gd")

func _ready() -> void:
	_assign_ticket_symbol_indices()
	_refresh_cabinet_plate_icons()

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
	_sort_slots_by_id(ticket_slots)
	return ticket_slots

func _assign_ticket_symbol_indices() -> void:
	var slots := get_ticket_slots()
	for index in range(slots.size()):
		var slot := slots[index]
		if slot == null:
			continue
		slot.ticket_symbol_index = CabinetSymbolAtlasScript.wrap_index(index)

func _refresh_cabinet_plate_icons() -> void:
	for child in get_children():
		if child is StorageCabinetLayout:
			(child as StorageCabinetLayout).refresh_plate_icons()

func _sort_slots_by_id(slots: Array[WardrobeSlot]) -> void:
	slots.sort_custom(Callable(self, "_compare_slot_ids"))

func _compare_slot_ids(a: WardrobeSlot, b: WardrobeSlot) -> bool:
	if a == null or b == null:
		return a != null
	return String(a.get_slot_identifier()) < String(b.get_slot_identifier())
