extends RefCounted

class_name InteractionConfig

var swap_enabled: bool = false

func _init(swap_enabled_value: bool = false) -> void:
	swap_enabled = swap_enabled_value

func duplicate_config() -> InteractionConfig:
	return get_script().new(swap_enabled) as InteractionConfig
