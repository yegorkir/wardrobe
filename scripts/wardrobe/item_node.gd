class_name ItemNode
extends RigidBody2D

const PhysicsLayers := preload("res://scripts/wardrobe/config/physics_layers.gd")
const DebugLog := preload("res://scripts/wardrobe/debug/debug_log.gd")
const DebugFlags := preload("res://scripts/wardrobe/config/debug_flags.gd")
const EventSchema := preload("res://scripts/domain/events/event_schema.gd")
const LOG_TRANSFER_ENABLED := false
const LOG_TRANSFER_END_ENABLED := false
const LOG_UNSTABLE_POS_ENABLED := false

enum ItemType {
	COAT,
	TICKET,
	ANCHOR_TICKET,
	BOTTLE,
	CHEST,
	HAT,
}

const DEFAULT_MASS_BY_TYPE: Dictionary = {
	ItemType.COAT: 1.2,
	ItemType.TICKET: 0.5,
	ItemType.ANCHOR_TICKET: 0.7,
	ItemType.BOTTLE: 0.6,
	ItemType.CHEST: 3.0,
	ItemType.HAT: 0.6,
}

enum State {
	STABLE,
	DRAGGING,
	SETTLING,
}

enum TransferPhase {
	NONE,
	RISING_THROUGH,
	FALLING_TO_TARGET,
}

enum FloorTransferMode {
	RISE_THEN_FALL,
	FALL_ONLY,
}

enum DropReason {
	NONE,
	REJECT,
}

const COLLISION_PADDING := 2.0
const SETTLE_LINEAR_THRESHOLD := 6.0
const SETTLE_ANGULAR_THRESHOLD := 0.4
const SETTLE_REQUIRED_TIME := 1.0
const SUPPORT_RAY_LENGTH := 48.0
const SETTLE_GRACE_FRAMES := 2
const DEFAULT_COLLISION_LAYER := PhysicsLayers.LAYER_ITEM_BIT
const DEFAULT_COLLISION_MASK := PhysicsLayers.MASK_ITEM_DEFAULT
const SHELFED_COLLISION_MASK := PhysicsLayers.MASK_ITEM_SHELFED
const TRANSFER_RISE_COLLISION_LAYER := 0
const TRANSFER_RISE_COLLISION_MASK := 0
const TRANSFER_FALL_COLLISION_LAYER := PhysicsLayers.LAYER_TRANSFER_FALL_BIT
const TRANSFER_FALL_COLLISION_MASK := PhysicsLayers.MASK_TRANSFER_FALL_ONLY
const PASS_THROUGH_PICK_SCALE := 1.6
const TRANSFER_RISE_SPEED := 520.0
const TRANSFER_FALL_MIN_SPEED := 60.0
const TRANSFER_TARGET_EPS := 0.5
const TRANSFER_RISE_EPS := 2.0
const TRANSFER_SUPPORT_RAY_LENGTH := 12.0
const TRANSFER_FORCE_LAND_FRAMES := 6
const TRANSFER_FAILSAFE_FRAMES := 12
const TRANSFER_SINK_LOG_FRAMES := 6

@export var item_id: String = ""
@export var item_type: ItemType = ItemType.COAT
@export var item_mass: float = 0.0
@export var cog_offset: Vector2 = Vector2.ZERO

var ticket_number: int = -1
var durability: float = 100.0

var _item_instance: RefCounted
var _aura_particles: GPUParticles2D
var _smoke_particles: GPUParticles2D
var _sparks_particles: GPUParticles2D
var _burn_overlay: Sprite2D
var _aura_debug_ring: Line2D

# Transfer effect metadata structure
class TransferEffectData:
	var node: GPUParticles2D
	var progress: float = 0.0
	var target_local_pos: Vector2 = Vector2.ZERO
	var target_radius: float = 0.0
	var is_returning: bool = false
	
	func _init(p_node: GPUParticles2D) -> void:
		node = p_node

var _transfer_effects: Dictionary = {} # target_id -> TransferEffectData
const TRANSFER_RETURN_SPEED := 2.0
const AURA_DENSITY_FACTOR := 0.02
const MIN_AURA_PARTICLES := 1

@onready var _pick_shape: CollisionShape2D = $PickArea/CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite
@onready var _physics_shape: CollisionShape2D = get_node_or_null("PhysicsShape") as CollisionShape2D

var _physics_tick
var _settle_time := 0.0
var _is_dragging := false
var _state: int = State.STABLE
var _settle_grace_frames := 0
var _pass_through_active := false
var _pass_through_until_y := 0.0
var _pass_through_restore_layer := 0
var _pass_through_restore_mask := 0
var _pick_default_size := Vector2.ZERO
var _reject_falling := false
var last_drop_reason: DropReason = DropReason.NONE
var current_surface: Node
var _transfer_phase: int = TransferPhase.NONE
var _transfer_mode: int = FloorTransferMode.FALL_ONLY
var _transfer_target_y := 0.0
var _transfer_restore_layer := 0
var _transfer_restore_mask := 0
var _transfer_restore_gravity_scale := 1.0
var _transfer_crossed_frames := 0
var _transfer_fall_frames := 0
var _transfer_sink_frames := 0
var _transfer_sink_logged := false
var _landing_cause: StringName = EventSchema.CAUSE_ACCIDENT
var _landing_armed := true
var _stored_landing_impact: float = 0.0

