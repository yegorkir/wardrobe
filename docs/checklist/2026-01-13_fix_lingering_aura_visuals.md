# Checklist: Fix Lingering Aura Visuals on Corrupted Items

- [x] **Analysis**
    - [x] Identify cause: `ExposureService` continues to calculate exposure and manage `pending_transfers` even for fully corrupted items.
    - [x] Verify `ExposureService` logic flow.

- [x] **Implementation**
    - [x] Update `ExposureService.tick`:
        - [x] Check item quality (via `item.quality_state.current_stars`) before exposure calculation loop.
        - [x] If quality <= 0:
            - [x] Clear any existing `pending_transfers` in `z_state` immediately (so visuals stop).
            - [x] Skip exposure calculation for this item.

- [x] **Verification**
    - [x] Run unit tests.
    - [x] (Optional) Verify visually or via logs that transfer effects cease once item "dies".
