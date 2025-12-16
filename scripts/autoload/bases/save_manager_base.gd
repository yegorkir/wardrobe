class_name SaveManagerBase
extends Node

const META_SAVE_PATH := "user://save_meta.json"
const RUN_SAVE_PATH := "user://save_run.json"

const DEFAULT_META := {
	"save_version": 1,
	"total_currency": 0,
	"unlocks": []
}

const DEFAULT_RUN := {
	"save_version": 1,
	"shift_state": {}
}

var _cached_meta: Dictionary = {}
var _cached_run: Dictionary = {}

func load_meta() -> Dictionary:
	if _cached_meta.is_empty():
		_cached_meta = _read_meta_from_disk()
	return _cached_meta.duplicate(true)

func save_meta(data: Dictionary) -> void:
	_cached_meta = DEFAULT_META.duplicate(true)
	for key in data.keys():
		_cached_meta[key] = data[key]
	var file := FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_cached_meta, "\t"))
		file.close()
		print("SaveManager: saved meta to", META_SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(META_SAVE_PATH):
		DirAccess.remove_absolute(META_SAVE_PATH)
		print("SaveManager: meta save cleared")
	_cached_meta = DEFAULT_META.duplicate(true)
	clear_run_save()

func load_run_state() -> Dictionary:
	if _cached_run.is_empty():
		_cached_run = _read_run_from_disk()
	return _cached_run.duplicate(true)

func save_run_state(data: Dictionary) -> void:
	_cached_run = DEFAULT_RUN.duplicate(true)
	for key in data.keys():
		_cached_run[key] = data[key]
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_cached_run, "\t"))
		file.close()
		print("SaveManager: saved run state to", RUN_SAVE_PATH)

func clear_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)
		print("SaveManager: run save cleared")
	_cached_run = DEFAULT_RUN.duplicate(true)

func _read_meta_from_disk() -> Dictionary:
	if FileAccess.file_exists(META_SAVE_PATH):
		var json_text := FileAccess.get_file_as_string(META_SAVE_PATH)
		var parsed: Variant = JSON.parse_string(json_text)
		if typeof(parsed) == TYPE_DICTIONARY:
			var merged := DEFAULT_META.duplicate(true)
			for key in parsed.keys():
				merged[key] = parsed[key]
			print("SaveManager: meta loaded from disk")
			return merged
	print("SaveManager: no save found, using defaults")
	return DEFAULT_META.duplicate(true)

func _read_run_from_disk() -> Dictionary:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		var json_text := FileAccess.get_file_as_string(RUN_SAVE_PATH)
		var parsed: Variant = JSON.parse_string(json_text)
		if typeof(parsed) == TYPE_DICTIONARY:
			var merged := DEFAULT_RUN.duplicate(true)
			for key in parsed.keys():
				merged[key] = parsed[key]
			print("SaveManager: run state loaded from disk")
			return merged
	print("SaveManager: no run save found, using defaults")
	return DEFAULT_RUN.duplicate(true)
