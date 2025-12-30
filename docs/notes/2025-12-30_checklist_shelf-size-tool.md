# Checklist: Shelf Size Tool Sync

- [x] Review `ShelfSurfaceAdapter` usage and locate shelf size + drop area sizing logic.
- [x] Add `@tool` and editor-sync setters for shelf width.
- [x] Add `drop_area_height_px` export and hook it into `DropArea/CollisionShape2D` sizing.
- [x] Guard editor sync to avoid recursive updates and sync child nodes safely.
- [x] Write task note and include Godot 4.5 reference link.
- [x] Fix `@export` setters to use backing fields instead of `field` to satisfy the parser.
- [x] Keep DropArea bottom edge fixed when adjusting height; only move the top edge.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (log contained `ERROR: Condition "ret != noErr" is true. Returning: ""`).
- [x] Run `"$GODOT_BIN" --path .` (failed: `Sandbox(Signal(6))`).
