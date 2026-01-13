# Checklist: Restrict Zombie Corruption to Client Items

- [x] **Analysis**
    - [x] Identify problem: System items (tickets, anchor tickets) are currently susceptible to zombie corruption.
    - [x] Determine filter criteria: `ItemInstance.kind`.

- [x] **Implementation**
    - [x] Update `ItemInstance`: Add `can_be_corrupted() -> bool` method.
        - [x] Return `false` for `KIND_TICKET` and `KIND_ANCHOR_TICKET`.
        - [x] Return `true` for others (`KIND_COAT`).
    - [x] Update `ExposureService.tick`:
        - [x] Skip `target_stages` registration and exposure calculation for items where `can_be_corrupted()` is false.

- [x] **Verification**
    - [x] Run unit tests.
    - [x] Verify in logs that ticket items no longer receive `ZOMBIE_STAGE_COMPLETE` events.
