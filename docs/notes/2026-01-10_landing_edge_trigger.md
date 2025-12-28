# Landing edge-trigger + landing await review

## Context
- Landing events now emit only on UNSTABLE->STABLE transitions; unstable/wake paths re-arm the landing guard.
- Test parse error in floor transfer helper fixed (variable rename) so GdUnit can load the suite.

## Notes
- Landing handling is driven by physics ticks and item stability; see `RigidBody2D` basics and sleep/freeze behavior: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- Frame waits in tests rely on `SceneTree.physics_frame`/`process_frame`: https://docs.godotengine.org/en/4.5/classes/class_scenetree.html
