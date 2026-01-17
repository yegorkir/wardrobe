# Bulb Visual Setup

## Goal
Finalize the `bulb_visual` prefab script so external visuals can drive it and the on/off sprites switch correctly.

## Decisions
- Expose an external visual node reference so the parent scene can wire a `LightSwitch` instance directly.
- Implement `set_is_on` to update the bulb sprites and forward the state to the external visual when present.

## References
- https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
- https://docs.godotengine.org/en/4.5/classes/class_sprite2d.html