const PASS_THROUGH_RESTORE_EPS := 0.5

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	_apply_mass_defaults()
	mass = maxf(0.1, item_mass)
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = DEFAULT_COLLISION_MASK
	_prepare_pick_area()
	_cache_default_pick_size()
	_prepare_physics_shape()
	_apply_physics_material()
	_update_center_of_mass()
	body_entered.connect(_on_body_entered)

func set_item_instance(instance: RefCounted) -> void:
	_item_instance = instance

func get_item_instance() -> RefCounted:
	return _item_instance

func get_item_radius() -> float:
	return maxf(get_visual_half_width(), get_visual_half_height())

func set_burn_damage(damage_ratio: float) -> void:
	# damage_ratio: 0.0 (clean) -> 1.0 (fully burnt)
	if _burn_overlay == null and damage_ratio > 0.0:
		_create_burn_overlay()
	
	if _burn_overlay != null:
		_burn_overlay.visible = damage_ratio > 0.0
		# Map ratio to opacity, but keep it subtle at first
		_burn_overlay.modulate.a = clampf(damage_ratio * 0.8, 0.0, 0.9)

func _create_burn_overlay() -> void:
	if _sprite == null: return
	
	_burn_overlay = Sprite2D.new()
	_burn_overlay.name = "BurnOverlay"
	
	# Generate texture matching the item size
	var base_tex = _sprite.texture
	if base_tex:
		var size = base_tex.get_size()
		var img = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		
		var noise = FastNoiseLite.new()
		noise.seed = randi()
		noise.frequency = 0.02 # Much lower frequency for larger blotches
		noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		noise.fractal_octaves = 2 # Less detail inside blotches
		
		# Draw burn marks only where the original sprite is visible (alpha > 0)
		var base_img = base_tex.get_image()
		if base_img:
			for y in range(size.y):
				for x in range(size.x):
					if base_img.get_pixel(x, y).a > 0.1:
						var n = noise.get_noise_2d(x, y)
						if n > 0.1: # Lower threshold to catch more area
							# Dark char color
							img.set_pixel(x, y, Color(0.1, 0.05, 0.05, 0.95))
		
		_burn_overlay.texture = ImageTexture.create_from_image(img)
		_burn_overlay.scale = _sprite.scale
		_burn_overlay.position = _sprite.position
		_burn_overlay.centered = _sprite.centered
		_burn_overlay.offset = _sprite.offset
		
		add_child(_burn_overlay)
		# Place it right above the sprite but below physics shapes if possible
		move_child(_burn_overlay, _sprite.get_index() + 1)

func set_burning(enabled: bool) -> void:
	if enabled:
		if _smoke_particles == null:
			_create_burning_effects()
		
		# Update emission shapes to match current sprite size
		if _sprite and _sprite.texture:
			var size = _sprite.texture.get_size() * _sprite.scale
			var half_size = size * 0.5
			
			# Sparks: Cover entire sprite
			var spark_mat = _sparks_particles.process_material as ParticleProcessMaterial
			if spark_mat:
				spark_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
				spark_mat.emission_box_extents = Vector3(half_size.x, half_size.y, 1.0)
			
			# Smoke: Top half only, slightly wider
			var smoke_mat = _smoke_particles.process_material as ParticleProcessMaterial
			if smoke_mat:
				smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
				# x: full width, y: top part only
				smoke_mat.emission_box_extents = Vector3(half_size.x * 0.8, half_size.y * 0.4, 1.0)
				# Offset smoke emitter to the top of the sprite
				_smoke_particles.position = Vector2(0, -half_size.y * 0.5)
		
		_smoke_particles.emitting = true
		_sparks_particles.emitting = true
	else:
		if _smoke_particles != null:
			_smoke_particles.emitting = false
			_sparks_particles.emitting = false

func set_emitting_aura(enabled: bool, radius: float = -1.0) -> void:
	if enabled:
		if _aura_particles == null:
			_create_aura_particles()
		if radius > 0.0:
			_set_aura_radius(radius)
			_set_aura_debug_ring_radius(radius)
			
			# Dynamic density: more particles for larger radius
			var new_amount = max(MIN_AURA_PARTICLES, int(radius * AURA_DENSITY_FACTOR))
			if _aura_particles.amount != new_amount:
				_aura_particles.amount = new_amount
				
		if DebugFlags.enabled:
			_show_aura_debug_ring(true)
		_aura_particles.emitting = true
	else:
		if _aura_particles != null:
			_aura_particles.emitting = false
		_show_aura_debug_ring(false)

