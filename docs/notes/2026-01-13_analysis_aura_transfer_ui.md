# Aura transfer UI/UX feedback — Analysis (2026-01-13)

## Status check (domain)
The domain-level transfer delay `t` is implemented:
- Per-source pending transfer timers exist in `ZombieExposureState`.
- Exposure begins only after the pending timer expires.
- Stage-gating (`source_stage > target_stage`) and self-exclusion are enforced in `CorruptionAuraService`.
- Stacking applies only to active sources.

No blocking issues found in the implementation that would prevent UI/UX planning.

## UX goal
Make it visually clear **which item is infecting which** when a target enters aura range, without changing domain outcomes.

## Proposed visual behavior
When a target enters aura range (rate 0 -> >0):
1) Reduce intensity of the source aura (base particle layer).
2) Spawn a second particle layer at the source, inheriting the reduced intensity.
3) Animate that second layer:
   - Move its emission center from source → target over time `t`.
   - Shrink its emission radius to `target_radius = item_radius * 0.9` over time `t`.
When target reaches the source stage (or rate returns to 0):
4) Reverse the animation, remove the second layer, restore source intensity.

## Data required (UI side)
Per item, cache:
- `last_rate` and `last_stage_index`
- `active_sources` (from domain exposure results)
- selected `source_id` for UI animation (closest source)

## Source selection rule
Choose the **closest** source by distance (stable and intuitive).

## Edge cases
- Multiple sources: multiple transfer overlays can run in parallel.
- Source leaves: cancel animation and restore intensity.
- Dragging: domain pauses exposure; UI should cancel active transfer.

## Engine references (Godot 4.5)
- Tween (SceneTreeTween):
  https://docs.godotengine.org/en/4.5/classes/class_tween.html
- GPUParticles2D:
  https://docs.godotengine.org/en/4.5/classes/class_gpuparticles2d.html
- ParticleProcessMaterial:
  https://docs.godotengine.org/en/4.5/classes/class_particleprocessmaterial.html
