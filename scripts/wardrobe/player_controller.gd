class_name WardrobePlayerController
extends CharacterBody2D

@export var move_speed: float = 240.0
@onready var hand_socket: Node2D = %HandSocket
@onready var interact_area: Area2D = %InteractArea
@onready var _interact_shape: CollisionShape2D = interact_area.get_node("CollisionShape2D") as CollisionShape2D

const HAND_SLOTS := 2
var _hands: Array = [null, null]
var active_hand_index := 0
var last_move_direction: Vector2 = Vector2.RIGHT
var _spawn_position := Vector2.ZERO

func _ready() -> void:
	_spawn_position = global_position

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length_squared() > 0.0:
		input_vector = input_vector.normalized()
		last_move_direction = input_vector
	velocity = input_vector * move_speed
	move_and_slide()

func get_active_hand_item() -> ItemNode:
	return _hands[active_hand_index]

func is_active_hand_empty() -> bool:
	return get_active_hand_item() == null

func hold_item(item: ItemNode) -> void:
	_hands[active_hand_index] = item
	if item:
		item.attach_to_anchor(hand_socket)

func take_item_from_hand() -> ItemNode:
	var item: ItemNode = _hands[active_hand_index]
	_hands[active_hand_index] = null
	return item

func get_last_move_dir() -> Vector2:
	return last_move_direction

func get_interact_radius() -> float:
	if _interact_shape and _interact_shape.shape is CircleShape2D:
		return (_interact_shape.shape as CircleShape2D).radius
	return 0.0

func reset_state() -> void:
	var carried := take_item_from_hand()
	if carried:
		carried.queue_free()
	for i in HAND_SLOTS:
		if i != active_hand_index:
			var extra_item: ItemNode = _hands[i]
			if extra_item:
				extra_item.queue_free()
			_hands[i] = null
	active_hand_index = 0
	last_move_direction = Vector2.RIGHT
	global_position = _spawn_position
	velocity = Vector2.ZERO
