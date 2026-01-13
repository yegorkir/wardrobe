# Checklist: Aura Transfer UI

- [x] **Analysis & Plan**
    - [x] Analyze domain state (`pending_transfers` in `ZombieExposureState`).
    - [x] Plan `ItemNode` visual extensions and `WorkdeskScene` orchestration.
    - [x] Plan reverse animation for interrupted transfers.

- [x] **Domain Updates**
    - [x] `CorruptionAuraService`: Add `pending_sources` to `ExposureResult`.
    - [x] `ExposureService`: Populate `pending_sources` in `tick`.
    - [x] `ExposureService`: Expose `get_exposure_result(item_id)` via cached last results.

- [x] **ItemNode Visuals**
    - [x] Add `set_aura_dimmed(bool)` to dim base aura intensity.
    - [x] Implement `TransferEffectData` to store effect state, target pos/radius.
    - [x] Add `update_transfer_effect(target, progress, target_radius)` to visualize stream.
    - [x] Implement `get_item_radius` based on visual bounds.
    - [x] Implement `_process_transfer_effects` for return animation.
    - [x] Update `clear_unused_transfers` to trigger return animation.
    - [x] Interpolate particle radius from source to target.

- [x] **Orchestration (WorkdeskScene)**
    - [x] Calculate `source_usage` map for **all** pending sources (removed closest-only restriction).
    - [x] Iterate items in `_tick_exposure` to update visuals.
    - [x] Calculate `target_radius` from `ItemNode.get_item_radius()` (or default).
    - [x] Pass `target_radius` to `update_transfer_effect`.

- [x] **Verification**
    - [x] Run unit tests (passed).
    - [x] Verify no regressions in existing exposure logic.