func _create_burning_effects() -> void:
	# 1. Smoke
	_smoke_particles = GPUParticles2D.new()
	_smoke_particles.name = "SmokeParticles"
	
	var smoke_mat = ParticleProcessMaterial.new()
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_mat.emission_sphere_radius = 16.0
	smoke_mat.gravity = Vector3(0, -40, 0) # Rise up
	smoke_mat.direction = Vector3(0, -1, 0)
	smoke_mat.spread = 20.0
	smoke_mat.initial_velocity_min = 10.0
	smoke_mat.initial_velocity_max = 30.0
	smoke_mat.scale_min = 2.0
	smoke_mat.scale_max = 6.0
	# Dark grey smoke, fading out
	smoke_mat.color = Color(0.2, 0.2, 0.2, 0.6)
	smoke_mat.color_ramp = _create_fade_out_gradient()
	
	_smoke_particles.process_material = smoke_mat
	_smoke_particles.amount = 96 # Tripled
	_smoke_particles.lifetime = 1.5
	_smoke_particles.local_coords = true
	add_child(_smoke_particles)
	
	# 2. Sparks
	_sparks_particles = GPUParticles2D.new()
	_sparks_particles.name = "SparksParticles"
	
	var spark_mat = ParticleProcessMaterial.new()
	spark_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_mat.emission_sphere_radius = 14.0
	spark_mat.gravity = Vector3(0, 98, 0) # Sparks fall/fly
	spark_mat.direction = Vector3(0, -1, 0)
	spark_mat.spread = 120.0 # Explode outwards/up
	spark_mat.initial_velocity_min = 40.0
	spark_mat.initial_velocity_max = 100.0
	spark_mat.damping_min = 10.0
	spark_mat.scale_min = 1.5
	spark_mat.scale_max = 2.5
	spark_mat.color = Color(1.0, 0.6, 0.1, 1.0) # Orange/Yellow
	
	_sparks_particles.process_material = spark_mat
	_sparks_particles.amount = 48 # Tripled
	_sparks_particles.lifetime = 0.6
	_sparks_particles.explosiveness = 0.2
	_sparks_particles.local_coords = true
	add_child(_sparks_particles)

func _create_fade_out_gradient() -> GradientTexture1D:
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0)) # Fade to transparent
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	return tex

func update_transfer_effect(target_id: StringName, target_global_pos: Vector2, progress: float, target_item_radius: float) -> void:
	var data: TransferEffectData
	if _transfer_effects.has(target_id):
		data = _transfer_effects[target_id]
	else:
		var node = _create_transfer_particle_node()
		add_child(node)
		data = TransferEffectData.new(node)
		_transfer_effects[target_id] = data
	
	data.is_returning = false
	data.progress = progress
	data.target_local_pos = to_local(target_global_pos)
	data.target_radius = target_item_radius
	
	_update_effect_visuals(data)

func clear_unused_transfers(active_ids: Array) -> void:
	for id in _transfer_effects:
		if not id in active_ids:
			var data = _transfer_effects[id] as TransferEffectData
			data.is_returning = true

func _process_transfer_effects(delta: float) -> void:
	if _transfer_effects.is_empty():
		return
		
	var to_remove: Array = []
	for id in _transfer_effects:
		var data = _transfer_effects[id] as TransferEffectData
		if data.is_returning:
			data.progress -= delta * TRANSFER_RETURN_SPEED
			if data.progress <= 0.0:
				data.node.queue_free()
				to_remove.append(id)
			else:
				_update_effect_visuals(data)
	
	for id in to_remove:
		_transfer_effects.erase(id)

func _update_effect_visuals(data: TransferEffectData) -> void:
	data.node.position = Vector2.ZERO.lerp(data.target_local_pos, data.progress)
	
	var source_radius := 24.0
	if _aura_particles:
		var aura_mat = _aura_particles.process_material as ParticleProcessMaterial
		if aura_mat:
			source_radius = aura_mat.emission_sphere_radius
	
	# Target emission radius is 90% of the target item radius
	var target_radius_effective = data.target_radius * 0.9
	
	var effect_mat = data.node.process_material as ParticleProcessMaterial
	if effect_mat:
		effect_mat.emission_sphere_radius = lerpf(source_radius, target_radius_effective, data.progress)

func _create_transfer_particle_node() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "TransferParticles"
	
	# Use fly texture
	particles.texture = _generate_fly_texture()
	
	# Use shared fly material logic
	var proc_mat = _create_fly_process_material()
	
	# Transfer specific adjustments
	proc_mat.color = Color(1.0, 1.0, 1.0, 0.5) # Semi-transparent flies for transfer
	proc_mat.gravity = Vector3(0, -5, 0) # Gentle rise for transfer visual
	proc_mat.radial_accel_min = 0.0 # No attraction for transfer
	proc_mat.radial_accel_max = 0.0
	proc_mat.orbit_velocity_min = 0.0
	proc_mat.orbit_velocity_max = 0.0
	proc_mat.damping_min = 2.0
	proc_mat.damping_max = 5.0
	
	particles.process_material = proc_mat
	particles.amount = 4 # A small group of flies moving
	particles.lifetime = 0.8
	particles.local_coords = true
	
	return particles

func _create_aura_particles() -> void:
	_aura_particles = GPUParticles2D.new()
	_aura_particles.name = "AuraParticles"
	
	# Create fly texture procedurally
	_aura_particles.texture = _generate_fly_texture()
	
	var proc_mat = _create_fly_process_material()
	
	# Aura specific adjustments (already set in helper, but explicit here for clarity if needed)
	# Keeping them confined and orbiting
	
	_aura_particles.process_material = proc_mat
	_aura_particles.amount = 1 # Only one fly at a time
	_aura_particles.lifetime = 4.5 # Lives 3x longer
	_aura_particles.local_coords = true
	
	add_child(_aura_particles)
	move_child(_aura_particles, 0)

