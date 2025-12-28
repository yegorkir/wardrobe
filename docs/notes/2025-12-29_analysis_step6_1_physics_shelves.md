# 2025-12-29 — Analysis: Step 6.1 physics shelves (No-SU, adapter-first)

## Problem summary
We must remove all SU/interval shelf placement and move to a physics-based system with:
- `RigidBody2D` items with mass + custom CoG.
- `StaticBody2D` shelf/floor surfaces.
- Drag that disables item collisions but preserves PickArea interaction.
- Drop decisions based on stability raycasts and overlap checks.
- Domino wake-up + auto-freeze after settling.
- UX feedback: gravity line, CoG marker, unstable warning.

## Current state (relevant code)
- `scripts/wardrobe/item_node.gd` is `Node2D` with `PickArea`.
- `scripts/ui/shelf_surface_adapter.gd` and `scripts/ui/floor_zone_adapter.gd` rely on SU and tweened placement.
- `scripts/ui/wardrobe_dragdrop_adapter.gd` owns pick/drop flow and uses SU placement rules.
- `scripts/app/wardrobe/placement/*` provides SU-based validation.

## Goals
- Remove SU math (capacity_units, size_su, UNIT_SCALE, intervals) from wardrobe adapters.
- Add physics surfaces and stability checks, with queries only in `_physics_process`.
- Keep slot-based hooks/desks unchanged, using place_flags only for hang/lay validation.

## Non-goals
- No changes to `scripts/domain/**`.
- No changes to core interaction or client logic.
- No UI redesign beyond required physics feedback.

## Constraints
- Physics queries must run in `_physics_process` only (avoid "space is locked" errors).
- `PickArea` must remain active on Layer 3 during drag.
- Do not teleport dynamic bodies; only move when frozen.

## Architecture choice (final)
**Option A — Adapter-first** with a dedicated physics tick adapter:
- `WardrobePhysicsTickAdapter` (`scripts/ui/wardrobe_physics_tick_adapter.gd`, `extends Node`).
- Scene instance (WorkdeskScene, WardrobeScene if needed).
- Owns `pending_stability_checks` queue and runs ray/shape queries in `_physics_process`.

## Component design

### `scripts/ui/wardrobe_physics_tick_adapter.gd`
- Holds `pending_stability_checks: Array[Dictionary]`.
- API:
  - `enqueue_drop_check(item: ItemNode, preferred_surface: Node = null)`
  - `request_settle_check(item: ItemNode)`
- In `_physics_process`:
  - `intersect_ray` from global CoG to Layer 1.
  - `intersect_shape` for overlap against Layer 2 (`exclude = [item.get_rid()]`).
  - Decide stable/unstable and apply freeze/torque.

### `scripts/wardrobe/item_node.gd`
- Change base to `RigidBody2D`.
- Exports: `mass`, `cog_offset`.
- Auto-collision: if shape missing, create `RectangleShape2D` from sprite size minus `collision_padding = 2.0`.
- PhysicsMaterial: friction 0.8, bounce 0.1.
- Drag state:
  - `enter_drag_mode()` -> freeze + no collisions (layer/mask = 0).
  - `exit_drag_mode()` -> restore layer/mask, freeze stays true until stability check.
- Settling:
  - Track low-velocity time in `_physics_process`.
  - When > 1s, call `physics_tick.request_settle_check(self)`.
- Domino wake-up:
  - On body entered by active body: `freeze = false`, tiny random torque.

### `scripts/ui/wardrobe_dragdrop_adapter.gd`
- On pick: call `item.enter_drag_mode()`.
- On drop to shelf/floor: set frozen position, then `physics_tick.enqueue_drop_check(item, surface)`.
- Remove SU validation for shelf/floor; keep hook/desk flow with place_flags.

### `scripts/ui/shelf_surface_adapter.gd` and `scripts/ui/floor_zone_adapter.gd`
- Remove SU and interval math.
- Provide surface bounds for stability/overhang checks.
- Shelves/floors contain `StaticBody2D` colliders (Layer 1).

## Formal overhang definition
- `left_x/right_x` from shelf collision shape bounds in world space.
- `overhang = cog_x - clamp(cog_x, left_x, right_x)`.
- `sign(overhang)`:
  - `-1` if `cog_x < left_x`
  - `+1` if `cog_x > right_x`
  - `0` otherwise
- Apply torque only if `sign != 0`.

## Risks and mitigations
- **Physics queries outside `_physics_process`**: solved by central tick adapter.
- **Pick interaction broken during drag**: keep PickArea on Layer 3, unchanged.
- **Unstable jitter**: enforce auto-freeze with settle timer and stability checks.
- **Overlaps on drop**: overlap gate forces dynamic resolution.

## Testing
- No current automated tests cover physics placement; manual verification required.
- Run: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.

## References (Godot 4.5)
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- StaticBody2D: https://docs.godotengine.org/en/4.5/classes/class_staticbody2d.html
- PhysicsDirectSpaceState2D: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
- Shape2D: https://docs.godotengine.org/en/4.5/classes/class_shape2d.html
