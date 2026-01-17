# Desk Client Exit Animation

## Summary
- Added a client exit animation when a desk client completes service: move left, fade out, and scale down.
- Desk assignment is blocked while the exit animation runs so the slot frees only after the animation ends.

## Implementation Notes
- `WorkdeskClientsUIAdapter` tracks exiting clients by desk, starts the exit tween on `notify_client_completed`, and clears the block when the tween finishes.
- `WorkdeskScene` now treats an active exit animation as a desk-blocking condition through the existing drop-zone blocker hook.

## References
- https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-create-tween
- https://docs.godotengine.org/en/4.5/classes/class_tween.html
