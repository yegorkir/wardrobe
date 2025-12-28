# Analysis: Shelf Physics Model (Overlap/Push)

## Context
Goal: avoid "snap back" behavior when pushing items near shelf edges; keep small overlaps "alive" but not feeling like an invisible hand.

Current behavior is implemented in `scripts/ui/wardrobe_physics_tick_adapter.gd` and `scripts/ui/shelf_surface_adapter.gd`, with item mass set in `scripts/wardrobe/item_node.gd`.

## Current Model Summary
### Placement & Drag
- Drag/drop uses `ShelfSurfaceAdapter.place_item(...)` to reparent and place the item on a shelf.
- X placement is clamped to shelf bounds using COG offset (no visual half-width clamp).
- Y placement snaps the item's bottom to shelf surface (`force_snap_bottom_to_y`).

### Stability Check
Triggered via `WardrobePhysicsTickAdapter.enqueue_drop_check(...)` and `request_settle_check(...)`.
Steps in `_run_stability_check`:
- Raycast down from COG to find support surface.
- Query overlaps (shape intersection) against other items.
- If overlap exists: resolve overlap.
- If supported and COG within bounds: snap to surface on Y and mark stable.
- Otherwise: mark unstable and/or apply small torque to tip item off shelf.

### Overlap Resolve (Small vs Large)
Implemented in `_resolve_overlap` with AABB overlap metrics:
- Small overlap: apply impulse-based push.
- Large overlap: reject placement and drop item to floor.

Push details:
- Metrics computed from AABB intersection on X (width) and area ratio.
- `OVERLAP_*` thresholds decide allow/reject.
- Small overlap push uses mass-aware impulses on both items.
- The "other" item gets a reverse impulse (intended as a reactive push).

### Mass
`ItemNode` uses `item_mass` defaulted by `ItemType` and applied to `RigidBody2D.mass`.

## Observed Problem Zones
1) **Impulse exchange creates back-pressure**
- Mass-aware push applies impulses to BOTH items. The "blocking" item behind the moving item gets a reverse impulse, which then pushes the moving item back.
- This creates the "returns backward on edge" feeling even without a boundary ahead.

2) **AABB-based overlap, X-only push**
- Overlap resolution is based on AABB intersection width and area ratio, not actual contact manifolds or minimal translation vector (MTV).
- The push direction is heuristic and may not match actual contact geometry.

3) **Energy injection and repeated resolution**
- Impulses are applied during stability checks, not only at the moment of contact.
- This can reintroduce energy and lead to oscillation (move -> resolve -> move -> resolve).

4) **Placement "snap" and physics "resolve" are mixed**
- We snap Y for stability while also applying impulses for overlap. This mixes positional correction (snap) with velocity corrections (impulse) without clear separation.

## Architecture Considerations
The current model is adapter-level (UI/physics), which is OK, but the manual overlap logic effectively replaces the physics solver with heuristics. This is likely the core of "non-physical" feel.

## Options for Improvement
### Option A: One-sided correction (no neighbor impulse)
- Only the moving item receives a small push or positional correction.
- Neighbor items are not directly pushed; they only move if actual physics contacts push them.
Pros: eliminates back-pressure.
Cons: less "mutual shove" feel; might feel less "alive".

### Option B: MTV position solve for the moving item
- Compute a minimal translation vector (MTV) for the moving item and apply position correction once.
- If MTV is small -> accept, else reject/drop.
Pros: deterministic and stable, no oscillation.
Cons: less dynamic; needs MTV computation (not just AABB).

### Option C: Shape cast to find nearest non-overlap
- Shape-cast the moving item along X to the nearest valid non-overlap position.
Pros: keeps motion plausible while avoiding jitter.
Cons: more work; still heuristic.

### Option D: Pure physics on drop
- Stop manual overlap resolution, unfreeze item and let physics resolve naturally.
Pros: physically correct.
Cons: likely too chaotic; can cause large pushes/falls (violates constraints).

## Suggested Direction (Draft)
Move to Option B (player wants "live shoving" but no back-pressure):
- No manual impulses to neighbors; only the moved item gets an impulse.
- Neighbor motion comes only from physical contact, not manual reverse pushes.
- Neighbors should be woken by contact (not by direct impulse), matching "impulse transmitted -> wake -> move".
- Add a short overlap cooldown to prevent repeated micro-pushes that cause edge rollbacks.

## Tests & Validation
Tests are run via Taskfile:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once: `"$GODOT_BIN" --path .`

## References (Godot 4.5)
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- PhysicsDirectSpaceState2D: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
- PhysicsShapeQueryParameters2D: https://docs.godotengine.org/en/4.5/classes/class_physicsshapequeryparameters2d.html
