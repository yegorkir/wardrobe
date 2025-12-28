# 2025-12-28 — Step 6.1 (Codex plan): Surface shelves + Floor (strict placement)

## Goal
- Add SHELF surface placement with strict (no auto-fit) drop rules.
- Invalid drop falls to FloorZone and remains pickable (player must recover it manually).
- Placement uses logical units with fixed-point sub-units (UNIT_SCALE=1000).

## Non-goals
- No physics simulation.
- No breakable items / penalties.
- No archetype effects (those are Step 6.2).
- No refactors of Step 4/5 beyond minimal wiring.

---

## Allowlist (strict)
### New
- `scripts/app/wardrobe/placement/default_placement_behavior.gd` (RefCounted, pure)
- `scripts/app/wardrobe/placement/placement_types.gd` (enums/bitflags + UNIT_SCALE)
- `scripts/ui/shelf_surface_adapter.gd` (UI-only, caches nodes, applies placements)
- `scripts/ui/floor_zone_adapter.gd` (UI-only)

### Edit (minimal)
- `scenes/screens/WorkdeskScene.tscn` (add FloorZone + at least one ShelfSurface)
- `scripts/ui/workdesk_scene.gd` (wiring: on drop decide shelf vs floor)
- (optional) `scripts/ui/wardrobe_dragdrop_adapter.gd` (only if needed to route “drop target kinds”)

### Forbidden
- `scripts/domain/**`
- Any auto-fit or snap logic.
- Any attempt to merge Step 6.1 with archetype effects.

---

## Task 0 — Discovery
- Locate current DnD drop resolution point (where we decide “place into slot”).
- Confirm how ItemNode parenting is managed (avoid conflicts with existing visuals adapters).

Stop condition:
- If routing a “drop target kind” (SHELF/FLOOR) can’t be done without refactor, add a minimal adapter layer in WorkdeskScene only.

---

## Task 1 — Placement math (pure) + anti-float footgun
Create `placement_types.gd`:
- `const UNIT_SCALE = 1000`
- `enum SlotKind { HOOK, SHELF, FLOOR }`
- `enum PlaceFlags { HANG=1, LAY=2 }`

Create `default_placement_behavior.gd`:
Input:
- `slot_kind`, `place_flags`, `size_su`
- for HOOK: `is_empty`
- for SHELF: `capacity_su`, `x_su`, `existing_intervals` (Array of `{x_su:int, size_su:int}`)
  Output:
- `{ ok: bool, reason: String }`

Rules:
- HOOK: ok iff HANG and empty
- SHELF: ok iff LAY and STRICT interval valid (bounds + overlap)
- FLOOR: always ok

Interval rules (STRICT):
- bounds: `0 <= x_su` and `x_su + size_su <= capacity_su`
- overlap: reject if `x < b && x+size > a` where `[a,b)` is existing interval

No floats in stored state: x_su/size_su/capacity_su are int.

---

## Task 2 — ShelfSurface adapter (strict, no auto-fit)
- ShelfSurface has:
    - `capacity_units` (float, config)
    - `shelf_length_px` (float/int, local width for mapping)
- Compute:
    - `capacity_su = round(capacity_units * UNIT_SCALE)`
- On drop compute x_su using integer-friendly mapping:
    - take `x_px` as local X of item left edge relative to ShelfSurface
    - `x_px_i = floor(x_px)` (fixed policy)
    - `x_su = floor(x_px_i * capacity_su / shelf_length_px)`
      This avoids “45.00001” rounding into a fail-by-1-subunit.

No snapping, no shifting, no first-fit.

Shelf state:
- `placements_by_shelf_id: Array[{ item_id, x_su, size_su }]`

---

## Task 3 — FloorZone adapter (drop-to-floor + scatter)
- FloorZone is a container area at the bottom of the screen.
- On failed shelf drop:
    - move item to FloorZone
    - tween to floor y
    - keep it pickable (ItemNode remains with Area2D)
- Add small `x_offset` on drop (random or deterministic) so items don’t stack into one pixel.

Scatter constraints (anti-footgun):
- x_offset must be bounded by FloorZone width:
    - compute FloorZone local bounds (min_x..max_x)
    - clamp final x within `[min_x + margin, max_x - margin]`
- Use a small spread (e.g., ±8..±24 px), not “random huge”.
- `margin >= half hitbox width`, so items remain pickable near edges.

---

## Task 4 — Z-order / y-sort for shelf & floor (must)
Problem:
- Without slots, draw order may depend on child order → visual chaos.

Solution (pick one, simplest for current scene):
- Prefer enabling y-sort on Shelf/Floor containers, OR
- Set `item_node.z_index = int(item_node.global_position.y)` after placement/move.

Confirm CursorHand still renders above everything (existing Step 4 z-index rules remain).

---

## Task 5 — Pick routing: choose topmost item (must)
Problem:
- Overlapping Area2D makes ambiguous picks.

Solution (preferred):
- On pick attempt, do a single point query (physics intersect_point) to collect hit item areas.
- Choose the topmost candidate:
    - highest z_index wins
    - tie-break by higher global_position.y or last in returned list (deterministic rule)
- Start drag only for that item_id.
- Do NOT rely on multiple Area2D signals firing.

---

## Task 6 — Drop routing in WorkdeskScene (minimal integration)
- When dropping:
    - determine target under cursor: shelf vs existing slot vs none
    - if shelf:
        - compute x_su
        - validate via DefaultPlacementBehavior against existing intervals
        - if ok: record placement + parent/animate to shelf
        - else: parent/animate to FloorZone + record floor item
    - if none:
        - drop to floor (optional; if implemented, same FloorZone path)

---

## DoD
- Strict shelf placement works; invalid drop falls to floor and is pickable.
- No menus, no snap, no auto-fit.
- Pick selects topmost item when overlapping.
- Stable draw order on shelf and floor (y-sort/z_index).
- Scatter does not throw items off-screen/outside FloorZone.
- No regressions in Step 4/5.
