# 2026-01-13 Changelog: Runtime Logging (Vampire/Zombie)

## Summary
- Moved Godot runtime log output to the repo at `/.godot/logs/godot.log` via `project.godot`.
- Added runtime log lines for vampire and zombie exposure stages, including light sources and aura rate.
- Confirmed logs are written in `/.godot/logs/` and include new exposure events.

## Details
- `VAMPIRE_STAGE_COMPLETE` now logs `item`, `stage`, `loss`, and `sources` (light source IDs such as `curtain_main` / `bulb_row0` / `bulb_row1`).
- `ZOMBIE_STAGE_COMPLETE` now logs `item`, `stage`, `loss`, and `rate` (effective aura exposure rate).
- `stage` is the exposure stage counter incremented when the exposure threshold is crossed; it continues to advance even when loss is zero (quality already reduced to minimum).

## Validation
- Ran tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; existing warnings remain).
- Launched Godot: `"$GODOT_BIN" --path .` (runtime logs captured in `/.godot/logs/`).

## References
- Godot 4.5 data paths (`user://` vs `res://`): https://docs.godotengine.org/en/4.5/tutorials/io/data_paths.html
