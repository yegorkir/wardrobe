# Design Note: Iteration 6 Curtain Visuals

## Goal
Align curtain visuals with the iteration 6 plan: two opposing accordion curtains with 6 segments each, driven by the curtain open ratio.

## Implementation
- Each curtain uses 12 `ColorRect` segments with slight color variation to cover half of the 982px light zone height (40px segment height x 12 = 480px).
- `Segment1` is anchored to the top/bottom edge of the curtain zone collision shape.
- `Segment2..Segment12` move with a speed gradient so the last segment moves fastest, creating an accordion effect that reveals or covers space.
- Segment travel is clamped to the curtain zone midline so top and bottom strips do not cross when opening.
- Each segment now clamps against the midline per-frame so individual segments never cross even if travel exceeds the remaining gap.
- Curtain visuals anchor to the fixed CurtainZone shape; LightZonesAdapter no longer mutates the collision shape, only the LightVisual, so the light gap is independent of curtain anchors.
- LightZonesAdapter now prefers the curtain adapter's gap rect so the light zone matches the actual space between curtains.
- The light gap is clamped to the base curtain zone rect to prevent any spill outside the curtain bounds.
- Curtain visuals are now composed from `CurtainStrip.tscn`, and `CurtainRig.tscn` bundles the two curtains with the curtain zone.

## References
- Node2D.position (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_node2d.html#class-node2d-property-position
- ColorRect (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_colorrect.html
- CollisionShape2D (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
