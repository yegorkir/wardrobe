extends RefCounted
class_name DefaultPlacementBehavior

const PlacementTypes := preload("res://scripts/app/wardrobe/placement/placement_types.gd")

const RESULT_KEY_OK := "ok"
const RESULT_KEY_REASON := "reason"

func can_place(
	slot_kind: int,
	place_flags: int,
	size_su: int,
	is_empty: bool = true,
	capacity_su: int = 0,
	x_su: int = 0,
	existing_intervals: Array = []
) -> Dictionary:
	match slot_kind:
		PlacementTypes.SlotKind.HOOK:
			return _check_hook(place_flags, is_empty)
		PlacementTypes.SlotKind.SHELF:
			return _check_shelf(place_flags, size_su, capacity_su, x_su, existing_intervals)
		PlacementTypes.SlotKind.FLOOR:
			return _ok("floor_ok")
		_:
			return _fail("slot_kind_unknown")

func _check_hook(place_flags: int, is_empty: bool) -> Dictionary:
	if (place_flags & PlacementTypes.PlaceFlags.HANG) == 0:
		return _fail("hang_required")
	if not is_empty:
		return _fail("slot_occupied")
	return _ok("hook_ok")

func _check_shelf(
	place_flags: int,
	size_su: int,
	capacity_su: int,
	x_su: int,
	existing_intervals: Array
) -> Dictionary:
	if (place_flags & PlacementTypes.PlaceFlags.LAY) == 0:
		return _fail("lay_required")
	if size_su <= 0:
		return _fail("size_invalid")
	if x_su < 0:
		return _fail("x_out_of_bounds")
	if x_su + size_su > capacity_su:
		return _fail("x_out_of_bounds")
	for interval in existing_intervals:
		if typeof(interval) != TYPE_DICTIONARY:
			continue
		var a := int(interval.get("x_su", 0))
		var b := a + int(interval.get("size_su", 0))
		if x_su < b and (x_su + size_su) > a:
			return _fail("overlap")
	return _ok("shelf_ok")

func _ok(reason: String) -> Dictionary:
	return {
		RESULT_KEY_OK: true,
		RESULT_KEY_REASON: reason,
	}

func _fail(reason: String) -> Dictionary:
	return {
		RESULT_KEY_OK: false,
		RESULT_KEY_REASON: reason,
	}
