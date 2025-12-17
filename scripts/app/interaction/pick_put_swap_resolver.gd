extends RefCounted

class_name PickPutSwapResolver

const ACTION_NONE := "NONE"
const ACTION_PICK := "PICK"
const ACTION_PUT := "PUT"
const ACTION_SWAP := "SWAP"

func resolve(hand_has_item: bool, slot_has_item: bool) -> Dictionary:
	var action := _determine_action(hand_has_item, slot_has_item)
	match action:
		ACTION_PICK:
			return _make_result(true, ACTION_PICK, "pick_allowed")
		ACTION_PUT:
			return _make_result(true, ACTION_PUT, "put_allowed")
		ACTION_SWAP:
			return _make_result(true, ACTION_SWAP, "swap_allowed")
		_:
			return _make_result(false, ACTION_NONE, "nothing_to_do")

func _determine_action(hand_item_present: bool, slot_item_present: bool) -> String:
	if not hand_item_present and not slot_item_present:
		return ACTION_NONE
	if not hand_item_present:
		return ACTION_PICK
	if not slot_item_present:
		return ACTION_PUT
	return ACTION_SWAP

func _make_result(success: bool, action: String, reason: String) -> Dictionary:
	return {
		"success": success,
		"action": action,
		"reason": reason,
	}
