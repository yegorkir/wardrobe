# Analysis: Shelf Surface SSOT + Item Snap Fixes

## Context
- Reported bug: shelf surface Y drifts when `DropArea` height changes, causing items to settle above/below the visual shelf line.
- Likely cause: UI elements (`DropLine`/`VisualBar`) are currently driven by `DropArea` geometry; if any placement flow reads that Y (directly or via cursor/drop coordinates), the shelf height drifts.
- Secondary issue: `ItemNode.get_global_bottom_y()` ignores rotation/shape transform; `snap_to_surface()` is epsilon-based and only applies while frozen.

## Goals
- Single source of truth for shelf surface Y, derived from `SurfaceRef.global_position.y + drop_y_offset_px` when present.
- Decouple DropArea sizing from shelf surface alignment.
- Deterministic snap of item bottom to shelf surface, regardless of cursor/drop area Y.
- Maintain adapter responsibility: UI/input flow corrects imprecise input without mutating domain rules.
- Apply the same SSOT principle to floor zones to avoid a second drift source.

## Non-goals
- Reworking domain placement rules or storage invariants.
- Altering physics simulation rules (beyond deterministic alignment when placing).
- Changing content definitions or prefab structure beyond the adapter-level sync.

## Proposed design (high level)
- **ShelfSurfaceAdapter** exposes a canonical `get_surface_y_global()` based on the `SurfaceRef` marker node, with a strict fallback to the physical surface shape if the marker is missing.
- Visual markers (`DropLine`, `VisualBar`) align to `get_surface_y_global()` via global Y, independent of DropArea height.
- **place_item()** uses drop X but **recomputes Y** from the shelf surface and item bottom offset.
- **ItemNode** provides a deterministic bottom placement via `force_snap_bottom_to_y()` and fixes bottom calculation for rotated shapes.

## Architecture notes (SSOT + adapter flow)
- **SSOT**: shelf surface height lives in `ShelfSurfaceAdapter`, based on `SurfaceRef` when present, not UI hit-testing shapes. If the marker is missing, fallback uses the physical surface collision shape (not `DropLine`/`DropArea`).
- **Adapters**: input hits (`DropArea`) only select a target shelf; they do not decide final placement Y.
- **Physics**: item bottom computed from actual shape transform to allow rotations without invalid snapping.

## Module/class responsibilities
- `scripts/ui/shelf_surface_adapter.gd`
  - Add `SurfaceRef: Node2D` to shelf prefabs and resolve it with `get_node_or_null("SurfaceRef")`.
  - Add `get_surface_y_global()` returning the canonical surface Y from `SurfaceRef`.
  - Update `_sync_visual_bar()` to use canonical Y for `VisualBar`/`DropLine` (global Y).
  - Update `place_item()` to compute Y from surface + item bottom, not from cursor Y.
  - Clamp X to canonical bounds based on `shelf_length_px` around `SurfaceRef.global_position.x` (optionally `SurfaceLeft/SurfaceRight` markers).
  - In `place_item()`, reset rotation/scale before computing bottom/snap.
  - Optional: add `_debug_validate_alignment()` that warns on mismatch.
- `scripts/wardrobe/item_node.gd`
  - Fix `get_global_bottom_y()` to use `global_transform` and local bottom point.
  - Add `force_snap_bottom_to_y(target_y: float)` for deterministic snap.
  - Replace `call_deferred("set_freeze", false)` with `call_deferred("set", "freeze", false)`.
- `scripts/ui/floor_zone_adapter.gd`
  - Add `SurfaceRef: Node2D` to floor prefabs and resolve it with `get_node_or_null("SurfaceRef")`.
  - Add `get_surface_y_global()` and use it for drop placement and visuals where applicable.
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
  - No logic changes required beyond relying on `ShelfSurfaceAdapter.place_item()` for final Y.

## Edge cases & decisions
- **Rotation**: bottom calculation uses shape transform; if item rotation is reset on placement, bottom snap remains correct.
- **Scale**: surface position comes from `SurfaceRef`; avoid relying on physics shape scale for placement.
- **X clamping**: required; clamp to canonical bounds using `shelf_length_px` (or left/right markers), not `DropArea` or shape.

## Requirements / invariants
- `surface_y_global` derived only from `SurfaceRef.global_position.y + drop_y_offset_px`.
- `DropLine.global_position.y == surface_y_global` within 0.5 px (debug validation).
- `VisualBar` aligns to `surface_y_global` and does not move when `DropArea` height changes.
- `place_item()` computes Y as `surface_y_global - item_bottom_offset_global` (no use of cursor Y).
- `abs(item.get_global_bottom_y() - shelf.get_surface_y_global()) <= 0.5` after placement.
- If `SurfaceRef` is missing, emit `push_warning(...)` and use the physical surface shape top edge as fallback (not `DropLine`).

## Suggested API details (GDScript)
- `ShelfSurfaceAdapter.get_surface_y_global()`
  - Use `SurfaceRef.global_position.y + drop_y_offset_px`.
  - If `SurfaceRef` is missing, emit a warning and use the surface collision shape top edge.
- `ItemNode.get_global_bottom_y()`
  - Use `(_physics_shape.global_transform * local_bottom).y` for both rectangle and circle shapes.
- `ItemNode.force_snap_bottom_to_y()`
  - `global_position.y += target_y - get_global_bottom_y()`

## Alternatives considered
1) Use `DropArea` as the canonical surface reference.
   - Rejected: UI-only hit shape should not determine physics/placement Y.
2) Compute snap based on cursor Y and epsilon.
   - Rejected: breaks determinism, fails when cursor Y drifts.
3) Compute surface bounds from `shelf_length_px` only.
   - Accepted for fallback, but prefer `SurfaceBody` for SSOT.

## Testing plan
- Run canonical tests after changes:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Manual verification (if tests do not cover):
  - Change `DropArea` height; confirm `DropLine` and `VisualBar` remain aligned to surface.
  - Drop items at different cursor Ys; confirm item bottoms align to shelf surface.

## Risks
- If `SurfaceRef` is missing in a prefab, fallback to the collision shape may diverge from visuals; warning + validation should catch this early.
- If `SurfaceRef` and the collision shape are misaligned, items may appear correct but collide incorrectly (or vice versa).

## Open questions
- None. Decisions recorded:
  - Clamp X now.
  - Reset item rotation to 0 on placement.
  - Apply SSOT to `FloorZoneAdapter`.
  - Replace `set_freeze` deferred call as noted above.

## References
- `CollisionShape2D` (global_transform, shape):
  - https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
- `RectangleShape2D` (size):
  - https://docs.godotengine.org/en/4.5/classes/class_rectangleshape2d.html
- `Node2D` transforms:
  - https://docs.godotengine.org/en/4.5/classes/class_node2d.html
