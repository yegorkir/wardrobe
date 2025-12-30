# 2025-12-30 — Drop fall-through shelf

## Goal
- Make surface drops fall via physics when released outside shelf drop zones.
- Ensure drops released above a shelf pass through shelf/items without collisions until below the shelf plane.

## Decisions
- Use a temporary pass-through window on `ItemNode` that disables collisions until the item center passes a target Y.
- Use shelf drop-rect bounds to detect "released above shelf" cases and select the nearest shelf under the cursor X.
- Route floor drops through the fall path to avoid teleporting to the floor surface.

## Notes
- Pass-through uses collision layer/mask switching on the item, restoring once it crosses the target Y.
- Floor drop uses `drop_item_with_fall` to keep physics-driven motion.

## References
- Godot 4.5: RigidBody2D (collision and physics behavior): https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- Godot 4.5: CollisionObject2D (layers/masks): https://docs.godotengine.org/en/4.5/classes/class_collisionobject2d.html