func _create_fly_process_material() -> ParticleProcessMaterial:
	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 24.0
	
	# Swarm behavior (hovering/buzzing)
	proc_mat.gravity = Vector3.ZERO # No gravity, keep them local
	proc_mat.direction = Vector3(0, -1, 0)
	proc_mat.spread = 180.0 # Emit in all directions
	
	# Fast movement
	proc_mat.initial_velocity_min = 40.0
	proc_mat.initial_velocity_max = 100.0
	proc_mat.damping_min = 5.0
	proc_mat.damping_max = 10.0
	
	# Keep them inside: Orbit + Attraction to center
	proc_mat.orbit_velocity_min = 0.2
	proc_mat.orbit_velocity_max = 0.5
	proc_mat.radial_accel_min = -60.0
	proc_mat.radial_accel_max = -30.0
	
	# Rotation for realistic movement
	proc_mat.angle_min = -180.0
	proc_mat.angle_max = 180.0
	proc_mat.angular_velocity_min = -400.0
	proc_mat.angular_velocity_max = 400.0
	
	# Use white so the texture colors (black/gray) are preserved
	proc_mat.color = Color.WHITE
	
	# Scale curve: starts small, peaks at mid-life, ends small
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.0)) # pos 0.0, value 0.0
	scale_curve.add_point(Vector2(0.5, 1.0)) # pos 0.5, value 1.0
	scale_curve.add_point(Vector2(1.0, 0.0)) # pos 1.0, value 0.0
	
	var scale_tex := CurveTexture.new()
	scale_tex.curve = scale_curve
	proc_mat.scale_curve = scale_tex
	
	proc_mat.scale_min = 2.0
	proc_mat.scale_max = 3.0
	
	return proc_mat

func _generate_fly_texture() -> ImageTexture:
	var w := 8
	var h := 8
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	var body_color := Color.BLACK
	var wing_color := Color(0.5, 0.5, 0.5, 0.8) # Grey, slightly transparent
	
	# Draw Body (Vertical block in center)
	for y in range(3, 7):
		img.set_pixel(3, y, body_color)
		img.set_pixel(4, y, body_color)
	
	# Draw Wings (Angled pixels)
	# Left wing
	img.set_pixel(1, 2, wing_color)
	img.set_pixel(2, 3, wing_color)
	img.set_pixel(2, 4, wing_color)
	
	# Right wing
	img.set_pixel(6, 2, wing_color)
	img.set_pixel(5, 3, wing_color)
	img.set_pixel(5, 4, wing_color)
	
	return ImageTexture.create_from_image(img)

func _set_aura_radius(radius: float) -> void:
	if _aura_particles == null:
		return
	if _aura_particles.process_material is ParticleProcessMaterial:
		var material := _aura_particles.process_material as ParticleProcessMaterial
		# Match the aura radius more closely visually (90%)
		material.emission_sphere_radius = radius * 0.9

func _show_aura_debug_ring(show_ring: bool) -> void:
	if not DebugFlags.enabled:
		if _aura_debug_ring != null:
			_aura_debug_ring.visible = false
		return
	if _aura_debug_ring == null and show_ring:
		_create_aura_debug_ring()
	if _aura_debug_ring != null:
		_aura_debug_ring.visible = show_ring

func _create_aura_debug_ring() -> void:
	_aura_debug_ring = Line2D.new()
	_aura_debug_ring.name = "AuraDebugRing"
	_aura_debug_ring.width = 2.0
	_aura_debug_ring.default_color = Color(0.2, 1.0, 0.2, 0.6)
	add_child(_aura_debug_ring)
	move_child(_aura_debug_ring, 0)

func _set_aura_debug_ring_radius(radius: float) -> void:
	if _aura_debug_ring == null:
		return
	var points: PackedVector2Array = []
	var segments := 64
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_aura_debug_ring.points = points

func _physics_process(delta: float) -> void:
	_process_transfer_effects(delta)
	if _transfer_phase != TransferPhase.NONE:
		_settle_time = 0.0
		return
	_log_unstable_position()
	if _pass_through_active:
		if get_bottom_y_global() >= _pass_through_until_y - PASS_THROUGH_RESTORE_EPS:
			_restore_pass_through()
	if freeze or _is_dragging:
		_settle_time = 0.0
		return
	if _settle_grace_frames > 0:
		_settle_grace_frames -= 1
		return
	if abs(linear_velocity.length()) <= SETTLE_LINEAR_THRESHOLD and abs(angular_velocity) <= SETTLE_ANGULAR_THRESHOLD:
		_settle_time += delta
		if _settle_time >= SETTLE_REQUIRED_TIME:
			_settle_time = 0.0
			var tick = _resolve_physics_tick()
			if tick:
				tick.request_settle_check(self)
	else:
		_settle_time = 0.0

func is_dragging() -> bool:
	return _is_dragging

func attach_to_anchor(anchor: Node2D) -> void:
	if anchor == null:
		return
	if get_parent():
		reparent(anchor)
	else:
		anchor.add_child(self)
	global_position = anchor.global_position
	global_rotation = 0.0
	global_scale = Vector2.ONE
	position = Vector2.ZERO

func get_pick_half_width() -> float:
	if _pick_shape and _pick_shape.shape is RectangleShape2D:
		return (_pick_shape.shape as RectangleShape2D).size.x * 0.5
	if _pick_shape and _pick_shape.shape is CircleShape2D:
		return (_pick_shape.shape as CircleShape2D).radius
	return 16.0

func get_pick_half_height() -> float:
	if _pick_shape and _pick_shape.shape is RectangleShape2D:
		return (_pick_shape.shape as RectangleShape2D).size.y * 0.5
	if _pick_shape and _pick_shape.shape is CircleShape2D:
		return (_pick_shape.shape as CircleShape2D).radius
	return 16.0

func configure_pick_box(size_px: float) -> void:
	if _pick_shape == null:
		return
	var rect_shape := _pick_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	rect_shape.size = Vector2(size_px, size_px)

