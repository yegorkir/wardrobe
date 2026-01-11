extends RefCounted

class_name QueueMixPolicy

const SOURCE_CHECKIN := StringName("CHECKIN")
const SOURCE_CHECKOUT := StringName("CHECKOUT")

const _CHECKOUT_THRESHOLD := 0.55

func select_next_source(snapshot: Dictionary) -> StringName:
	var need_in: int = int(snapshot.get("need_in", 0))
	var need_out: int = int(snapshot.get("need_out", 0))
	var outstanding: int = int(snapshot.get("outstanding", 0))
	var progress: float = float(snapshot.get("progress", 0.0))

	if need_in <= 0 and need_out <= 0:
		return SOURCE_CHECKIN
	if need_in <= 0:
		return SOURCE_CHECKOUT
	if need_out <= 0:
		return SOURCE_CHECKIN
	if outstanding <= 0:
		return SOURCE_CHECKIN

	var normalized_progress: float = clamp(progress, 0.0, 1.0)
	var target_total: float = max(1.0, float(need_in + need_out))
	var outstanding_ratio: float = clamp(float(outstanding) / target_total, 0.0, 1.0)
	var checkout_score: float = max(normalized_progress, outstanding_ratio)
	if checkout_score >= _CHECKOUT_THRESHOLD:
		return SOURCE_CHECKOUT
	return SOURCE_CHECKIN
