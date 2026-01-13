# Aura visuals adjustment (2026-01-13)

## Summary
- Zombie items now always display corruption aura visuals.
- Non-zombie items only display aura after quality loss enables weak propagation.
- Aura particle radius is driven by archetype or weak-aura config instead of a hardcoded value.

## Files touched
- `scripts/wardrobe/item_node.gd`
- `scripts/domain/magic/exposure_service.gd`
- `scripts/ui/workdesk_scene.gd`

## References (Godot 4.5)
- GPUParticles2D:
  https://docs.godotengine.org/en/4.5/classes/class_gpuparticles2d.html
- ParticleProcessMaterial:
  https://docs.godotengine.org/en/4.5/classes/class_particleprocessmaterial.html