func configure_pick_box_from_sprite() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	if _pick_shape == null:
		return
	var rect_shape := _pick_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	var size := _sprite.texture.get_size() * _sprite.scale
	rect_shape.size = size

func refresh_physics_shape_from_sprite() -> void:
	if _physics_shape == null or _physics_shape.shape == null:
		return
	if _physics_shape.shape is RectangleShape2D:
		var rect := _physics_shape.shape as RectangleShape2D
		var size := _resolve_sprite_size()
		if size != Vector2.ZERO:
			rect.size = Vector2(maxf(2.0, size.x - COLLISION_PADDING), maxf(2.0, size.y - COLLISION_PADDING))
			_update_center_of_mass()

func get_visual_half_width() -> float:
	if _sprite == null or _sprite.texture == null:
		return get_pick_half_width()
	return _sprite.texture.get_size().x * _sprite.scale.x * 0.5

func get_visual_half_height() -> float:
	if _sprite == null or _sprite.texture == null:
		return get_pick_half_height()
	return _sprite.texture.get_size().y * _sprite.scale.y * 0.5

func get_global_cog() -> Vector2:
	return global_transform * center_of_mass

func get_support_ray_length() -> float:
	return SUPPORT_RAY_LENGTH

func get_physics_shape_query() -> Dictionary:
	if _physics_shape == null:
		return {}
	if _physics_shape.shape == null:
		return {}
	return {
		"shape": _physics_shape.shape,
		"transform": _physics_shape.global_transform,
	}

func get_global_bottom_y() -> float:
	return get_bottom_y_global()

func get_collider_aabb_global() -> Rect2:
	if _physics_shape == null or _physics_shape.shape == null:
		return _get_sprite_aabb()
	var shape := _physics_shape.shape as Shape2D
	var shape_transform := _physics_shape.global_transform
	return _get_shape_aabb(shape, shape_transform)

func get_bottom_y_global() -> float:
	var rect := get_collider_aabb_global()
	if rect.size != Vector2.ZERO:
		return rect.position.y + rect.size.y
	return global_position.y + get_visual_half_height()

func snap_to_surface(hit_position: Vector2, epsilon: float) -> void:
	if not freeze:
		return
	var bottom_y := get_bottom_y_global()
	var delta := hit_position.y - bottom_y
	if abs(delta) <= epsilon:
		global_position.y += delta

func snap_bottom_to_y(target_y: float) -> void:
	global_position.y += target_y - get_bottom_y_global()

func force_snap_bottom_to_y(target_y: float) -> void:
	snap_bottom_to_y(target_y)

func enter_drag_mode() -> void:
	_cancel_floor_transfer()
	_is_dragging = true
	_clear_pass_through()
	last_drop_reason = DropReason.NONE
	_clear_landing_cause()
	_apply_collision_profile_default()
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_state = State.DRAGGING
	_log_debug("enter_drag item=%s state=%s", [item_id, str(_state)])

func exit_drag_mode() -> void:
	_is_dragging = false
	_apply_collision_profile_default()
	freeze = false
	sleeping = false
	arm_landing()
	_state = State.SETTLING
	_settle_grace_frames = SETTLE_GRACE_FRAMES
	_log_debug("exit_drag item=%s state=%s", [item_id, str(_state)])

func prepare_for_slot_anchor() -> void:
	_cancel_floor_transfer()
	_clear_pass_through()
	_reject_falling = false
	last_drop_reason = DropReason.NONE
	_is_dragging = false
	_settle_time = 0.0
	_settle_grace_frames = 0
	_state = State.STABLE
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func enable_pass_through_until_y(target_y: float) -> void:
	_start_pass_through(target_y)

func start_reject_fall(surface_y: float) -> void:
	if _reject_falling:
		return
	_cancel_floor_transfer()
	_reject_falling = true
	last_drop_reason = DropReason.REJECT
	set_landing_cause(EventSchema.CAUSE_REJECT)

	_pass_through_active = true
	_pass_through_until_y = surface_y

	collision_layer = PhysicsLayers.LAYER_ITEM_REJECT_BIT
	collision_mask = PhysicsLayers.MASK_ITEM_REJECT_FALL
	_expand_pick_area()

func _start_pass_through(target_y: float) -> void:
	_pass_through_active = true
	_reject_falling = false
	_pass_through_until_y = target_y
	_pass_through_restore_layer = collision_layer
	_pass_through_restore_mask = collision_mask
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = PhysicsLayers.MASK_FLOOR_ONLY
	_expand_pick_area()

func _restore_pass_through() -> void:
	_pass_through_active = false
	_pass_through_until_y = 0.0

	if _reject_falling:
		_reject_falling = false
		collision_layer = DEFAULT_COLLISION_LAYER
		collision_mask = DEFAULT_COLLISION_MASK
		_state = State.SETTLING
		_settle_grace_frames = SETTLE_GRACE_FRAMES
	else:
		collision_layer = _pass_through_restore_layer
		collision_mask = _pass_through_restore_mask
	_restore_pick_area()


func _clear_pass_through() -> void:
	if _pass_through_active:
		if _reject_falling:
			collision_layer = DEFAULT_COLLISION_LAYER
			collision_mask = DEFAULT_COLLISION_MASK
		else:
			collision_layer = _pass_through_restore_layer
			collision_mask = _pass_through_restore_mask

	_pass_through_active = false
	_pass_through_until_y = 0.0
	_reject_falling = false
	_restore_pick_area()

