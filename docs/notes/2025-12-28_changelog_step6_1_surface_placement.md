# 2025-12-28 — Changelog: Step 6.1 surface placement

- Added placement primitives in `scripts/app/wardrobe/placement/placement_types.gd` and strict validation in `scripts/app/wardrobe/placement/default_placement_behavior.gd`.
- Introduced `scripts/ui/shelf_surface_adapter.gd` to manage shelf bounds, interval storage, and animated drops with y-sort.
- Introduced `scripts/ui/floor_zone_adapter.gd` to handle floor bounds, deterministic scatter, and animated drops with y-sort.
- Extended DnD in `scripts/ui/wardrobe_dragdrop_adapter.gd` to pick/drop shelf/floor items via point query while keeping slot interactions intact.
- Added pickable Area2D to `scenes/prefabs/item_node.tscn` and exposed half-width helper in `scripts/wardrobe/item_node.gd`.
- Added ShelfSurface_1 and FloorZone nodes to `scenes/screens/WorkdeskScene.tscn` with editable bounds and drop lines, and wired them in `scripts/ui/workdesk_scene.gd`.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log contains an audio init error line).
- Fixed strict typing warnings/errors in surface pick/drop helpers and fixed-point mapping for shelf/floor adapters.
