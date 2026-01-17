extends RefCounted

class_name ClientSpawnRequest

enum Type {
	CHECKIN,
	CHECKOUT
}

var type: Type
var reason: String

func _init(p_type: Type, p_reason: String = "") -> void:
	type = p_type
	reason = p_reason