func start_floor_transfer(target_y: float, mode: int) -> void:
	_cancel_floor_transfer(false)
	_apply_collision_profile_default()
	_transfer_target_y = target_y
	_transfer_mode = mode
	_transfer_phase = TransferPhase.RISING_THROUGH if mode == FloorTransferMode.RISE_THEN_FALL else TransferPhase.FALLING_TO_TARGET
	_transfer_crossed_frames = 0
	_transfer_fall_frames = 0
	_transfer_sink_frames = 0
	_transfer_sink_logged = false
	_capture_transfer_restore()
	_apply_transfer_profile_for_phase()
	freeze = false
	sleeping = false
	_log_debug("transfer_start item=%s phase=%s target_y=%.2f", [item_id, str(_transfer_phase), _transfer_target_y])
	if _transfer_phase == TransferPhase.RISING_THROUGH:
		gravity_scale = 0.0
		linear_velocity = Vector2(linear_velocity.x, -TRANSFER_RISE_SPEED)
	else:
		gravity_scale = 1.0
		if linear_velocity.y < TRANSFER_FALL_MIN_SPEED:
			linear_velocity = Vector2(linear_velocity.x, TRANSFER_FALL_MIN_SPEED)

func cancel_floor_transfer() -> void:
	_cancel_floor_transfer(true)

func apply_collision_profile_shelfed() -> void:
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = SHELFED_COLLISION_MASK

func apply_collision_profile_default() -> void:
	_apply_collision_profile_default()

func _apply_collision_profile_default() -> void:
	collision_layer = DEFAULT_COLLISION_LAYER
	collision_mask = DEFAULT_COLLISION_MASK

func _apply_transfer_profile_for_phase() -> void:
	if _transfer_phase == TransferPhase.RISING_THROUGH:
		collision_layer = TRANSFER_RISE_COLLISION_LAYER
		collision_mask = TRANSFER_RISE_COLLISION_MASK
	else:
		collision_layer = TRANSFER_FALL_COLLISION_LAYER
		collision_mask = TRANSFER_FALL_COLLISION_MASK
	_log_transfer_profile_applied()

func _capture_transfer_restore() -> void:
	_transfer_restore_layer = collision_layer
	_transfer_restore_mask = collision_mask
	_transfer_restore_gravity_scale = gravity_scale
	if _transfer_restore_gravity_scale <= 0.0:
		_transfer_restore_gravity_scale = 1.0

func _restore_transfer_settings() -> void:
	collision_layer = _transfer_restore_layer
	collision_mask = _transfer_restore_mask
	gravity_scale = _transfer_restore_gravity_scale

func _cancel_floor_transfer(restore: bool = true) -> void:
	if _transfer_phase == TransferPhase.NONE:
		return
	if restore:
		_restore_transfer_settings()
	_transfer_phase = TransferPhase.NONE
	_transfer_mode = FloorTransferMode.FALL_ONLY
	_transfer_target_y = 0.0
	_transfer_crossed_frames = 0
	_transfer_fall_frames = 0
	_transfer_sink_frames = 0
	_transfer_sink_logged = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _transfer_phase == TransferPhase.NONE:
		return
	_log_transfer_state(state)
	if _transfer_phase == TransferPhase.RISING_THROUGH:
		state.linear_velocity = Vector2(state.linear_velocity.x, -TRANSFER_RISE_SPEED)
		if get_bottom_y_global() <= _transfer_target_y - TRANSFER_RISE_EPS:
			snap_bottom_to_y(_transfer_target_y - TRANSFER_RISE_EPS)
			_transfer_phase = TransferPhase.FALLING_TO_TARGET
			_apply_transfer_profile_for_phase()
			gravity_scale = _transfer_restore_gravity_scale
			_log_debug("transfer_phase item=%s phase=%s", [item_id, str(_transfer_phase)])
			state.linear_velocity = Vector2(state.linear_velocity.x, maxf(state.linear_velocity.y, 0.0))
		return
	if _transfer_phase == TransferPhase.FALLING_TO_TARGET:
		if state.linear_velocity.y < TRANSFER_FALL_MIN_SPEED:
			state.linear_velocity = Vector2(state.linear_velocity.x, TRANSFER_FALL_MIN_SPEED)
		if get_bottom_y_global() > _transfer_target_y + TRANSFER_TARGET_EPS:
			_transfer_fall_frames += 1
			_transfer_sink_frames += 1
		else:
			_transfer_fall_frames = 0
			_transfer_sink_frames = 0
			_transfer_sink_logged = false
		if _transfer_sink_frames >= TRANSFER_SINK_LOG_FRAMES and not _transfer_sink_logged:
			_transfer_sink_logged = true
			_log_transfer_sink_detected(state)
		if _transfer_fall_frames >= TRANSFER_FAILSAFE_FRAMES:
			_force_land_transfer("failsafe")
			return
		if _is_transfer_landed():
			_finish_transfer(state.linear_velocity.length())

func _is_transfer_landed() -> bool:
	if get_bottom_y_global() < _transfer_target_y - TRANSFER_TARGET_EPS:
		return false
	_transfer_crossed_frames += 1
	if _is_supported_by_floor():
		return true
	return _transfer_crossed_frames >= TRANSFER_FORCE_LAND_FRAMES

