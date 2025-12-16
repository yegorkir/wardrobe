class_name ContentDBBase
extends Node

signal content_event(event_name, payload)

var _archetypes: Dictionary = {}
var _modifiers: Dictionary = {}
var _waves: Dictionary = {}
var _log_entries: Array = []

func _ready() -> void:
	_load_category("archetypes", _archetypes)
	_load_category("modifiers", _modifiers)
	_load_category("waves", _waves)
	_log_status()

func _load_category(category: String, target: Dictionary) -> void:
	var base_path := "res://content/%s" % category
	for file_name in DirAccess.get_files_at(base_path):
		if not file_name.ends_with(".json"):
			continue
		var path := "%s/%s" % [base_path, file_name]
		var json_text := FileAccess.get_file_as_string(path)
		var parsed: Variant = JSON.parse_string(json_text)
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("id"):
			target[parsed["id"]] = parsed
		else:
			push_warning("ContentDB: failed to parse %s" % path)
	_record_content_event("category_loaded", {
		"category": category,
		"count": target.size(),
	})

func _log_status() -> void:
	print("ContentDB: loaded %d archetypes, %d modifiers, %d waves" % [
		_archetypes.size(),
		_modifiers.size(),
		_waves.size()
	])
	_record_content_event("content_summary", {
		"archetypes": _archetypes.size(),
		"modifiers": _modifiers.size(),
		"waves": _waves.size(),
	})

func get_archetype(id: String) -> Dictionary:
	return _archetypes.get(id, {})

func get_modifier(id: String) -> Dictionary:
	return _modifiers.get(id, {})

func get_wave(id: String) -> Dictionary:
	return _waves.get(id, {})

func get_log_entries() -> Array:
	return _log_entries.duplicate(true)

func _record_content_event(event_name: String, payload: Dictionary) -> void:
	var entry := {
		"event": event_name,
		"payload": payload.duplicate(true),
	}
	_log_entries.append(entry)
	var payload_copy: Dictionary = entry["payload"].duplicate(true)
	emit_signal("content_event", event_name, payload_copy)
