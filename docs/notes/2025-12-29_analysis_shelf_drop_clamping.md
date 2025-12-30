# Analysis: Shelf Drop Clamping

## Problem summary
- Issue: x_out_of_bounds when dropping items onto shelf surfaces when `item.size_su` is close/equal to `shelf.capacity_su`.
- Observed behavior: drop logic converts mouse position to `x_su` based on shelf origin. Even a 1px offset makes `x_su > 0`, so `x_su + size_su > capacity_su` for full-width items.
- UX impact: users aim at shelf center, but strict math requires pixel-perfect left-edge alignment for full-width items.

## Current flow (as implemented)
- UI adapter computes `x_su` and validates via placement behavior:
  - `WardrobeDragDropAdapter._try_drop_to_shelf()` uses `ShelfSurfaceAdapter.compute_x_su_for_drop()` to compute raw `x_su`.
  - `DefaultPlacementBehavior.can_place()` rejects if `x_su < 0` or `x_su + size_su > capacity_su`.
  - On reject, UI falls back to floor drop.

## Proposed solution (constrained drop in adapter)
- Keep domain/app strict: no changes to storage invariants or placement rules.
- Clamp the UI-derived coordinate before validation:
  - `max_valid_x_su = capacity_su - size_su`
  - `x_final = clampi(x_raw, 0, max_valid_x_su)`
- Pre-check capacity: if `size_su > capacity_su`, reject immediately (no clamp; no placement attempt).
- Feed `x_final` into `can_place()` and, if accepted, place with `x_final`.

## Architecture impact
- Adapter responsibility: translate fuzzy input into valid strict coordinates.
- Domain responsibility: remain strict and reject invalid coordinates; no behavior change.
- Presentation impact: full-width items may snap left when user drops near right edge; accepted as intended UX.

## Alternatives considered
1) Clamp inside `ShelfSurfaceAdapter.compute_x_su_for_drop()`.
   - Pros: centralized calculation.
   - Cons: hides input correction in a utility; less explicit adapter responsibility.
2) Relax domain rules to allow overflow and auto-correct.
   - Rejected: violates strict invariants and SSOT rules.

## Requirements
- If `size_su > capacity_su`: drop rejected (no shelf placement).
- If `size_su == capacity_su`: any drop within shelf clamps to `x=0` and succeeds.
- If `size_su < capacity_su`: drops clamp to `[0, capacity - size]` and then validate against existing intervals.
- If clamped position still collides/invalid: use existing rejection behavior (fall back to floor).

## Files and code points
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
  - `_try_drop_to_shelf()` (compute `x_su`, capacity/size validation, clamp).
- `scripts/ui/shelf_surface_adapter.gd`
  - No change expected; referenced for context.

## Implementation plan
1) Confirm drop behavior decisions (oversize handling, clamp logging, shelf-only scope).
2) Update `_try_drop_to_shelf()` to pre-check capacity and clamp `x_su` before validation.
3) Keep placement validation strict; only adjust adapter coordinate.
4) Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` and report results.
5) Manual verification in scene: full-width, partial-width, and oversize cases.

## Testing impact
- No direct unit tests currently cover shelf drop clamping; functional coverage is minimal.
- Add/extend functional tests if available for drag/drop placement; otherwise manual verification is required.
- Canonical test command (must be used):
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Open questions
- Should oversize items (size > capacity) fall back to floor drop or fail completely?
- Should clamping be applied only when drop is inside shelf bounds, or also when within a near-hover threshold?
- Should we log a debug message when clamping occurs (to aid in QA)?

## References
- `clampi` (GDScript global function):
  - https://docs.godotengine.org/en/4.5/classes/class_@globalscope.html#class-globalscope-method-clampi
