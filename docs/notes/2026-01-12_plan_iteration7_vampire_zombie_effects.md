# Iteration 7 (7A/7B) — Plan: Vampire light corrosion + Zombie aura corrosion

## Goals
- Introduce item archetypes for items (domain-first).
- Implement vampire light exposure with staged quality loss.
- Implement zombie aura exposure with stacking/cap and propagation.
- Use a unified `apply_effect` API with enum effect types.
- Add UI-only aura particle visuals.

## Non-goals
- No new light rules beyond existing Light Query contract.
- No new UI HUD indicators or text labels.

## Plan steps
1) **Add item archetype to item domain**
   - Extend item config/state with `item_archetype_id`.
   - Ensure item instance can access archetype without UI.

2) **Define effect enums and apply_effect API**
   - Create `ItemEffectType` enum and `EffectSourceType` enum.
   - Add `ItemEffect` value object and `ItemEffectResult`.
   - Implement `apply_effect` on item domain state; route quality loss through quality system.

3) **Vampire exposure system (7A)**
   - `VampireExposureState` + config (threshold, loss per stage).
   - `tick_vampire_exposure(item_id, is_in_light, is_dragging, delta)`.
   - Apply `LIGHT_CORROSION` effect when threshold reached.

4) **Zombie aura service (7B)**
   - `CorruptionAuraService` to compute exposure rates per item.
   - `ZombieExposureState` + config (threshold, loss, cap, propagation radius).
   - `tick_zombie_exposure(item_id, rate, is_dragging, delta)`.
   - Apply `ZOMBIE_AURA` effect on stage completion.

5) **Propagation & aura sources**
   - Build sources from zombie archetype items and weak aura emitters.
   - Skip dragged items in source list.

6) **Logging**
   - Add log events for vampire/zombie stages and effect application.
   - Use injected `Callable` logger (ShiftLog).

7) **UI aura particles**
   - Item visual adapter toggles Particles2D when `is_emitting_weak_aura`.
   - Color: dark green, radius = propagation radius (visual only).

8) **Tests**
   - Unit tests: vampire exposure accumulation/reset/drag/quality clamp.
   - Unit tests: zombie aura stacking/cap/reset/propagation.
   - Integration test: 3-item scenario (zombie + near + far) with deterministic results.
   - UI test: particle toggle on `is_emitting_weak_aura` state.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`

## Follow-up plan (2026-01-13) — Remaining work
1) **Confirm test baseline**
   - Re-run canonical tests; resolve any parser/type errors (latest logs showed `ItemEffect`/`ItemEffectResult` parse failures).
   - If errors persist, align `class_name` usage and type hints for `ItemEffect*` classes.

2) **Fix weak aura propagation radius**
   - Add a dedicated `weak_aura_radius` config (global or per-archetype).
   - Ensure non-zombie items that reached stage 1 emit a weak aura with the new radius.

3) **Expose affecting sources in aura service**
   - Extend `CorruptionAuraService` to optionally return source ids for logging/debug.
   - Update exposure orchestration to pass `sources` into logs if required.

4) **Add missing tests**
   - Integration/deterministic scenario (zombie + nearby + far) with stable results.
   - Propagation test to confirm weak aura spreads from a non-zombie item.

5) **Clarify/implement vampire exposure UI**
   - If still required, implement a simple progress bar indicator driven by exposure state.

6) **Docs hygiene**
   - Update `docs/checklist/2026-01-12_iteration7_vampire_zombie_effects.md`.
   - Update `docs/changelog/2026-01-12_iteration7_vampire_zombie_effects.md`.
