extends Node

const SAVE_PATH := "user://save_meta.json"
const DEFAULT_META := {
	"save_version": 1,
	"total_currency": 0,
	"unlocks": []
}

var _cached_meta: Dictionary = {}

func load_meta() -> Dictionary:
	if _cached_meta.is_empty():
		_cached_meta = _read_meta_from_disk()
	return _cached_meta.duplicate(true)

func save_meta(data: Dictionary) -> void:
	_cached_meta = DEFAULT_META.duplicate(true)
	for key in data.keys():
		_cached_meta[key] = data[key]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_cached_meta, "\t"))
		file.close()
		print("SaveManager: saved meta to", SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: save cleared")
	_cached_meta = DEFAULT_META.duplicate(true)

func _read_meta_from_disk() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		var json_text := FileAccess.get_file_as_string(SAVE_PATH)
		var parsed: Variant = JSON.parse_string(json_text)
		if typeof(parsed) == TYPE_DICTIONARY:
			var merged := DEFAULT_META.duplicate(true)
			for key in parsed.keys():
				merged[key] = parsed[key]
			print("SaveManager: meta loaded from disk")
			return merged
	print("SaveManager: no save found, using defaults")
	return DEFAULT_META.duplicate(true)
