class_name StorageCabinetLayout
extends Node2D

@export var cabinet_id: StringName = StringName()

@onready var _slots_root: Node = $Slots

func _ready() -> void:
	_assign_slot_ids()

func _assign_slot_ids() -> void:
	if cabinet_id == StringName():
		cabinet_id = StringName(name)
	if _slots_root == null:
		push_warning("StorageCabinetLayout missing Slots node: %s" % name)
		return
	var positions: Array[Node] = []
	for child in _slots_root.get_children():
		if child is Node:
			positions.append(child)
	positions.sort_custom(Callable(self, "_compare_positions"))
	var index := 0
	for pos in positions:
		var slot_a := pos.get_node_or_null("SlotA") as WardrobeSlot
		var slot_b := pos.get_node_or_null("SlotB") as WardrobeSlot
		if slot_a == null or slot_b == null:
			push_warning("StorageCabinetLayout %s missing SlotA/SlotB in %s" % [cabinet_id, pos.name])
			index += 1
			continue
		var prefix := "%s_P%d" % [String(cabinet_id), index]
		slot_a.slot_id = "%s_SlotA" % prefix
		slot_b.slot_id = "%s_SlotB" % prefix
		index += 1

func _compare_positions(a: Node, b: Node) -> bool:
	return String(a.name) < String(b.name)
