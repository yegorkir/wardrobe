# 2025-12-28 — Checklist: Step 6.1 surface placement

- [x] Add placement types/flags and strict validation behavior in app layer.
- [x] Implement ShelfSurface adapter with interval storage, drop mapping, and tweened placement.
- [x] Implement FloorZone adapter with deterministic scatter and clamped bounds.
- [x] Extend DnD to pick/drop shelf/floor items using point query without touching slot logic.
- [x] Add ItemNode pick Area2D and helper sizing method.
- [x] Place ShelfSurface_1 and FloorZone in WorkdeskScene StorageHall with editable bounds.
- [x] Run tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (log shows an audio init error line, exit code 0).