func _finish_transfer(final_impact: float = 0.0) -> void:
	snap_bottom_to_y(_transfer_target_y)
	
	var impact_to_report = final_impact if final_impact > 0.0 else linear_velocity.length()
	if _landing_armed:
		_landing_armed = false
		get_tree().call_group(PhysicsLayers.GROUP_TICK, "on_item_impact", self, impact_to_report, current_surface)
	
	_stored_landing_impact = impact_to_report
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_restore_transfer_settings()
	_transfer_phase = TransferPhase.NONE
	_transfer_mode = FloorTransferMode.FALL_ONLY
	_transfer_target_y = 0.0
	_transfer_crossed_frames = 0
	_transfer_fall_frames = 0
	_transfer_sink_frames = 0
	_transfer_sink_logged = false
	_state = State.SETTLING
	_settle_grace_frames = SETTLE_GRACE_FRAMES
	if LOG_TRANSFER_END_ENABLED:
		_log_debug("transfer_end item=%s", [item_id])

func _force_land_transfer(reason: String) -> void:
	snap_bottom_to_y(_transfer_target_y)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_restore_transfer_settings()
	_transfer_phase = TransferPhase.NONE
	_transfer_mode = FloorTransferMode.FALL_ONLY
	_transfer_target_y = 0.0
	_transfer_crossed_frames = 0
	_transfer_fall_frames = 0
	_transfer_sink_frames = 0
	_transfer_sink_logged = false
	_state = State.SETTLING
	_settle_grace_frames = SETTLE_GRACE_FRAMES
	_log_debug("transfer_force_land item=%s reason=%s", [item_id, reason])

func _is_supported_by_floor() -> bool:
	var space := get_world_2d().direct_space_state
	if space == null:
		return false
	var origin := Vector2(global_position.x, get_bottom_y_global() - 1.0)
	var target := origin + Vector2(0.0, TRANSFER_SUPPORT_RAY_LENGTH)
	var params := PhysicsRayQueryParameters2D.create(origin, target)
	params.collision_mask = PhysicsLayers.LAYER_FLOOR_BIT
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [self]
	var hit: Dictionary = space.intersect_ray(params)
	return not hit.is_empty()

func _prepare_pick_area() -> void:
	var pick_area := $PickArea as Area2D
	if pick_area == null:
		return
	pick_area.collision_layer = PhysicsLayers.LAYER_PICK_AREA_BIT
	pick_area.collision_mask = PhysicsLayers.LAYER_PICK_AREA_BIT
	pick_area.input_pickable = true

func _cache_default_pick_size() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D:
		var rect := _pick_shape.shape as RectangleShape2D
		_pick_default_size = rect.size

func _expand_pick_area() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D:
		var rect := _pick_shape.shape as RectangleShape2D
		if _pick_default_size == Vector2.ZERO:
			_pick_default_size = rect.size
		rect.size = _pick_default_size * PASS_THROUGH_PICK_SCALE

func _restore_pick_area() -> void:
	if _pick_shape == null:
		return
	if _pick_shape.shape is RectangleShape2D and _pick_default_size != Vector2.ZERO:
		var rect := _pick_shape.shape as RectangleShape2D
		rect.size = _pick_default_size

func _prepare_physics_shape() -> void:
	if _physics_shape == null:
		_physics_shape = CollisionShape2D.new()
		_physics_shape.name = "PhysicsShape"
		add_child(_physics_shape)
	if _physics_shape.shape == null:
		var size := _resolve_sprite_size()
		if size == Vector2.ZERO:
			size = Vector2(32.0, 32.0)
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(2.0, size.x - COLLISION_PADDING), maxf(2.0, size.y - COLLISION_PADDING))
		_physics_shape.shape = rect

func _apply_physics_material() -> void:
	if physics_material_override != null:
		return
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.8
	physics_material.bounce = 0.1
	physics_material_override = physics_material

func _update_center_of_mass() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = _resolve_local_center() + cog_offset

func _apply_mass_defaults() -> void:
	if item_mass > 0.0:
		return
	var default_mass: float = float(DEFAULT_MASS_BY_TYPE.get(item_type, 1.0))
	item_mass = default_mass

func _resolve_sprite_size() -> Vector2:
	if _sprite == null or _sprite.texture == null:
		return Vector2.ZERO
	return _sprite.texture.get_size() * _sprite.scale

func _resolve_local_center() -> Vector2:
	if _physics_shape != null and _physics_shape.shape != null:
		return _physics_shape.position
	return Vector2.ZERO

func _get_sprite_aabb() -> Rect2:
	var half := Vector2(get_visual_half_width(), get_visual_half_height())
	return Rect2(global_position - half, half * 2.0)

func _get_shape_aabb(shape: Shape2D, shape_transform: Transform2D) -> Rect2:
	if shape == null:
		return Rect2()
	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var half := rect.size * 0.5
		var points := PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		var max_y := -INF
		for point in points:
			var world := shape_transform * point
			min_x = minf(min_x, world.x)
			max_x = maxf(max_x, world.x)
			min_y = minf(min_y, world.y)
			max_y = maxf(max_y, world.y)
		return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var center := shape_transform.origin
		var r := circle.radius
		return Rect2(Vector2(center.x - r, center.y - r), Vector2(r * 2.0, r * 2.0))
	return Rect2()


