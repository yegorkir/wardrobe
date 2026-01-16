extends RefCounted
class_name WorkdeskClientsUIAdapter

const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const DEFAULT_TEXTURE: Texture2D = preload("res://assets/sprites/placeholder/slot.png")
const DESK_ENTRY_DURATION := 0.7
const DESK_ENTRY_DELAY := 0.4
const DESK_ENTRY_OFFSET := 60.0
const DESK_ENTRY_SCALE := 0.5

class DeskClientView extends RefCounted:
	var client_visual: CanvasItem
	var patience_bg: Control
	var patience_fill: Control
	var patience_full_width: float = 0.0
	var base_position: Vector2 = Vector2.ZERO
	var base_scale: Vector2 = Vector2.ONE
	var _entry_tween: Tween
	var _has_base_transform := false

	func configure(
		client_node: CanvasItem,
		patience_bg_node: Control,
		patience_fill_node: Control
	) -> void:
		client_visual = client_node
		patience_bg = patience_bg_node
		patience_fill = patience_fill_node
		_cache_base_transform()
		if patience_bg:
			patience_full_width = patience_bg.size.x
		elif patience_fill:
			patience_full_width = patience_fill.size.x

	func set_client_visible(visible: bool) -> void:
		if client_visual:
			if not visible:
				_reset_client_visual()
			client_visual.visible = visible
		if patience_bg:
			patience_bg.visible = visible
		if patience_fill:
			patience_fill.visible = visible

	func set_client_texture(texture: Texture2D) -> void:
		if client_visual == null:
			return
		if client_visual is TextureRect:
			var rect := client_visual as TextureRect
			rect.texture = texture
			return
		if client_visual is Sprite2D:
			var sprite := client_visual as Sprite2D
			sprite.texture = texture

	func set_patience_ratio(ratio: float) -> void:
		if patience_fill == null:
			return
		var clamped := clampf(ratio, 0.0, 1.0)
		var width := patience_full_width
		if width <= 0.0:
			width = patience_fill.size.x
		patience_fill.size = Vector2(width * clamped, patience_fill.size.y)

	func play_entry_animation(delay: float) -> void:
		if client_visual == null:
			return
		if not _has_base_transform:
			_cache_base_transform()
		if _entry_tween and _entry_tween.is_valid():
			_entry_tween.kill()
		client_visual.position = base_position - Vector2(0.0, DESK_ENTRY_OFFSET)
		client_visual.scale = base_scale * DESK_ENTRY_SCALE
		var modulate := client_visual.modulate
		modulate.a = 0.0
		client_visual.modulate = modulate
		_entry_tween = client_visual.create_tween()
		if delay > 0.0:
			_entry_tween.tween_interval(delay)
		_entry_tween.tween_property(client_visual, "position", base_position, DESK_ENTRY_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_entry_tween.parallel().tween_property(client_visual, "scale", base_scale, DESK_ENTRY_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_entry_tween.parallel().tween_property(client_visual, "modulate:a", 1.0, DESK_ENTRY_DURATION)

	func _cache_base_transform() -> void:
		if client_visual == null:
			return
		base_position = client_visual.position
		base_scale = client_visual.scale
		_has_base_transform = true

	func _reset_client_visual() -> void:
		if client_visual == null:
			return
		if _entry_tween and _entry_tween.is_valid():
			_entry_tween.kill()
		if not _has_base_transform:
			_cache_base_transform()
		client_visual.position = base_position
		client_visual.scale = base_scale
		var modulate := client_visual.modulate
		modulate.a = 1.0
		client_visual.modulate = modulate

var _desks_by_id: Dictionary = {}
var _desk_states_by_id: Dictionary = {}
var _patience_by_client_id: Dictionary = {}
var _patience_max_by_client_id: Dictionary = {}
var _clients_by_id: Dictionary = {}
var _portrait_cache: Dictionary = {}
var _prev_client_by_desk_id: Dictionary = {}
var _initialized := false

func configure(
	desks_by_id: Dictionary,
	desk_states_by_id: Dictionary,
	patience_by_client_id: Dictionary,
	patience_max_by_client_id: Dictionary,
	clients_by_id_opt: Dictionary
) -> void:
	_desks_by_id = desks_by_id
	_desk_states_by_id = desk_states_by_id
	_patience_by_client_id = patience_by_client_id
	_patience_max_by_client_id = patience_max_by_client_id
	_clients_by_id = clients_by_id_opt
	_portrait_cache.clear()
	_prev_client_by_desk_id.clear()
	_initialized = false

func refresh() -> void:
	for desk_id in _desks_by_id.keys():
		var desk_view: DeskClientView = _desks_by_id.get(desk_id, null)
		if desk_view == null:
			continue
		var desk_state: RefCounted = _desk_states_by_id.get(desk_id, null)
		if desk_state == null:
			desk_view.set_client_visible(false)
			_prev_client_by_desk_id[desk_id] = StringName()
			continue
		var client_id: StringName = desk_state.current_client_id
		var previous_id: StringName = _prev_client_by_desk_id.get(desk_id, StringName())
		if client_id == StringName():
			desk_view.set_client_visible(false)
			_prev_client_by_desk_id[desk_id] = StringName()
			continue
		desk_view.set_client_visible(true)
		desk_view.set_client_texture(_resolve_client_portrait(client_id))
		if _initialized and previous_id != client_id:
			desk_view.play_entry_animation(DESK_ENTRY_DELAY)
		var patience_left := float(_patience_by_client_id.get(client_id, 0.0))
		var patience_max := float(_patience_max_by_client_id.get(client_id, 0.0))
		var ratio := 0.0
		if patience_max > 0.0:
			ratio = patience_left / patience_max
		desk_view.set_patience_ratio(ratio)
		_prev_client_by_desk_id[desk_id] = client_id
	_initialized = true

func _resolve_client_portrait(client_id: StringName) -> Texture2D:
	if _portrait_cache.has(client_id):
		return _portrait_cache[client_id]
	var client: RefCounted = _clients_by_id.get(client_id, null)
	if client == null or not (client is ClientStateScript):
		_portrait_cache[client_id] = DEFAULT_TEXTURE
		return DEFAULT_TEXTURE
	var client_state := client as ClientState
	var portrait_key := client_state.portrait_key
	if portrait_key == StringName():
		_portrait_cache[client_id] = DEFAULT_TEXTURE
		return DEFAULT_TEXTURE
	var key_text := String(portrait_key)
	var texture: Texture2D = DEFAULT_TEXTURE
	if key_text.begins_with("res://"):
		if ResourceLoader.exists(key_text):
			texture = load(key_text)
	else:
		var candidate := "res://assets/portraits/%s.png" % key_text
		if ResourceLoader.exists(candidate):
			texture = load(candidate)
	_portrait_cache[client_id] = texture
	return texture
