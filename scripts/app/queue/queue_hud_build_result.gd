extends RefCounted

class_name QueueHudBuildResult

var snapshot: RefCounted
var timed_out_ids: Array[StringName] = []

func _init(result_snapshot: RefCounted, timeouts: Array[StringName]) -> void:
	snapshot = result_snapshot
	timed_out_ids = timeouts.duplicate()
