class_name HookBoard
extends Node2D

@export var board_prefix := "HookBoard_0":
	set(value):
		board_prefix = value
		_update_slot_prefixes()

@onready var _hooks: Array[HookItem] = []

func _ready() -> void:
	_collect_hooks()
	_update_slot_prefixes()

func _collect_hooks() -> void:
	_hooks.clear()
	for child in get_children():
		if child is HookItem:
			_hooks.append(child as HookItem)

func _update_slot_prefixes() -> void:
	if board_prefix.is_empty():
		return
	if _hooks.is_empty():
		return
	for i in _hooks.size():
		_hooks[i].slot_prefix = "%s_Hook_%d" % [board_prefix, i]
