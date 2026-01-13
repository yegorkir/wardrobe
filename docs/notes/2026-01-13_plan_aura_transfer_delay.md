# Aura transfer delay (domain-level) — Plan (2026-01-13)

## Goal
Implement domain-level transfer delay `t` so corruption begins only after `t` completes, while preserving stacking, stage gating, and self-exclusion.

## Plan
1) **State model**
   - Add `pending_transfers` to `ZombieExposureState` (`Dictionary` keyed by `StringName`).
   - Helper methods: `set_pending`, `clear_pending`, `tick_pending(delta)`.

2) **ExposureService integration**
   - Compute distance-based `t` per source.
   - Track/update pending transfers per target.
   - Build active source list (remaining_time <= 0).
   - Keep self-exclusion and stage-gating.

3) **CorruptionAuraService inputs**
   - Accept active sources only.
   - Continue to enforce `source_stage > target_stage`.

4) **Tests**
   - Add unit tests for transfer delay (`t` not elapsed -> no corruption).
   - Add multi-source delay test (staggered activation).
   - Add exit-and-reenter test (pending reset).

5) **Docs**
   - Update notes to describe new delay rule and stage gating.

6) **Verification**
   - Run: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
   - Launch: `"$GODOT_BIN" --path .`
