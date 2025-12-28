# 2025-12-28 — Analysis: ShelfSurface in StorageCabinetLayout + lay/hang validation

## Problem summary
- Replace hook position `Pos1` in `StorageCabinetLayout_Simple.tscn` with a shelf surface prefab.
- Shelf width should be configurable; if unset, auto-derive from cabinet sprite width in `_ready()`.
- Add new client items with size + placement behavior (HANG/LAY) and ensure hook placement rejects non‑HANG items.
- Remove now-unneeded WorkdeskScene shelf if shelf is moved into the cabinet prefab.

## Current state (important)
- `StorageCabinetLayout_Simple.tscn` uses `scripts/wardrobe/storage_cabinet_layout.gd` to assign slot IDs to SlotA/SlotB children of `Slots`.
- Slot IDs are required for storage: `WardrobeStorageState` and `WardrobeInteractionService` index items by slot_id.
- DnD uses slot_id as the primary key in commands and events. Removing IDs would break pick/put/swap and desk events.

## Questions raised
- “Can we remove IDs or move to signals?”
  - Signals could be used to announce slot presence, but IDs are still required as stable keys in `WardrobeStorageState` and interaction events. Replacing IDs would be a refactor across domain/app adapters and not needed for this task.
  - Minimal change: keep IDs but update `storage_cabinet_layout.gd` to ignore shelf nodes inside `Slots` so it does not warn.

## Requirements (from user)
- ShelfSurface is a prefab (`scenes/prefabs/shelf_surface.tscn`) inserted into `Slots` at `Pos1`.
- Shelf width is configurable; if config is absent, compute from cabinet sprite width and scale at runtime.
- New items:
  - `BOTTLE`: 1 su, 15 px, LAY‑only.
  - `CHEST`: 2 su, 30 px, LAY‑only.
  - `HAT`: 3 su, 45 px, HANG|LAY.
  - Existing `COAT`: HANG‑only.
- Clients should be configured with these items deterministically (manually assigned in a config table, no RNG).
- Hooks must reject non‑HANG items; shelves must reject non‑LAY items.

## Architecture impact
- **Adapters (UI layer)**: placement validation currently exists for shelves only. Hook placement is still driven by slot interactions; needs a placement behavior check before executing the slot interaction when holding an item.
- **Domain/app**: keep as-is; do not move placement rules into domain. Only add adapter-side validation gates.
- **Prefab design**: `ShelfSurface` prefab should expose DropArea (RectangleShape2D) and a 4px black ColorRect at bottom edge. DropLine should align with top of that ColorRect. Placement must respect item visual bottom (Sprite centered vs bottom anchored) to avoid sinking.
- **Item type scalability**: there is no `ItemResource`/item metadata system in the repo. For now, place_flags and size_units should live in a dedicated config script (static dictionary) instead of in `WardrobeDragDropAdapter`.

## Proposed solution (high-level)
1. **Shelf prefab**
   - Create `scenes/prefabs/shelf_surface.tscn` (Node2D) using `ShelfSurfaceAdapter`.
   - Nodes: `DropArea/CollisionShape2D`, `ItemsRoot`, `DropLine`, `VisualBar` (ColorRect).
   - Add `@export var shelf_length_px: float = 0.0` (0 = auto).
   - In `ShelfSurfaceAdapter._ready()`, if `shelf_length_px <= 0`, derive from CabinetSprite width and assign to DropArea size.

2. **StorageCabinetLayout_Simple changes**
   - Remove `Pos1` hook slots and instance the shelf prefab in `Slots` at the same transform.
   - Update `storage_cabinet_layout.gd` to skip children that are not slot containers (no SlotA/SlotB), without warnings.

3. **Placement capability (HANG/LAY) for items**
   - Add a UI-layer map: `ItemType -> place_flags`, matching the list above.
   - Gate hook interaction in `WardrobeDragDropAdapter`:
     - When holding item and hovering hook slot, validate HANG flag before executing slot interaction.
     - If not HANG, reject (no action). Optionally show feedback later.
   - Shelf already validates LAY; confirm it uses place_flags per item.

4. **Client items configuration**
   - Extend `WardrobeStep3SetupAdapter._make_demo_client` to create additional items per client.
   - Decide which item is used for dropoff/pickup flows (currently coat for dropoff, ticket for pickup). Likely:
     - Replace coat with one of the configured items (COAT/BOTTLE/CHEST/HAT) per client to test mixed behavior.
   - Ensure item kind and visuals are updated in `WardrobeItemVisualsAdapter` and `ItemNode.ItemType`.

## Risks & mitigations
- **Slot IDs**: Removing or refactoring IDs is high-risk. Keep IDs and only skip non-slot nodes.
- **Visual/logic mismatch**: auto shelf width from sprite must respect scale; clamp to minimums.
- **Mixed item behavior**: Hook interactions must block LAY‑only items; otherwise users can hang bottles.

## Testing notes
- Existing tests should be run via Taskfile after changes.
- Potential missing tests: no unit tests cover new placement flags or demo item distribution; manual verification recommended.
