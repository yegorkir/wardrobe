# Changelog: shader-tween-param (2026-01-17)

- Located the ghost item tween as the source of repeated `ShaderMaterial::set_shader_parameter` argument errors.
- Added `StringName` constants for ghost shader parameters and updated `scripts/wardrobe/item_node.gd` to read them.
- Replaced the direct `set_shader_parameter.bind(...)` tweens with a helper that passes `(param, value)` in the correct order.
- Renamed the helper parameter to avoid the CanvasItem `material` shadowing warning.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0; existing CA cert error line remains).
- Launched Godot with `"$GODOT_BIN" --path .` and confirmed the shader tween error spam no longer appears in the startup log.
