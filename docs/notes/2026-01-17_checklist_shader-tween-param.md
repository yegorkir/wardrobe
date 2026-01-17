# Checklist: shader-tween-param (2026-01-17)

- [x] Identified the ghost appearance tween as the source of the `set_shader_parameter` argument errors.
- [x] Added `StringName` constants for ghost shader parameter keys.
- [x] Implemented a helper to call `set_shader_parameter(param, value)` with correct argument order and updated the tweens to use it.
- [x] Renamed helper parameters to avoid CanvasItem `material` shadowing warnings.
- [x] Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0; existing CA cert error line remains).
- [x] Launched Godot with `"$GODOT_BIN" --path .` and verified the shader tween error spam is gone.
