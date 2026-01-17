# Desk light items bugfix (2026-01-17)

## Context
Desk/service light is wired and visually turns on, but client items on the desk are not considered "in light" unless they are near the bulb center.

## Repro
- Integration coverage in `tests/integration/light/test_workdesk_light_zones_scene.gd` now asserts the service bulb collision zone matches the configured `zone_width`/`zone_height`.
- Before the fix, the zone stays at the prefab default size, so items positioned within the intended desk light area may still be outside the effective light rect.

## Root cause
`BulbLightRig` only applied `zone_width`/`zone_height` in editor runs. At runtime the collision shape kept the prefab default (`100x100`), so the service light zone was too small and `LightZonesAdapter.is_item_in_light()` returned false for most desk positions.

## Fix
- Apply `_update_zone_geometry()`, `_update_visual_params()`, and `_update_visual_layout()` in `_ready()` for runtime as well as editor.
- Extend the workdesk light integration test to assert the service zone shape matches the configured size.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`

## Docs
- Godot 4.5 `Node._ready()`: https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-ready
- Godot 4.5 `RectangleShape2D`: https://docs.godotengine.org/en/4.5/classes/class_rectangleshape2d.html
