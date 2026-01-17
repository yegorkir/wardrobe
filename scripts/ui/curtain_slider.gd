extends VSlider

signal curtainChanged(newValue)

func _value_changed(new_value: float) -> void:
	curtainChanged.emit(new_value)
