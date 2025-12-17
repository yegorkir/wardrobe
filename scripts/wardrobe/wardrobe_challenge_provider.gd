extends Resource

class_name WardrobeChallengeProvider

const WardrobeDataServiceScript := preload("res://scripts/wardrobe/wardrobe_data_service.gd")
const WardrobeChallengeConfigScript := preload("res://scripts/wardrobe/wardrobe_challenge_config.gd")

@export var challenge_config: Resource

var _data_service
var _content_db: ContentDBBase

func get_default_challenge_id() -> String:
	var config: Resource = _ensure_config()
	return config.default_challenge_id if config else ""

func load_challenge_definition(challenge_id: String) -> Dictionary:
	var service: Variant = _ensure_service()
	return service.load_challenge_definition(challenge_id) if service else {}

func load_best_results() -> Dictionary:
	var service: Variant = _ensure_service()
	return service.load_best_results() if service else {}

func save_best_results(data: Dictionary) -> void:
	var service: Variant = _ensure_service()
	if service:
		service.save_best_results(data)

func load_seed_entries() -> Array:
	var service: Variant = _ensure_service()
	return service.load_seed_entries() if service else []

func ensure_ready() -> void:
	_ensure_service()

func set_content_db(db: ContentDBBase) -> void:
	if _content_db != db:
		_content_db = db
		_data_service = null

func _ensure_service() -> Variant:
	if _data_service == null:
		var config: Resource = _ensure_config()
		if config == null:
			return null
		_data_service = WardrobeDataServiceScript.new(
			_content_db,
			config.best_results_path,
			config.default_seed_id,
			config.fallback_seed_table
		)
	return _data_service

func _ensure_config() -> Resource:
	if challenge_config == null or challenge_config.get_script() != WardrobeChallengeConfigScript:
		challenge_config = WardrobeChallengeConfigScript.new()
	return challenge_config
