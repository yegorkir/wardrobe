# Iteration 7 (7A/7B) — Analysis: Vampire light corrosion + Zombie aura corrosion

## Scope
Define domain-first rules and APIs for vampire light exposure and zombie aura exposure, using a unified item effect API (enum-based), explicit item archetypes, and deterministic tick-based progression. Include UI-only visuals for zombie aura particles.

## Requirements (confirmed)
- Items have archetypes; vampire/zombie effects are driven by item archetype, not client archetype.
- Effects are applied via a universal API (`apply_effect`) with enum effect types (no free strings).
- Vampire items lose quality in stages while in light; exposure resets when leaving light or while dragged.
- Zombie items emit a radius-based aura; exposure accumulates from nearby sources, with stacking + cap.
- After first zombie stage, the affected item emits a weak aura (propagation).
- Drag rule: while item is dragged, it does not accumulate exposure and does not affect others.
- Visuals: show dark-green particles around items that emit a corruption aura (UI-only).
- Logs for stage transitions and effect application are recorded via ShiftLog (through injected Callables).

## Constraints & architecture rules
- Domain/app must not depend on Node or SceneTree.
- UI/adapters gather positions and drag state from ItemNode and pass to app services.
- No duplicate APIs for damage/effects; only one effect pipeline.
- Determinism required for tick-driven systems (no wall-clock usage).

## Domain model (proposed)
### Item archetype
- Source of truth in immutable item config (content-derived).
- Item instance may cache `item_archetype_id` for quick reads.

### Effects
- `ItemEffectType` enum:
  - `LIGHT_CORROSION`, `ZOMBIE_AURA`, `FALL`, `FIRE`, `OTHER` (extendable)
- `EffectSourceType` enum:
  - `LIGHT`, `ZOMBIE`, `FALL`, `OTHER`
- `ItemEffect` value object:
  - `effect_type`, `source`, `intensity`, `tags`
- `ItemEffectResult`:
  - `accepted`, `quality_loss`, `events`

### Vampire exposure
- `VampireExposureState`:
  - `current_stage_exposure: float`
  - `stage_index: int`
- `VampireExposureConfig`:
  - `threshold_per_stage: float`
  - `quality_loss_per_stage: int`

### Zombie exposure
- `ZombieExposureState`:
  - `current_stage_exposure: float`
  - `stage_index: int`
  - `is_emitting_weak_aura: bool`
- `ZombieExposureConfig`:
  - `threshold_per_stage: float`
  - `quality_loss_per_stage: int`
  - `stack_rate_cap: float`
  - `propagation_radius_min: float`
- `AuraSource`:
  - `source_id`, `position`, `radius`, `base_rate`, `strength_modifier`, `is_active`

## Core services (proposed)
- `VampireExposureSystem` (domain/app)
  - Inputs: `is_in_light`, `is_dragging`, `delta`, item quality state
  - Outputs: updated exposure state + effect applications
- `CorruptionAuraService` (domain/app)
  - Inputs: positions + active sources
  - Outputs: per-item exposure rates + affecting source list
- `ZombieExposureSystem` (domain/app)
  - Inputs: exposure rate, `is_dragging`, `delta`, item quality
  - Outputs: updated exposure state + effect applications

## Data flow (tick)
1) Adapter gathers per-item data:
   - `item_id`, `position`, `is_dragging`, `archetype_id`
2) Vampire path:
   - `is_in_light` from Light Query
   - `VampireExposureSystem.tick(...)` → `apply_effect(LIGHT_CORROSION)`
3) Zombie path:
   - Build `AuraSource` from zombie items (skip dragging)
   - `CorruptionAuraService.get_rate(item_id)`
   - `ZombieExposureSystem.tick(...)` → `apply_effect(ZOMBIE_AURA)`
4) UI reacts to `is_emitting_weak_aura` and toggles particles.

## Logs (ShiftLog)
- `VAMPIRE_EXPOSURE_START`
- `VAMPIRE_STAGE_COMPLETE`
- `VAMPIRE_QUALITY_LOSS`
- `ZOMBIE_AURA_APPLIED`
- `ZOMBIE_STAGE_COMPLETE`
- `ZOMBIE_PROPAGATION_ENABLED`

## Risks & mitigations
- Archetype confusion (client vs item) → separate item archetype fields and configs.
- Drag rule divergence → pass `is_dragging` into both exposure systems.
- O(N^2) aura checks → allow MVP, but isolate CorruptionAuraService for later spatial optimization.
- Dual damage APIs → enforce `apply_effect` as the only entry point.

## Test matrix (high-level)
- Vampire exposure: accumulate/reset/drag/quality clamp.
- Zombie aura: single/multi source, cap, reset on removal, propagation.
- Determinism: same inputs → same outputs.
- UI: particles appear only when `is_emitting_weak_aura`.

## Engine references (Godot 4.5)
- Particles2D (aura visuals):
  https://docs.godotengine.org/en/4.5/classes/class_particles2d.html
- GPUParticles2D (optional):
  https://docs.godotengine.org/en/4.5/classes/class_gpuparticles2d.html
- Node2D (item visuals positioning):
  https://docs.godotengine.org/en/4.5/classes/class_node2d.html
