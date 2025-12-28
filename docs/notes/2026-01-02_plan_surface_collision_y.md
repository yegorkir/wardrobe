# Plan: unify surface collision Y for floor landing

## Scope
- Establish a base surface API for collision-aligned Y.
- Update floor selection and transfer targets to use collision Y.
- Add one-way margin configuration for floors (Option 1+3).
- Keep existing rules: release always resolves to surface or floor, desk is always allowed.

## Affected files
- `scripts/wardrobe/surface/wardrobe_surface_2d.gd`
- `scripts/ui/floor_zone_adapter.gd`
- `scripts/ui/shelf_surface_adapter.gd` (if needed for shared contract)
- `scripts/wardrobe/surface/surface_registry.gd`
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
- `scripts/wardrobe/item_node.gd` (only if transfer target use changes)
- Notes: `docs/notes/2026-01-02_changelog_drag-release-logging.md`, `docs/notes/2026-01-02_checklist_drag-release-logging.md`

## Plan
1) Review current surface API usage
   - Identify all call sites using `get_surface_y_global()` to compute `target_y`.
   - Confirm floor surfaces have `SurfaceBody/CollisionShape2D` for collision top.

2) Extend base surface contract
   - Add `get_surface_collision_y_global()` to `WardrobeSurface2D`.
   - Default to `get_surface_y_global()` with a warning to avoid silent mismatches.

3) Implement collision-aligned Y on surfaces
   - `FloorZoneAdapter`: return top of `SurfaceBody/CollisionShape2D` if available, else fallback.
   - `ShelfSurfaceAdapter`: implement the same if shelf placements also use collision Y.

4) Route transfer targets through the new contract
   - In `SurfaceRegistry.pick_floor_for_item()` and drag/drop floor fallback, replace `get_surface_y_global()` usage with `get_surface_collision_y_global()`.
   - Keep deterministic selection logic unchanged.

5) One-way safety margin
   - In `FloorZoneAdapter._apply_physics_layers()`, set `one_way_collision_margin` to a small value (e.g., 2–4px) in addition to `one_way_collision = true`.

6) Validate behavior locally (mandatory)
   - Run: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
   - Launch: `"$GODOT_BIN" --path .`

## Acceptance criteria
- Items landing on floors no longer pass through after transfer end.
- Transfer target Y matches floor collision plane (logs show consistent bottom_y near target before landing).
- No new warnings introduced.
