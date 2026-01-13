# Aura transfer UI/UX feedback — Plan (2026-01-13)

## Goal
Implement UI-only feedback for infection transfer using a second particle layer and tweened movement/radius over time `t`.

## Plan
1) **Data plumbing (UI)**
   - In `WorkdeskScene` (or a dedicated adapter), cache per-item:
     - `last_rate`, `last_stage_index`, `active_sources`.
   - Detect transitions: `last_rate == 0` and `current_rate > 0` (start), and `rate == 0` or `target_stage >= source_stage` (stop).

2) **Source selection**
   - For each target, pick the closest `source_id` from `active_sources` using positions.
   - Support multiple sources by allowing multiple overlays (per source) if needed.

3) **Particle overlay**
   - Extend `ItemNode` with:
     - `set_aura_intensity(scale: float)` for base layer.
     - `spawn_transfer_overlay(source_pos, target_pos, source_radius, target_radius, t)`.
     - `stop_transfer_overlay()`.

4) **Animation**
   - Tween overlay center from source → target over `t`.
   - Tween emission radius from source_radius → target_radius over `t`.
   - On completion (or stop condition), reverse or cleanup.

5) **UI-only constraints**
   - No changes to domain state.
   - Cancel animations when target is dragged or loses rate.

6) **Verification**
   - Manual visual check: entering aura shows transfer, completion restores base intensity.

## Notes
- Keep overlays lightweight (reuse nodes if possible).
- All values remain visual; domain still dictates actual rate via transfer delay `t`.
