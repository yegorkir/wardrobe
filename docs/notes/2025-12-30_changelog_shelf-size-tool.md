# Changelog: Shelf Size Tool Sync

- Enabled `@tool` execution for `ShelfSurfaceAdapter` to update shelf sizing live in the editor.
- Added exported `drop_area_height_px` with editor sync to control `DropArea/CollisionShape2D` height.
- Added editor sync guard and initialization to avoid recursive updates and preserve existing shape height.
- Replaced `field` usage with explicit backing variables to fix GDScript parse errors.
- Keep DropArea bottom edge fixed when changing drop area height; only grow/shrink from the top.
