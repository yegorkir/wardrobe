# Iteration 10 MVP rescope implementation notes

## Summary
Implemented iteration 10 rescope across desk service point flow, drag/drop return-to-origin, ticket rack, tray layout, and tests. This note captures key behavior and API references used during implementation.

## Key behavior details
- Return-to-origin uses a tween on `ItemNode` to move items back to their origin anchor and temporarily disables input pickable.
- Client drop zones use `Area2D` overlap validation and a simple point-inside check to resolve deliver attempts.
- Ticket rack jitter is deterministic per ticket id, persisted until ticket consumption clears the offset.

## References (Godot 4.5)
- Area2D (overlap detection, monitoring): https://docs.godotengine.org/en/4.5/classes/class_area2d.html
- Tween (return-to-origin animation): https://docs.godotengine.org/en/4.5/classes/class_tween.html
