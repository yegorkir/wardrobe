# Aura transfer delay (domain-level) — Analysis (2026-01-13)

## Problem statement
We need deterministic, domain-level control over when zombie corruption starts after a target enters an aura. The user-visible animation has a transfer time `t`, and **real corruption must begin only after `t` completes**. This must work with multiple sources, stage gating, and self-exclusion.

## Requirements
- Corruption **does not start immediately** on entering aura; it starts after transfer time `t`.
- Multiple sources can affect a target; stacking applies **only for active sources**.
- Stage gating: a source affects a target **only if `source_stage > target_stage`**.
- Self-exclusion: a source never affects its own item.
- Drag rule preserved: dragging pauses exposure and propagation.
- Deterministic outcomes (tick-based, no wall-clock).

## Architecture considerations
### Domain responsibility
The delay `t` must live in the domain layer so it is deterministic and testable. UI visuals may animate, but **domain starts damage only after delay**.

### Data needed per item
We need to track per-target, per-source transfer state:
- `pending_transfers`: `source_id -> remaining_time`
- `active_sources`: derived from pending state (remaining_time <= 0)

### Placement
Add transfer state into `ZombieExposureState` (domain, RefCounted). Avoid Node or SceneTree dependencies.

## Proposed domain model changes
### ZombieExposureState (new fields)
- `pending_transfers: Dictionary` (key: `StringName source_id`, value: `float remaining_time`)
- `active_sources: Array[StringName]` (optional; can be derived on the fly)

### Transfer timing
Transfer time is a function of distance:
- `t = clamp(distance / speed, t_min, t_max)`
- `speed` and clamp values should be constants or config.

## Services impact
### CorruptionAuraService
Currently computes `rate` + `sources`. It needs additional inputs:
- `target_stages` and `source_stages` (for stage gating)
- `pending_transfers` and `transfer_time` evaluation (or keep pending logic in `ExposureService`)

### ExposureService
Will:
- Build `pending_transfers` per target from source distances.
- Decrement `remaining_time` by `delta`.
- Pass only **active sources** to `CorruptionAuraService`.
- Apply `ZombieExposureSystem` only when rate > 0 (unchanged).

## Edge cases
- Leaving aura before `t` completes: remove pending transfer.
- Re-entering: reset `remaining_time` or resume? (Prefer reset for clarity.)
- Multiple sources with different `t`: each tracked independently.

## Testing approach
Unit tests should verify:
- No corruption before `t` elapses.
- Multiple sources activate independently by their `t`.
- Stage gating blocks equal/higher targets.
- Self-exclusion always holds.

## References
- Godot 4.5: GDScript basics (typed dictionaries):
  https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_basics.html
