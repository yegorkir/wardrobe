extends RefCounted

func validate(slots: Array[WardrobeSlot], player: Node) -> void:
	var issues: Array[String] = []
	var item_locations: Dictionary = {}
	for slot in slots:
		var slot_item := slot.get_item()
		if slot_item:
			if item_locations.has(slot_item):
				issues.append(
					"Item %s duplicated between %s and %s" % [
						slot_item.item_id,
						item_locations[slot_item],
						slot.get_slot_identifier(),
					]
				)
			else:
				item_locations[slot_item] = slot.get_slot_identifier()
	if player != null and player.has_method("get_active_hand_item"):
		var hand_item: Variant = player.call("get_active_hand_item")
		if hand_item:
			if item_locations.has(hand_item):
				issues.append("Item %s exists in slot and hand" % hand_item.item_id)
			else:
				item_locations[hand_item] = "hand"
	if issues.size() > 0:
		for issue in issues:
			push_error("Wardrobe integrity violation: %s" % issue)
