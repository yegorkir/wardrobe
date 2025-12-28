# Analysis: floor transfer miss / item falling through

## Context
- Items (e.g., bottle_00) rise to target floor, switch to `FALLING_TO_TARGET`, then keep accelerating downward past the floor.
- Logs show `transfer_end` fires, then item remains `SETTLING` and continues falling with increasing `y`.

## Observed behavior (from logs)
- `transfer_start` to target_y (e.g., 1095.00).
- `RISING_THROUGH` updates bottom_y until just below target.
- Switch to `FALLING_TO_TARGET`, then bottom_y increases without support hit; eventually `transfer_end` fires via forced landing.
- After `transfer_end`, item continues falling (no collision with floor).
- In newer logs, `FALLING_TO_TARGET` oscillates around target_y with small negative velocity spikes (e.g., vel_y ~= -6), then never stabilizes and eventually continues falling.

## Likely causes (hypotheses)

### H1: One-way direction or entry side is wrong
- Floor shapes are set to `one_way_collision = true`, but direction/margin might be wrong or not explicitly set.
- If the body is considered “below” the one-way plane, it will not collide while falling.
- When we snap to target_y, the body may still be slightly below the effective plane.

### H2: Transition to FALLING happens too early (item is still below the floor)
- We switch to `FALLING_TO_TARGET` when `bottom_y <= target_y + eps`.
- If `bottom_y` is computed from AABB and the floor surface is slightly above, the body might still be below the collision plane, so it never collides.
- Falling continues as if no floor existed.

### H2a: Target Y does not match actual collision plane
- `target_y` is derived from `SurfaceRef` / bounds, not from the collision shape top.
- If collision shape top is above/below `target_y` by even a few pixels, snapping to `target_y` can leave the body inside or below the collider.
- This matches the "oscillate near target then fall" symptom.

### H3: Collision profile restored but item remains inside pass-through state
- We switch to TRANSFER mask (floor-only) during transfer and restore to DEFAULT at transfer end.
- If the item remains overlapping the floor, Godot may not resolve the overlap into a stable resting state without snapping or a settle check.

### H3a: Transfer end occurs without a real support contact
- `_is_transfer_landed()` can exit via `TRANSFER_FORCE_LAND_FRAMES` even if no support ray hit occurs.
- This produces `transfer_end` while still not supported, then gravity resumes and the item continues to fall.
- Logs show `transfer_end` followed by continuous position updates downward.

### H4: Stabilization not triggered after transfer end
- `enqueue_drop_check` is called once at drop time, but `_physics_process` in `ItemNode` is paused while transfer runs.
- After transfer end, we do not explicitly request a settle check, so physics tick may not snap/mark stable again.
- The item can keep falling (no collision confirmation) and never becomes stable.

### H5: Floor surface bounds / X-filter mismatch
- The selected target floor may not be directly under the item’s current X (due to clamp/scatter or selection bounds).
- The item can fall through because the floor is elsewhere or because the support ray misses it.

### H6: One-way collision may require explicit margin or direction alignment
- `CollisionShape2D.one_way_collision` is set, but `one_way_collision_margin` is not set.
- If the item crosses the plane and ends slightly below it, one-way may never catch it.
- A too-small margin would explain why the item oscillates around target_y without settling.

### H7: Gravity/velocity clamp fights contact resolution
- In `FALLING_TO_TARGET`, velocity is clamped to `TRANSFER_FALL_MIN_SPEED`, which can fight contact resolution and cause repeated separation.
- This can prevent a stable contact from forming on a thin one-way floor.

## Option set A: Keep rules, adjust scene/physics (no gameplay change)

### A1: Ensure one-way direction and margin are correct
- Explicitly set one-way collision direction so floors hold from above and pass from below.
- Set a small one-way margin to make “just above” collisions reliable.
- Pros: preserves transfer FSM; fixes floor collisions at the source.
- Cons: needs clear, explicit setup for all floor shapes.
- Docs: https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html

### A2: Raise item slightly above floor when switching to FALLING
- When crossing target_y, move the item to `target_y - small_offset` before enabling gravity.
- Ensures the body is unambiguously above the one-way plane, so it collides while falling.
- Pros: minimal change to logic; avoids dependency on one-way direction quirks.
- Cons: artificial vertical jump; must be small and consistent.

### A3: Snap + freeze on landing, then request settle
- On transfer end, snap bottom to target_y, freeze the body, and request a settle check.
- Pros: guarantees stable placement; avoids indefinite falling.
- Cons: more “authoritative” snap; less physical.

### A4: Align target_y to actual collision plane
- Compute target_y from the floor collision shape top instead of `SurfaceRef`.
- Or add a per-floor `surface_y_offset` exported value so visual and collision surfaces can be aligned.
- Pros: removes "target plane mismatch" entirely.
- Cons: requires touching floor surface adapter/scene data.

## Option set B: Adjust transfer FSM logic (still no gameplay rule change)

### B1: Two-step: rise past target + settle window
- Require `bottom_y <= target_y - margin` before entering FALLING.
- Add a short “settle window” where we check support ray and only then allow gravity.
- Pros: reduces cases where body is still below the floor.
- Cons: more state logic; needs tuning.

### B2: Re-run settle check after transfer end
- After `transfer_end`, explicitly enqueue a settle check to force snap/freeze logic in `WardrobePhysicsTickAdapter`.
- Pros: uses existing stabilization rules; less special-case logic.
- Cons: still depends on collision detection to identify support.

### B3: Pause gravity for 1-2 frames after transfer_end
- Temporarily freeze or set gravity_scale = 0 and let collision resolution separate the body.
- Pros: gives the solver a chance to resolve overlap without extra velocity.
- Cons: still reliant on correct collision plane and margins.

## Option set C: Validate floor choice and alignment

### C1: Validate X-bound alignment before starting transfer
- If the chosen floor is not within bounds for the item X, adjust X first or select a different floor.
- Pros: avoids falling through because target floor is elsewhere.
- Cons: requires additional constraints in `SurfaceRegistry` or dragdrop.

## Specific hypothesis from user
- When the item starts below the floor and physics switches from rise to fall, it may still be "below" the one-way plane.
- In that state, the one-way collision ignores it, so it simply keeps falling.
- This aligns with H1 + H2/H2a and suggests a fix like A2 or A4 (ensure it is slightly above the plane before falling).

## Notes on current log evidence
- The item transitions to FALLING and then accelerates indefinitely: indicates collision with floor is not happening.
- The `transfer_end` fires but does not stop motion afterward, meaning collision response is not engaged.

## Suggested next step for debugging
- Add explicit logs for:
  - floor surface bounds used during selection
  - one-way direction/margins on floor shapes
  - item bottom_y vs target_y at transition moment
- Decide whether to fix by adjusting one-way direction/margins (A1), offsetting above the surface (A2), or forcing settle check (B2).

## References (Godot 4.5)
- CollisionShape2D one-way: https://docs.godotengine.org/en/4.5/classes/class_collisionshape2d.html
- RigidBody2D integration: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
