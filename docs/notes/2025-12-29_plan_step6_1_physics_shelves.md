# 2025-12-29 — Plan: Step 6.1 physics shelves (No-SU)

## Goals
- Replace SU shelf placement with physics-based placement.
- Keep hooks/desks as slot-based snap.
- Add stability checks, wake-up, auto-freeze, and drag-safe behavior.

## Plan (small steps, runnable after each)

1) **Physics tick adapter**
- Create `scripts/ui/wardrobe_physics_tick_adapter.gd` (`extends Node`).
- Add `pending_stability_checks` queue and `_physics_process` to run ray/shape queries.
- Instance it in `scenes/screens/WorkdeskScene.tscn` (and in `scenes/screens/WardrobeScene.tscn` if needed).

2) **ItemNode → RigidBody2D**
- Update `scripts/wardrobe/item_node.gd` to extend `RigidBody2D`.
- Add exports: `mass`, `cog_offset`.
- Auto-create `CollisionShape2D` from sprite size with `collision_padding = 2.0` if shape missing.
- Apply `PhysicsMaterial` (friction 0.8, bounce 0.1).
- Implement drag state API:
  - `enter_drag_mode()` -> freeze + no collisions (layer/mask = 0).
  - `exit_drag_mode()` -> restore layer/mask, keep freeze until stability check.
- Add settle timer in `_physics_process` and call `physics_tick.request_settle_check(self)`.
- Add domino wake-up in `_on_body_entered` with tiny random torque.

3) **Collision layers + interaction rules**
- Enforce layers:
  - Layer 1: StaticBody2D surfaces.
  - Layer 2: Item RigidBody2D.
  - Layer 3: PickArea + DropAreas.
- Keep PickArea active during drag (no layer changes).

4) **ShelfSurfaceAdapter: remove SU + add physics surface**
- Strip `capacity_units`, SU placement arrays, and interval math in `scripts/ui/shelf_surface_adapter.gd`.
- Update `scenes/prefabs/shelf_surface.tscn`:
  - Add `StaticBody2D` + `CollisionShape2D` aligned to shelf surface.
  - Keep DropArea for detection (Area2D).
- Add helpers to expose shelf global bounds for overhang calculation.

5) **FloorZoneAdapter: keep scatter, drop to physics**
- Keep deterministic scatter + edge clamp in `scripts/ui/floor_zone_adapter.gd`.
- Remove tweened placement; place frozen item at cursor + scatter.
- Add `StaticBody2D` collision shape for floor (scene or prefab).

6) **Drag/drop flow rewrite**
- Update `scripts/ui/wardrobe_dragdrop_adapter.gd`:
  - On pick: call `enter_drag_mode()`.
  - On drop to shelf/floor: set frozen position, enqueue drop check via physics tick adapter.
  - Remove SU validation for shelf/floor.
- Keep hook/desk interaction flow unchanged (slot-based + place_flags).

7) **Stability + torque logic (centralized)**
- In `WardrobePhysicsTickAdapter._physics_process`:
  - Raycast from global CoG to Layer 1.
  - Overlap gate: `intersect_shape` on Layer 2, `exclude = [item.get_rid()]`.
  - Stable: Y-snap + `freeze = true`.
  - Unstable: `freeze = false`, `apply_torque_impulse(TORQUE_BASE * mass * sign(overhang))`.
- Overhang definition via shelf bounds in world space.

8) **UX feedback**
- Add CoG marker + gravity line during drag.
- If unstable: modulate red + shake tween + warning icon.
- Warning icon placeholder: `Polygon2D` triangle 50px above input point.

9) **Cleanup SU artifacts**
- Remove SU logic usage in wardrobe adapters.
- Keep `default_placement_behavior.gd` for hooks/desks validation (HANG/LAY).
- Ensure no runtime references to `*_su`, `UNIT_SCALE`, `capacity_units` remain.

10) **Verification**
- Run tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Manual checks:
  - Drag does not nudge neighbors.
  - Stable drop freezes; unstable drop falls and can wake neighbors.
  - Items auto-freeze after settling.
  - Floor scatter stays inside bounds.
  - Hooks/desks still snap correctly.

## References (Godot 4.5)
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- StaticBody2D: https://docs.godotengine.org/en/4.5/classes/class_staticbody2d.html
- PhysicsDirectSpaceState2D.ray query: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html#class-physicsdirectspacestate2d-method-intersect-ray
