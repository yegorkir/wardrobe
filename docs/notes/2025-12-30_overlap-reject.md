# Overlap Reject + Push Budget (Shelf Placement)

## Goal
Allow small overlaps to resolve with gentle pushes while rejecting large overlaps so items drop to the floor and avoid "invisible hand" shifts.

## Changes
- Added overlap metrics (AABB intersection area ratio, per-item and total push estimates, affected count).
- Introduced push budgets and reject reasons for large overlaps.
- On reject, the item is released and dropped to the nearest floor zone (no hand rollback).
- Rejects now use a fall drop to avoid instant snapping to the floor surface.
- Stability now treats center-of-mass as the shelf-validity check (COG over shelf keeps item stable).
- Shelf clamping and overlap-bound checks now also use COG-based bounds.
- Small-overlap pushes are now mass-aware, distributing impulses between items based on relative mass.
- Item mass defaults now derive from `ItemType` when `item_mass` is unset.
- Shelf X clamp now accounts for COG offset so edge placements don't snap inward when COG is still over the shelf.
- Added debug logging for metrics, decisions, and planned push distances.
- Added a tiny-overlap ignore threshold to skip sub-pixel resolve passes (now 1.0px to reduce residual rollback).
- Overlapping neighbors are woken on overlap detection (including cooldown/tiny-skip paths) so chained pushes can propagate.
- Overlap cooldown no longer masks big-overlap rejects; reject rules still run during cooldown.
- Neighbor items are no longer put on cooldown; only the resolved item uses cooldown to keep motion springy.

## Tuning knobs
- `OVERLAP_MAX_PUSH_PER_ITEM_PX`, `OVERLAP_MAX_PUSH_TOTAL_PX`, `OVERLAP_MAX_AFFECTED`, `OVERLAP_MAX_AREA_RATIO`
- `OVERLAP_PUSH_IMPULSE_PER_PX`, `OVERLAP_MIN_PUSH_PX`, `OVERLAP_IGNORE_PX`, `OVERLAP_COOLDOWN_FRAMES`

## Notes
- Overlap metrics use AABB intersection for determinism and simplicity.
- Floor drop uses existing `FloorZoneAdapter.drop_item` to avoid large overlap-driven pushes.

## References (Godot 4.5)
- PhysicsDirectSpaceState2D: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
- PhysicsShapeQueryParameters2D: https://docs.godotengine.org/en/4.5/classes/class_physicsshapequeryparameters2d.html
- Rect2: https://docs.godotengine.org/en/4.5/classes/class_rect2.html
