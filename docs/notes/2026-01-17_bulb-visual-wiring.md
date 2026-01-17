# Bulb Visual Wiring

## Goal
Ensure BulbVisual sprites switch correctly by wiring BulbLightRig to drive BulbVisual, which then forwards state to LightSwitch.

## Decisions
- Wire BulbLightRig `external_visual_path` to the corresponding BulbVisual instance so `set_is_on` is called.
- Keep BulbVisual forwarding `set_is_on` to the LightSwitch reference.

## References
- https://docs.godotengine.org/en/4.5/classes/class_nodepath.html
- https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
