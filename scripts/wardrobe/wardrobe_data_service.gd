extends RefCounted

class_name WardrobeDataService

var _content_db: ContentDBBase
var _best_results_path := ""
var _default_seed_id := ""
var _fallback_seed_table: Array = []

func _init(
	content_db: ContentDBBase,
	best_results_path: String,
	default_seed_id: String,
	fallback_seed_table: Array
) -> void:
	_content_db = content_db
	_best_results_path = best_results_path
	_default_seed_id = default_seed_id
	_fallback_seed_table = fallback_seed_table.duplicate(true)

func load_challenge_definition(challenge_id: String, warn_on_missing := false) -> Dictionary:
	if _content_db == null:
		if warn_on_missing:
			push_warning("ContentDB unavailable; challenge cannot load (id=%s)" % challenge_id)
		return {}
	var definition := _content_db.get_challenge(challenge_id)
	if definition.is_empty():
		if warn_on_missing:
			push_warning("Challenge definition missing: %s" % challenge_id)
		return {}
	var payload_variant: Variant = definition.get("payload", {})
	if payload_variant is Dictionary:
		var payload := payload_variant as Dictionary
		if not payload.has("id"):
			payload["id"] = definition.get("id", StringName())
		return payload.duplicate(true)
	if warn_on_missing:
		push_warning("Challenge definition payload missing: %s" % challenge_id)
	return {}

func load_seed_entries() -> Array:
	if _content_db:
		var entries := _content_db.get_seed_items(_default_seed_id)
		if entries.size() > 0:
			return entries
	return _fallback_seed_table.duplicate(true)

func load_best_results() -> Dictionary:
	var parsed: Variant = _read_json_dictionary(_best_results_path, "Best results", false, false)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func save_best_results(data: Dictionary) -> void:
	var file := FileAccess.open(_best_results_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func _read_json_dictionary(
	path: String,
	context: String,
	warn_on_missing := true,
	warn_on_empty := true
) -> Variant:
	if not FileAccess.file_exists(path):
		if warn_on_missing:
			push_warning("%s missing: %s" % [context, path])
		return null
	var raw_text := FileAccess.get_file_as_string(path)
	if raw_text.is_empty():
		if warn_on_empty:
			push_warning("%s empty: %s" % [context, path])
		return null
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("%s JSON invalid: %s" % [context, path])
		return null
	return parsed
