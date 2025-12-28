# Analysis: drag-drop floor fallback

## Context
- Drag release can fail when the cursor is not over a valid slot/shelf/floor zone.
- Current behavior: if no floor is detected, the item remains in the hand, causing it to keep following the cursor.
- Desired behavior: on drag release, the item must always end up on a valid target. If no valid slot/shelf is available, the item must fall to the floor. If the nearest floor is above the item, the item must move upward via physics (not teleport) until it reaches that floor, then resume normal physics.

## Requirements recap
- Drag release always resolves to either slot/shelf placement or floor drop.
- If the only eligible floor is above the item, it must physically move upward (no teleporting).
- If the player picks the item during the upward or downward fall, the item must return to drag state the same way it would during a normal fall.
- Desk slots always accept any item. Other slots still use existing validation.
- The selection rule for floors:
  - Prefer floors below the item; choose the one with minimal positive delta_y.
  - If none below, choose the closest floor by absolute delta_y.

## Current flow (summary)
- `WardrobeDragDropAdapter.on_pointer_up`:
  - If hovering a slot, tries slot interaction (desk slots always accept).
  - Else tries drop to shelf, else drop to floor.
  - `_try_drop_to_floor` can fail if `get_floor_below_item` returns null, causing the item to stay in the hand.
- `FloorZoneAdapter` provides drop methods, and `ItemNode` owns pass-through and reject-fall behavior.

## Architecture constraints
- Adapter logic stays in `scripts/ui` or `scripts/wardrobe`.
- Core rules remain in `domain/` and `app/` untouched.
- Any new state needed for drag/drop should be adapter or node-local state.

## Solution design (goal)
- Make floor selection deterministic and comprehensive for both below and above cases.
- Ensure `on_pointer_up` always resolves to a definitive outcome: place to slot/shelf or enqueue a floor drop.
- Introduce a minimal upward-fall mode for items when targeting a floor above the item.

## Options for upward fall implementation

### Option A: ItemNode “rise-through + fall-to-target” mode (preferred for cleanliness)
- Add a dedicated mode to `ItemNode` for upward travel with two phases:
  - `RISING_THROUGH`: allow pass-through (or use one-way collision on floor shapes) so the item can move upward past a floor plane.
  - `FALLING_TO_TARGET`: restore normal gravity so the item lands on the chosen floor.
- Track a target surface Y; when the item crosses/arrives at the target, restore physics settings (gravity, collision masks, pass-through, etc.).
- Prefer controlling physics in `_integrate_forces(state)` to keep RigidBody behavior deterministic.
- On drag pickup during ascent, `enter_drag_mode()` must clear rise state and restore collision profile immediately.
- Pros:
  - Keeps physics state transitions in one place.
  - Minimal changes to adapters beyond triggering the new mode.
  - Aligns with “presentation/adapters own physics” rule.
- Cons:
  - Adds state to ItemNode; must keep it tidy and well-documented.

### Option B: FloorZoneAdapter handles upward travel (adapter-driven)
- Add a new drop method in FloorZoneAdapter: `drop_item_with_rise(item, cursor_pos)` that applies an upward impulse or negative gravity and tracks completion.
- ItemNode remains mostly unchanged.
- Pros:
  - Drop behavior encapsulated in the surface adapter.
- Cons:
  - Spreads physics logic across adapters and item node; harder to reason about global physics changes.
  - Increases surface adapter responsibilities.

### Option C: Central “DropFlow” helper in dragdrop adapter (least invasive but less clean)
- In `WardrobeDragDropAdapter`, if target floor is above, set the item’s velocity upward and schedule a restore on `physics_tick`.
- Pros:
  - Minimal file changes initially.
- Cons:
  - More state tracking in the dragdrop adapter; violates separation of concerns.
  - Harder to keep consistent with other physics transitions.

## Preferred direction
- Option A is the cleanest and most maintainable: physics behavior stays with the item node, adapters only decide targets.

## Modules and class changes (Option A)
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
  - Replace `_get_floor_below_item` with `_get_nearest_floor_for_item` using the new selection rules.
  - Ensure `on_pointer_up` always calls a floor drop if no slot/shelf placement occurs.
  - Use new floor selection to choose the correct floor target for upward or downward travel.
- `scripts/wardrobe/item_node.gd`
  - Add rise/fall state machine with target Y and restore logic.
  - Provide a public `start_floor_transfer(target_y: float, direction: int)` and `cancel_floor_transfer()` for pickup cases.
  - Use `_integrate_forces(state)` to drive velocity/gravity and detect target crossing.
  - Introduce a collision profile helper to switch to TRANSFER and restore DEFAULT.
- `scripts/ui/floor_zone_adapter.gd` (if needed)
  - Minimal or no changes; still used to place/drop once the item reaches the floor.

## Tests
- No existing tests cover drag/drop physics flow. Current requirement is to run canonical tests after change.

## Risks
- Upward motion requires pass-through or one-way collisions; otherwise the item can stick below a floor.
- If upward travel is too slow/fast, it may feel odd; should be tuned with a single constant.

## Open questions (resolved by user)
- Floor selection: prefer below; else nearest by absolute delta (deterministic tiebreaks).
- Upward movement must be physical (no teleport); use pass-through or one-way.
- Desk slots always accept items.

## References (Godot 4.5)
- One-way collision: https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
- RigidBody2D integration: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
