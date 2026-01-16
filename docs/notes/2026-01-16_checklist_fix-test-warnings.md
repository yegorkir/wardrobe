# 2026-01-16 — Checklist: fix test warnings

- [x] Reviewed test-run warnings and identified class-name shadowing from test constants.
- [x] Renamed test preloads to `*Script` and updated usages to remove class-name conflicts.
- [x] Removed unused preloads that only contributed warnings.
- [x] Fixed narrowing conversion warnings in aura transfer tests by using integer stage literals.
- [x] Renamed runtime preloads and cleaned runtime warning sources (unused `_light_zone`, shadowed `material`, unused curtain ratio parameter, floor selection naming).
- [x] Fixed indentation in `ZombieExposureSystem.tick` after refactor.
- [ ] Run `gdscript_diag.get_diagnostics` for edited test scripts (tool not available in this session).
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (suite passes; stderr includes `ret != noErr` engine error).
- [x] Launch Godot with `"$GODOT_BIN" --path .` (timed out after 10s but project boot logged).
