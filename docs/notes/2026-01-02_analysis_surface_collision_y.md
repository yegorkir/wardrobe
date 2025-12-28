# Analysis: unify surface collision Y for floor landing

## Context
- Items transfer to a floor target using `target_y` derived from `SurfaceRef` or bounds.
- Logs show `transfer_end` fires without real contact; items continue falling.
- Likely cause: mismatch between `SurfaceRef` Y and the physical collision plane (top of `CollisionShape2D`), combined with one-way collision behavior.

## Goal
- Align all floor landing targets to the actual collision plane to keep physics and visuals consistent.
- Keep clean architecture by centralizing “physics surface Y” in the base surface contract.

## Proposed contract change
- Add `get_surface_collision_y_global()` to `WardrobeSurface2D`.
  - Default implementation: fall back to `get_surface_y_global()` and warn (to avoid silent mistakes).
  - Adapters override to return collision-shape top when available.
- Update the floor-selection/transfer path to use `get_surface_collision_y_global()` for `target_y`.

## Likely root causes addressed
- `SurfaceRef` or bounds Y is not identical to collider top.
- One-way collisions ignore bodies that are slightly below the plane, so a mismatch causes indefinite falling.

## Benefits
- Single source of truth for physics placement; reduces drift between visuals and collision.
- Simplifies future surface types (they must provide collision Y explicitly).
- Works cleanly with one-way + margin tuning.

## Risks / considerations
- Visual misalignment could become visible if sprites were authored to a different reference line; may need small offsets on surfaces.
- Any surface lacking a proper collision shape will still default to `get_surface_y_global()`, so warnings should remain.

## References (Godot 4.5)
- CollisionShape2D one-way: https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
- RigidBody2D integration: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
