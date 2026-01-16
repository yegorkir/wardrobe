# Queue Entry Animation

## Goal
Extend the queue HUD entry animation so new clients appear from the right edge near QueueKpis and travel left into their slot, making the motion noticeable and readable.

## Approach
- Animate the newly created queue item from the QueueKpis right edge to its final slot position.
- Use `CanvasItem.set_as_top_level(true)` during the tween so the item can move independently of the HBoxContainer layout, then restore it afterward.
- Animate queue departures by moving the client down toward the desk, scaling to half size, and fading out over 0.4s.
- Animate desk arrivals by moving the client down into place while scaling from half size to normal and fading in (after a 0.4s delay).

## References
- CanvasItem `top_level`: https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html#class-canvasitem-property-top-level
- Tween (parallel tweens + intervals): https://docs.godotengine.org/en/4.5/classes/class_tween.html
