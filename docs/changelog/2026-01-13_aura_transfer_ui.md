# Changelog: Aura Transfer UI

## 2026-01-13
- Implemented visual feedback for aura transfer delay (corruption "pending" state).
- **Domain**:
    - Updated `CorruptionAuraService.ExposureResult` to include `pending_sources`.
    - Updated `ExposureService` to populate `pending_sources` and cache results.
- **Visuals (ItemNode)**:
    - Added `get_item_radius()` to calculate visual radius from sprite bounds.
    - Added `set_aura_dimmed(bool)`: Reduces aura opacity/density for active sources.
    - Added `update_transfer_effect(target_id, target_pos, progress, target_radius)`:
        - Spawns and animates a particle stream from source to target.
        - Interpolates emission radius from source size to 90% of target size.
    - Implemented return animation:
        - When a transfer is interrupted, the stream animates back to the source (`TRANSFER_RETURN_SPEED`).
        - Uses `TransferEffectData` metadata to track state (active/returning).
- **UI (WorkdeskScene)**:
    - Updated `_tick_exposure` to orchestrate transfer effects.
    - **Visualizes ALL pending sources**: Now supports multiple simultaneous transfer streams to a single target, instead of limiting to the closest one.
    - Calculates `target_radius` dynamically from the target `ItemNode`.
    - Updates `ItemNode` visuals based on active transfers, passing target radius and progress.
