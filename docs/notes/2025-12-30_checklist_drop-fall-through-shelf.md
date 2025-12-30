# 2025-12-30 — Checklist: Drop fall-through shelf

- [x] Inspect drag/drop and floor/shelf adapters to locate teleport-to-floor placement paths.
- [x] Add pass-through state on `ItemNode` with restore-on-Y-crossing logic for temporary collision disabling.
- [x] Expose shelf drop-rect bounds in world space for release-above-shelf detection.
- [x] Update floor drop flow to call the fall-based drop and apply pass-through when cursor is above a shelf drop rect.
- [x] Extend pass-through detection to use shelf bounds plus item width padding so side releases above shelves ignore collisions.
- [x] Switch to floor-targeted pass-through so drop-to-floor ignores all shelves and items regardless of lateral impulse.
- [x] Enlarge pick area during pass-through to give players a larger rescue window.
- [x] Drop non-hookable items to the floor when released above a hook slot.
- [x] Switch floor drop helper to use the fall path to remove teleporting to surface Y.
- [x] Record decisions and Godot 4.5 references in `docs/notes/2025-12-30_drop-fall-through-shelf.md`.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot with `"$GODOT_BIN" --path .`.
