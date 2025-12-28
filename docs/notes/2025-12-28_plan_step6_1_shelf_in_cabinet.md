# 2025-12-28 — Plan: ShelfSurface in StorageCabinetLayout + lay/hang validation

## Goals
- Move ShelfSurface into `StorageCabinetLayout_Simple.tscn` (replace `Pos1` hook).
- Support configurable shelf width with auto fallback.
- Add new client items with LAY/HANG rules and visuals.
- Enforce HANG/LAY rules on hooks/shelves.

## Steps
1. **Prefab + scene wiring**
   - Create `scenes/prefabs/shelf_surface.tscn` using `ShelfSurfaceAdapter`.
   - Add DropArea/CollisionShape2D, ItemsRoot, DropLine, and ColorRect (black 4px) aligned to bottom of DropArea.
   - Add exports for `shelf_length_px` and optional `auto_from_cabinet` toggle.
   - Update `StorageCabinetLayout_Simple.tscn`: remove `Slots/Pos1` hook, instance shelf prefab at same transform.

2. **Slot ID assignment robustness**
   - Update `scripts/wardrobe/storage_cabinet_layout.gd` to skip non-slot nodes in `Slots` without warnings.
   - Keep stable slot IDs for remaining hooks.

3. **Placement capability map + hook validation**
	- Add `ItemType` entries for BOTTLE/CHEST/HAT (and visuals) in `ItemNode` + `WardrobeItemVisualsAdapter`.
	- Add a UI-layer map of item type -> place_flags (HANG/LAY) in a dedicated config script (not in `WardrobeDragDropAdapter`) for scalability.
	- Before executing hook slot interaction, validate HANG; if not allowed, reject without modifying state.
	- Ensure shelf validation uses LAY flag per item.

4. **Client item configuration**
   - Update `WardrobeStep3SetupAdapter._make_demo_client` to assign configured item types per client.
   - Define deterministic mapping (e.g., client index -> item type) to test mixed behavior.
   - Confirm desk spawn/pickup flows still work with new items.

5. **Clean-up**
   - Remove `ShelfSurface_1` from `WorkdeskScene.tscn` and adjust wiring to collect shelves from cabinet prefab.

6. **Verification**
	- Run tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
	- Manual check: drag LAY‑only to hook (reject), HANG‑only to shelf (reject), HANG|LAY allowed on both.
	- Visual check: ensure item bottom aligns with DropLine (no sinking into the 4px shelf bar).
