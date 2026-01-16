extends RefCounted
class_name WorkdeskClientsUIAdapter

const ClientStateScript := preload("res://scripts/domain/clients/client_state.gd")
const DEFAULT_TEXTURE: Texture2D = preload("res://assets/sprites/placeholder/slot.png")
const DESK_ENTRY_DURATION := 0.7
const DESK_ENTRY_DELAY := 0.4
const DESK_ENTRY_OFFSET := 60.0
const DESK_ENTRY_SCALE := 0.5
const DESK_EXIT_DURATION := 0.45
const DESK_EXIT_OFFSET := 70.0
const DESK_EXIT_SCALE := 0.5

class DeskClientView extends RefCounted:
	var client_visual: CanvasItem
	var patience_bg: Control
	var patience_fill: Control
	var patience_full_width: float = 0.0
	var base_position: Vector2 = Vector2.ZERO
	var base_scale: Vector2 = Vector2.ONE
	var _entry_tween: Tween
	var _exit_tween: Tween
	var _has_base_transform := false
	var _exit_in_progress := false

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
		_exit_in_progress = false
		if _exit_tween and _exit_tween.is_valid():
			_exit_tween.kill()
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

	func play_exit_animation(on_finished: Callable) -> void:
		if client_visual == null:
			return
		if not _has_base_transform:
			_cache_base_transform()
		_exit_in_progress = true
		if _entry_tween and _entry_tween.is_valid():
			_entry_tween.kill()
		if _exit_tween and _exit_tween.is_valid():
			_exit_tween.kill()
		_exit_tween = client_visual.create_tween()
		_exit_tween.tween_property(
			client_visual,
			"position",
			base_position + Vector2(-DESK_EXIT_OFFSET, 0.0),
			DESK_EXIT_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_exit_tween.parallel().tween_property(
			client_visual,
			"scale",
			base_scale * DESK_EXIT_SCALE,
			DESK_EXIT_DURATION
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_exit_tween.parallel().tween_property(client_visual, "modulate:a", 0.0, DESK_EXIT_DURATION)
		if on_finished.is_valid():
			_exit_tween.tween_callback(on_finished)

	func is_exit_in_progress() -> bool:
		return _exit_in_progress

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
		if _exit_tween and _exit_tween.is_valid():
			_exit_tween.kill()
		_exit_in_progress = false
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
var _desk_id_by_client_id: Dictionary = {}
var _exit_block_by_desk_id: Dictionary = {}
var _exiting_client_by_desk_id: Dictionary = {}
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
	_desk_id_by_client_id.clear()
	_exit_block_by_desk_id.clear()
	_exiting_client_by_desk_id.clear()
	_initialized = false

func refresh() -> void:
	for desk_id in _desks_by_id.keys():
		var desk_view: DeskClientView = _desks_by_id.get(desk_id, null)
		if desk_view == null:
			continue
		var previous_id: StringName = _prev_client_by_desk_id.get(desk_id, StringName())
		var desk_state: RefCounted = _desk_states_by_id.get(desk_id, null)
		if desk_state == null:
			if not _is_exit_blocked(desk_id):
				desk_view.set_client_visible(false)
				if previous_id != StringName() and _desk_id_by_client_id.get(previous_id, StringName()) == desk_id:
					_desk_id_by_client_id.erase(previous_id)
			_prev_client_by_desk_id[desk_id] = StringName()
			continue
		var client_id: StringName = desk_state.current_client_id
		if client_id == StringName():
			if not _is_exit_blocked(desk_id):
				desk_view.set_client_visible(false)
				if previous_id != StringName() and _desk_id_by_client_id.get(previous_id, StringName()) == desk_id:
					_desk_id_by_client_id.erase(previous_id)
			_prev_client_by_desk_id[desk_id] = StringName()
			continue
		if _is_exit_blocked(desk_id):
			var exiting_id: StringName = _exiting_client_by_desk_id.get(desk_id, StringName())
			if exiting_id != client_id:
				_exit_block_by_desk_id.erase(desk_id)
				_exiting_client_by_desk_id.erase(desk_id)
		_desk_id_by_client_id[client_id] = desk_id
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

func notify_client_completed(client_id: StringName) -> void:
	notify_client_departed(client_id)

func notify_client_departed(client_id: StringName) -> void:
	if client_id == StringName():
		return
	var desk_id: StringName = _desk_id_by_client_id.get(client_id, StringName())
	if desk_id == StringName():
		return
	if _exit_block_by_desk_id.get(desk_id, false):
		return
	var desk_view: DeskClientView = _desks_by_id.get(desk_id, null)
	if desk_view == null:
		return
	_exit_block_by_desk_id[desk_id] = true
	_exiting_client_by_desk_id[desk_id] = client_id
	if desk_view.patience_bg:
		desk_view.patience_bg.visible = false
	if desk_view.patience_fill:
		desk_view.patience_fill.visible = false
	desk_view.play_exit_animation(Callable(self, "_on_exit_finished").bind(desk_id, client_id))

func is_exit_blocked(desk_id: StringName) -> bool:
	return _is_exit_blocked(desk_id)

func _is_exit_blocked(desk_id: StringName) -> bool:
	return bool(_exit_block_by_desk_id.get(desk_id, false))

func _on_exit_finished(desk_id: StringName, client_id: StringName) -> void:
	_exit_block_by_desk_id.erase(desk_id)
	_exiting_client_by_desk_id.erase(desk_id)
	if _desk_id_by_client_id.get(client_id, StringName()) == desk_id:
		_desk_id_by_client_id.erase(client_id)
	var desk_view: DeskClientView = _desks_by_id.get(desk_id, null)
	if desk_view == null:
		return
	desk_view.set_client_visible(false)

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
