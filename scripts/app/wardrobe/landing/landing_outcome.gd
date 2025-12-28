extends RefCounted
class_name LandingOutcome

const EFFECT_NONE := StringName("NONE")
const EFFECT_BOUNCE := StringName("BOUNCE")
const EFFECT_BREAK := StringName("BREAK")

const KEY_TYPE := StringName("type")
const KEY_MULTIPLIER := StringName("multiplier")
const KEY_QUALITY_DELTA := StringName("quality_delta")
const KEY_ENTROPY_DELTA := StringName("entropy_delta")

var effects: Array[Dictionary] = []
var quality_delta: Variant = null
var entropy_delta: Variant = null
