# Bulb Visual Dual Routing

## Goal
Make LightSwitch the primary input that toggles bulbs while BulbRow and BulbVisual stay in sync with the light service.

## Decisions
- Let LightSwitch toggle the LightService and listen for bulb state changes.
- Let BulbLightRig listen for bulb state changes and forward `set_is_on` to BulbVisual.

## References
- https://docs.godotengine.org/en/4.5/classes/class_nodepath.html
- https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
