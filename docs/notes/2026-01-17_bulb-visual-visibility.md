# Bulb Visual Visibility

## Goal
Ensure the BulbVisual prefab starts with only one sprite visible so on/off changes are perceptible.

## Decisions
- Default BulbOn to hidden in the prefab so the off state is clearly visible at startup.
- Resolve the external visual from a NodePath to avoid editor-time node assignment issues.

## References
- https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
- https://docs.godotengine.org/en/4.5/classes/class_sprite2d.html
