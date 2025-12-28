# 2026-01-10 — Plan: Step 6.1 no one-way floor transfer + landing behavior

## Invariants
- Floor surfaces do not use one-way collision; upward transfer goes through phase-specific collision masks on ItemNode.
- RISE phase ignores FLOOR collisions; FALL phase collides with FLOOR only (no ITEM/SHELF).
- Landing is declared only at the physics-tick stable point (support ray + within surface bounds + snap).
- ItemLanded emits both:
  - debug event `ITEM_LANDED`
  - app event `EVENT_ITEM_LANDED` (ShiftLog)
- LandingOutcome is computed in app layer and applied in UI adapters.
- Debug logs are gated by one global bool with early return (no formatting work when disabled).

## Transfer phases (Floor transfer)
1) RISE
   - Collision mask ignores FLOOR.
   - Drive vertical velocity upward until `item_bottom_y <= floor_collision_y - eps`.
   - Before enabling FLOOR collisions, snap to a safe bottom (>= eps above floor).
2) FALL
   - Collision mask includes FLOOR only.
   - Gravity on; landing requires bottom >= target_y - eps and support ray hit.
   - Failsafe: if bottom continues below plane for N frames after enabling FLOOR, snap/freeze and emit debug event.
3) LAND/SETTLE
   - Settle check via WardrobePhysicsTickAdapter.
   - Freeze/snap in stable pipeline; emit ItemLanded + outcome.

## Landing definition
- “Landing” is the moment an item becomes stable on a surface via the physics tick:
  - support ray hits a surface body
  - item is within surface bounds
  - snap delta <= epsilon
- Surface kind resolved via WardrobeSurface2D (Floor/Shelf/Unknown).

## Event payload structure
`EVENT_ITEM_LANDED` payload:
- `item_id: StringName`
- `item_kind: StringName`
- `surface_kind: StringName` (FLOOR/SHELF/UNKNOWN)
- `cause: StringName` (DROP/REJECT/ACCIDENT/COLLISION)
- `impact: float` (proxy: abs(vy) at stabilization)
- `tick: int` (0 if not tracked)

## Acceptance checklist (short)
- Floors are not one-way; upward transfer uses collision masks.
- Item does not tunnel through floor after transfer end.
- Drop/transfer and passive fall both emit ItemLanded (debug + app event).
- LandingOutcome computed by item_kind and applied in UI.

## References (Godot 4.5)
- RigidBody2D (integrate forces / gravity / freeze): https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- Collision layers & masks: https://docs.godotengine.org/en/4.5/tutorials/physics/physics_introduction.html#collision-layers-and-masks
- PhysicsDirectSpaceState2D (ray/shape queries): https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
