# 2026-01-17 — Analysis: reduce StorageCabinetLayout_Simple count in CabinetsGrid

## Context
- Goal: understand what must change to reduce the number of `StorageCabinetLayout_Simple` instances inside `CabinetsGrid`.
- Scope: Workdesk scene uses `scenes/prefabs/CabinetsGrid.tscn` as a prefab instance.

## Current wiring (facts)
- `scenes/prefabs/CabinetsGrid.tscn` instances `StorageCabinetLayout_Simple.tscn` as direct children with explicit `cabinet_id`.
- `scripts/wardrobe/storage_cabinet_layout.gd` assigns slot IDs based on `cabinet_id` + position index.
- `scripts/wardrobe/cabinets_grid.gd` collects cabinet slots by `slot_id` prefix `Cab_` and suffix `_SlotA/_SlotB` and assigns ticket symbol indices by sorted slot ID.
- `scripts/ui/wardrobe_world_setup_adapter.gd` can query `CabinetsGrid.get_ticket_slots()` if the grid node has that method; otherwise it falls back to scanning all `WardrobeSlot` nodes and filtering by the same `Cab_` + `_SlotA/_SlotB` rule.
- `scripts/ui/wardrobe_step3_setup.gd` seeds tickets into whatever cabinet slots are discovered; it does not assume a fixed count.

## Answer (high level)
- To reduce the number of cabinet layouts, you typically only remove or disable the extra cabinet nodes in `scenes/prefabs/CabinetsGrid.tscn` (or replace with fewer instances).
- `scripts/wardrobe/cabinets_grid.gd` does not need changes unless you want to change how ticket symbol indices are assigned or want a different slot discovery rule.
- The main functional impact is fewer slots, which means fewer seeded tickets in Step 3 (expected).

## Potential pitfalls / constraints
- Keep `cabinet_id` unique for every remaining cabinet instance; slot IDs are derived from it.
- Do not change `_SlotA/_SlotB` suffixes: ticket slot discovery relies on them.
- If the Workdesk scene overrides the `CabinetsGrid` script to `null`, the grid script will not run and ticket symbol assignment will only happen via the fallback in `WardrobeWorldSetupAdapter`.

## Architecture impact
- Presentation only: removing instances changes layout and capacity but not domain/app logic.
- Slot discovery remains adapter-driven via `WardrobeWorldSetupAdapter` and relies on slot ID conventions.
- Symbol assignment is tied to stable sorting of slot IDs; removing cabinets changes symbol distribution but does not break determinism.

## Options
1) Scene-only edit: remove the extra `Cabinet_*` nodes from `scenes/prefabs/CabinetsGrid.tscn`.
2) Runtime toggle: keep nodes but disable (e.g., `visible = false` or remove from scene tree in `_ready`) if you want to re-enable later via code.
3) New prefab: create an alternate grid prefab with fewer cabinets and swap the instance in `WorkdeskScene`.

## Plan (if we implement)
1) Decide which cabinets to keep/remove and whether the change is permanent or toggleable.
2) Update `scenes/prefabs/CabinetsGrid.tscn` to remove or disable the selected cabinet nodes.
3) (Optional) Adjust positions for spacing if you want a compact layout.
4) Validate slot discovery by inspecting the ticket slot list at runtime.
5) Run canonical tests and launch Godot once.

## Open questions
- Confirmed candidates to remove: `Cabinet_004`, `Cabinet_003`, `Cabinet_001`, `Cabinet_002`.
- Pending: should removal be permanent in `scenes/prefabs/CabinetsGrid.tscn` or toggleable at runtime?
- Pending: is a reduced number of seeded tickets acceptable for Step 3, or should we inject extra tickets elsewhere?

## Execution plan (proposed)
1) Confirm scope: permanent removal vs runtime toggle, and confirm acceptable reduction in seeded tickets.
2) Edit `scenes/prefabs/CabinetsGrid.tscn` to remove or disable `Cabinet_004`, `Cabinet_003`, `Cabinet_001`, `Cabinet_002`.
3) If needed, tighten layout by adjusting remaining cabinet positions to keep spacing consistent.
4) Verify slot discovery via `WardrobeWorldSetupAdapter.get_cabinet_ticket_slots()` during runtime.
5) Run canonical tests and launch Godot once per repo policy.
