# 2026-01-10 — Transfer isolation (Solution A)

## Summary
- Added a dedicated transfer-fall physics layer so transfer items only collide with floor surfaces during fall, while normal items never scan that layer.
- Floor surfaces now include the transfer-fall layer in their collision masks to guarantee landing during transfer.
- Transfer diagnostics now emit structured debug events for profile application and sink detection under the global debug flag.

## Rationale
- Isolating transfer-fall collisions prevents item-to-item wake/hit during transfer while preserving reliable floor contact.
- Structured logs make it easy to prove collision isolation and detect floor sink regressions without relying on ad-hoc prints.

## References
- Godot 4.5 physics introduction (collision layers/masks): https://docs.godotengine.org/en/4.5/tutorials/physics/physics_introduction.html#collision-layers-and-masks
- Godot 4.5 `RigidBody2D` class reference: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
