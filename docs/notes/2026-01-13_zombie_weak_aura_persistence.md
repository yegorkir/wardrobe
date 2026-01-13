# Zombie weak aura persistence (2026-01-13)

## Summary
- Weak aura now persists after the first corruption stage, even when exposure rate drops to zero.
- Dragging still suppresses emission via source filtering, but does not clear the weak aura flag.

## Files touched
- `scripts/domain/magic/zombie_exposure_state.gd`
- `scripts/domain/magic/zombie_exposure_system.gd`
