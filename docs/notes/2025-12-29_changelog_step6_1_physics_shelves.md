# 2025-12-29 — Changelog: Step 6.1 physics shelves (No-SU)

## Added
- `WardrobePhysicsTickAdapter` to centralize physics queries in `_physics_process` and track drag probe state.
- Physics surfaces (`StaticBody2D`) for shelf and floor zones.
- Cursor-hand drag feedback (CoG marker, gravity line, warning icon + shake).

## Changed
- `ItemNode` migrated to `RigidBody2D` with CoG, physics material, auto-collision, and settle/wake logic.
- Shelf/Floor adapters converted to physics-first placement (no SU intervals, no tween snapping).
- Drag/drop flow now enqueues stability checks and uses place flags only (HANG/LAY).
- Slot placement forces frozen, non-colliding items for hooks/desks.
- Removed size units from `WardrobeItemConfig`; kept place flags only.
- `WardrobePhysicsTick` scene nodes switched to `Node2D` to allow world-space queries.
- Cursor-hand warning state uses typed `supported` to satisfy parser.
- Marked `WardrobePhysicsTick` nodes as `unique_name_in_owner` to satisfy `%WardrobePhysicsTick` lookups.
- Deferred wake-up in `ItemNode` to avoid physics flushing errors.
- Removed unused `_interaction_events_target` field warning.
- Added debug logging hooks for drag/drop, shelf/floor placement, and physics tick stability checks.
- Tightened physics tick typing to satisfy Variant inference warnings.
- Added per-item collision/wake logging for objects pushed by other bodies.
- Prevented freezing on overlap; added overlap resolution impulses and torque.
- Added settle grace frames and state gating to avoid instant freeze after drop.
- Surface bounds now derived from collider chain (Rect2) to avoid missing-bounds torque skips.

## Removed
- SU/interval placement logic from shelf/floor adapters and drag/drop flow.
- `UNIT_SCALE` constant from placement types.

## Verification
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
  - Log: `ERROR: Condition "ret != noErr" is true. Returning: ""`
  - Exit code: 0
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task build-all`
  - Log: `ERROR: Condition "ret != noErr" is true. Returning: ""`
  - Log: `ERROR: Cannot save file '/Users/yegorkir/Library/Application Support/Godot/editor_settings-4.5.tres'.`
  - Exit code: 0
