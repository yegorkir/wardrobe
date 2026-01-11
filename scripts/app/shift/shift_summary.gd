extends RefCounted

class_name ShiftSummary

const InspectionReportScript := preload("res://scripts/domain/inspection/inspection_report.gd")

var money: int
var notes: Array
var cleanliness: float
var inspector_risk: float
var status: StringName
var strikes_current: int
var strikes_limit: int
var inspection_report: InspectionReportScript
var end_reasons: Array

func _init(
	money_value: int,
	notes_value: Array,
	cleanliness_value: float,
	inspector_risk_value: float,
	status_value: StringName,
	strikes_current_value: int,
	strikes_limit_value: int,
	inspection_report_value: InspectionReportScript,
	end_reasons_value: Array
) -> void:
	money = money_value
	notes = notes_value.duplicate(true)
	cleanliness = cleanliness_value
	inspector_risk = inspector_risk_value
	status = status_value
	strikes_current = strikes_current_value
	strikes_limit = strikes_limit_value
	inspection_report = inspection_report_value
	end_reasons = end_reasons_value.duplicate(true)

func duplicate_summary() -> ShiftSummary:
	var report_copy: InspectionReportScript = inspection_report.duplicate_report() if inspection_report else null
	return get_script().new(
		money,
		notes,
		cleanliness,
		inspector_risk,
		status,
		strikes_current,
		strikes_limit,
		report_copy,
		end_reasons
	) as ShiftSummary
