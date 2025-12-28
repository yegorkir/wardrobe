extends RefCounted
class_name WardrobeDebugLog

const DebugFlags := preload("res://scripts/wardrobe/config/debug_flags.gd")

static func enabled() -> bool:
	return DebugFlags.enabled

static func log(message: String) -> void:
	if not DebugFlags.enabled:
		return
	print("[Wardrobe] %s" % message)

static func logf(format: String, args: Array) -> void:
	if not DebugFlags.enabled:
		return
	print("[Wardrobe] %s" % (format % args))

static func event(event_type: StringName, payload: Dictionary) -> void:
	if not DebugFlags.enabled:
		return
	print("[Wardrobe] %s %s" % [event_type, payload])