func _resolve_physics_tick():
	if _physics_tick != null and is_instance_valid(_physics_tick):
		return _physics_tick
	var node := get_tree().get_first_node_in_group(PhysicsLayers.GROUP_TICK)
	_physics_tick = node
	return _physics_tick

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if _state == State.DRAGGING:
		return
	if _transfer_phase != TransferPhase.NONE:
		return
	
	# Surface impact detection for damage
	if _landing_armed and body is CollisionObject2D:
		var col_obj := body as CollisionObject2D
		var surface_mask := PhysicsLayers.LAYER_FLOOR_BIT | PhysicsLayers.LAYER_SHELF_BIT
		if (col_obj.collision_layer & surface_mask) != 0:
			var impact := linear_velocity.length()
			# Ignore micro-impacts
			if impact > 5.0:
				_landing_armed = false
				get_tree().call_group(PhysicsLayers.GROUP_TICK, "on_item_impact", self, impact, body)

	if body is RigidBody2D:
		var other := body as RigidBody2D
		if other.collision_layer == 0 and other.collision_mask == 0:
			return
		set_landing_cause(EventSchema.CAUSE_COLLISION)
		_log_debug(
			"hit by %s pos=%.1f,%.1f vel=%.1f,%.1f transfer=%s phase=%s self_layer=%d self_mask=%d other_layer=%d other_mask=%d",
			[
				other.name,
				other.global_position.x,
				other.global_position.y,
				other.linear_velocity.x,
				other.linear_velocity.y,
				str(_transfer_phase != TransferPhase.NONE),
				str(_transfer_phase),
				collision_layer,
				collision_mask,
				other.collision_layer,
				other.collision_mask,
			]
		)
		call_deferred("_wake_from_hit")
		other.set_deferred("freeze", false)
		other.set_deferred("sleeping", false)

func _wake_from_hit() -> void:
	freeze = false
	sleeping = false
	arm_landing()
	apply_torque_impulse(randf_range(-2.0, 2.0))
	_log_debug("wake item=%s pos=%.1f,%.1f vel=%.1f,%.1f", [
		item_id,
		global_position.x,
		global_position.y,
		linear_velocity.x,
		linear_velocity.y,
	])

func _log_debug(format: String, args: Array = []) -> void:
	if not DebugLog.enabled():
		return
	if args.is_empty():
		DebugLog.log("ItemNode %s" % format)
		return
	DebugLog.logf("ItemNode " + format, args)

func _log_unstable_position() -> void:
	if not LOG_UNSTABLE_POS_ENABLED:
		return
	if not DebugLog.enabled():
		return
	if _state == State.STABLE:
		return
	_log_debug("pos item=%s state=%s x=%.1f y=%.1f", [
		item_id,
		str(_state),
		global_position.x,
		global_position.y,
	])

func _log_transfer_state(state: PhysicsDirectBodyState2D) -> void:
	if not LOG_TRANSFER_ENABLED:
		return
	if not DebugLog.enabled():
		return
	_log_debug("transfer item=%s phase=%s bottom_y=%.2f target_y=%.2f vel_y=%.2f", [
		item_id,
		str(_transfer_phase),
		get_bottom_y_global(),
		_transfer_target_y,
		state.linear_velocity.y,
	])

func _log_transfer_profile_applied() -> void:
	if not DebugLog.enabled():
		return
	var payload := {
		"item_id": StringName(item_id),
		"phase": StringName(str(_transfer_phase)),
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
		"restore_layer": _transfer_restore_layer,
		"restore_mask": _transfer_restore_mask,
	}
	DebugLog.event(StringName("TRANSFER_PROFILE_APPLIED"), payload)

func _log_transfer_sink_detected(state: PhysicsDirectBodyState2D) -> void:
	if not DebugLog.enabled():
		return
	var payload := {
		"item_id": StringName(item_id),
		"phase": StringName(str(_transfer_phase)),
		"bottom_y": get_bottom_y_global(),
		"target_y": _transfer_target_y,
		"vel_y": state.linear_velocity.y,
		"frames": _transfer_sink_frames,
		"collision_layer": collision_layer,
		"collision_mask": collision_mask,
	}
	DebugLog.event(StringName("TRANSFER_SINK_DETECTED"), payload)

func get_debug_state_label() -> String:
	match _state:
		State.STABLE:
			return "stable"
		State.DRAGGING:
			return "dragging"
		State.SETTLING:
			return "settling"
		_:
			return "unknown"

func is_settling() -> bool:
	return _state == State.SETTLING

func allow_settle() -> bool:
	return _settle_grace_frames <= 0

func mark_stable() -> void:
	_state = State.STABLE

func consume_landing_arm() -> bool:
	if not _landing_armed:
		return false
	_landing_armed = false
	return true

func arm_landing() -> void:
	_landing_armed = true
	_stored_landing_impact = 0.0

func get_effective_impact() -> float:
	if _stored_landing_impact > 0.0:
		return _stored_landing_impact
	return linear_velocity.length()

func is_transfer_active() -> bool:
	return _transfer_phase != TransferPhase.NONE

func is_reject_falling() -> bool:
	return _reject_falling

func is_pass_through_active() -> bool:
	return _pass_through_active

func can_register_on_surface() -> bool:
	return not _reject_falling

func set_current_surface(surface: Node) -> void:
	current_surface = surface

func clear_current_surface() -> void:
	current_surface = null

func set_landing_cause(cause: StringName) -> void:
	if cause.is_empty():
		return
	_landing_cause = cause

func consume_landing_cause(default_cause: StringName = EventSchema.CAUSE_ACCIDENT) -> StringName:
	var cause := _landing_cause
	_landing_cause = default_cause
	return cause

func _clear_landing_cause() -> void:
	_landing_cause = EventSchema.CAUSE_ACCIDENT
