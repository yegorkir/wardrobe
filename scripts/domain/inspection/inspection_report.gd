extends RefCounted

class_name InspectionReport

var triggered: bool
var mode: StringName
var cleanliness: float
var inspector_risk: float
var notes: Array[String]

func _init(
	triggered_value: bool,
	mode_value: StringName,
	cleanliness_value: float,
	inspector_risk_value: float,
	notes_value: Array[String]
) -> void:
	triggered = triggered_value
	mode = mode_value
	cleanliness = cleanliness_value
	inspector_risk = inspector_risk_value
	notes = notes_value.duplicate(true)

func duplicate_report() -> InspectionReport:
	return get_script().new(
		triggered,
		mode,
		cleanliness,
		inspector_risk,
		notes
	) as InspectionReport
