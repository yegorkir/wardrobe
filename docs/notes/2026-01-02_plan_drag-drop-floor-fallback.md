# Plan: drag-drop floor fallback

## Goal
Guarantee that drag release always resolves to a valid placement (slot/shelf/floor), with upward floor travel when needed, while keeping adapter logic simple and maintainable.

## Proposed approach (Option A from analysis)
Move upward-fall logic into `ItemNode` as a dedicated state, keeping adapters responsible only for target selection and drop initiation.

## Steps
1) Update floor selection logic
- Add `_get_nearest_floor_for_item(item)` in `scripts/ui/wardrobe_dragdrop_adapter.gd`.
- Use rule: choose floor below with minimal delta; if none, choose absolute closest.
- Add deterministic tiebreak and X overlap filtering (avoid selecting floors from other areas).
- Replace existing `_get_floor_below_item` usage.

2) Add upward-fall support to ItemNode
- Introduce an FSM for transfer with two phases:
  - `RISING_THROUGH`: use **one-way floors** so the item can pass from below.
  - `FALLING_TO_TARGET`: restore normal gravity to land on the target floor.
- Contract: floor `CollisionShape2D` must have `one_way_collision = true` and direction set so floors hold from above and pass from below.
- During `RISING_THROUGH`, keep collision `mask = FLOOR_BIT` so one-way is active (do not disable floor collisions).
- Add transfer API on `ItemNode`:
  - `start_floor_transfer(target_y: float, mode: FloorTransferMode)` where mode is `RISE_THEN_FALL` or `FALL_ONLY`.
  - `cancel_floor_transfer()` for pickup cases.
- Drive transfer in `_integrate_forces(state)` (RigidBody2D-safe) instead of `_physics_process`.
- Add collision profile helpers with explicit composition:
  - `push_collision_profile_transfer()` applies TRANSFER where `mask = FLOOR_BIT` and excludes `ITEM_BIT` and `SHELF_BIT`.
  - `restore_collision_profile_default()` reverts to DEFAULT (document DEFAULT mask composition alongside).
- Target crossing must use bottom Y:
  - For rise: switch to `FALLING_TO_TARGET` when `get_bottom_y_global() <= target_y + eps`.
- Landing criteria: `get_bottom_y_global() >= target_y - eps` AND support ray hits floor surface AND optionally `abs(linear_velocity.y) <= v_eps`.
- Ensure `enter_drag_mode()` clears transfer state and restores physics before grabbing.

3) Integrate drop flow
- On drag release with no slot/shelf placement, always call floor drop:
  - If target floor below, keep existing fall behavior.
  - If target floor above, call `start_floor_transfer` with `RISE_THEN_FALL` (one-way floors).
  - If no floor exists, define a fallback (nearest global floor or a safety drop zone) and log warning.

4) Validation
- Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Launch Godot: `"$GODOT_BIN" --path .`.
- Confirm upward drop behavior and that catching in mid-rise resets to drag mode cleanly.
- Manual scenario check: release with no floor below, confirm rise-through then fall onto target floor.

## Deliverables
- Code changes in `scripts/ui/wardrobe_dragdrop_adapter.gd` and `scripts/wardrobe/item_node.gd`.
- If needed, small additions in `scripts/ui/floor_zone_adapter.gd`.
- Update changelog/checklist entries in `docs/notes/2026-01-02_changelog_drag-release-logging.md` and `docs/notes/2026-01-02_checklist_drag-release-logging.md`.

## Ownership note
- Floor selection logic should live in `SurfaceRegistry` (single source of truth) if possible; otherwise, document that dragdrop owns the choice and tick does not.

## Collision policy decision (must choose before implementation)
- Chosen: DEFAULT mask includes `ITEM_BIT` for mid-air interactions.
- Introduce `SHELFED` profile where mask = `FLOOR_BIT | SHELF_BIT` (no `ITEM_BIT`).
- Switch to `SHELFED` immediately on shelf placement (simpler, prevents chain reactions).
- Return to DEFAULT on `enter_drag_mode()` and at the start of any floor transfer/fall.
