extends RefCounted

class_name PickPutSwapResolver

const InteractionConfigScript := preload("res://scripts/app/interaction/interaction_config.gd")

const ACTION_NONE := "NONE"
const ACTION_PICK := "PICK"
const ACTION_PUT := "PUT"

var _config: InteractionConfigScript = InteractionConfigScript.new()

func setup(config: InteractionConfigScript) -> void:
	_config = config.duplicate_config() if config else InteractionConfigScript.new()

func resolve(hand_has_item: bool, slot_has_item: bool) -> Dictionary:
	if hand_has_item and slot_has_item:
		if not _config.swap_enabled:
			return _make_result(false, ACTION_NONE, "swap_disabled")
		return _make_result(false, ACTION_NONE, "swap_unavailable")
	var action := _determine_action(hand_has_item, slot_has_item)
	match action:
		ACTION_PICK:
			return _make_result(true, ACTION_PICK, "pick_allowed")
		ACTION_PUT:
			return _make_result(true, ACTION_PUT, "put_allowed")
		_:
			return _make_result(false, ACTION_NONE, "nothing_to_do")

func _determine_action(hand_item_present: bool, slot_item_present: bool) -> String:
	if not hand_item_present and not slot_item_present:
		return ACTION_NONE
	if not hand_item_present:
		return ACTION_PICK
	if not slot_item_present:
		return ACTION_PUT
	return ACTION_NONE

func _make_result(success: bool, action: String, reason: String) -> Dictionary:
	return {
		"success": success,
		"action": action,
		"reason": reason,
	}
