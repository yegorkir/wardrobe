class_name ContentDBBase
extends Node

var _archetypes: Dictionary = {}
var _modifiers: Dictionary = {}
var _waves: Dictionary = {}

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

func _log_status() -> void:
	print("ContentDB: loaded %d archetypes, %d modifiers, %d waves" % [
		_archetypes.size(),
		_modifiers.size(),
		_waves.size()
	])

func get_archetype(id: String) -> Dictionary:
	return _archetypes.get(id, {})

func get_modifier(id: String) -> Dictionary:
	return _modifiers.get(id, {})

func get_wave(id: String) -> Dictionary:
	return _waves.get(id, {})
