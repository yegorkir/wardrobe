extends RefCounted

class_name WardrobeShiftLog

const ShiftLogEntryScript := preload("res://scripts/app/logging/shift_log_entry.gd")

var _events: Array[ShiftLogEntryScript] = []

func record(event_type: StringName, payload: Dictionary = {}) -> void:
	var entry := ShiftLogEntryScript.new(event_type, payload)
	_events.append(entry)
	if event_type == &"VAMPIRE_STAGE_COMPLETE":
		var item_id: StringName = payload.get(&"item_id", StringName())
		var stage: int = int(payload.get(&"stage", 0))
		var loss: int = int(payload.get(&"loss", 0))
		var sources: Array = payload.get(&"sources", [])
		print("VAMPIRE_STAGE_COMPLETE item=%s stage=%d loss=%d sources=%s" % [item_id, stage, loss, sources])
	elif event_type == &"ZOMBIE_STAGE_COMPLETE":
		var zombie_item_id: StringName = payload.get(&"item_id", StringName())
		var zombie_stage: int = int(payload.get(&"stage", 0))
		var zombie_loss: int = int(payload.get(&"loss", 0))
		var rate: float = float(payload.get(&"rate", 0.0))
		print("ZOMBIE_STAGE_COMPLETE item=%s stage=%d loss=%d rate=%.2f" % [zombie_item_id, zombie_stage, zombie_loss, rate])

func get_events() -> Array[ShiftLogEntryScript]:
	return _events.duplicate(true)

func clear() -> void:
	_events.clear()
