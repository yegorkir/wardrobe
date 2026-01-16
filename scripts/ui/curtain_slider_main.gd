extends VSlider

@onready var anotherSlider = $CurtainSlider

func _value_changed(new_value: float) -> void:
	anotherSlider.value = new_value

func _ready():
	anotherSlider.curtainChanged.connect(_on_anotherSlider_curtainChanged)

func _on_anotherSlider_curtainChanged(new_value):
	self.value = new_value
