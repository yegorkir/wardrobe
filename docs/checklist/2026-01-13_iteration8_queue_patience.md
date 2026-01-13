# Checklist: Iteration 8 (Queue Patience & Pool Delay)

- [x] **Config & Seed**
  - [x] Update `ShiftService.SHIFT_DEFAULT_CONFIG` with new keys.
  - [x] Implement seed resolution in `ShiftService`.
  - [x] Expose config and seed to systems.

- [x] **Queue Delay (ClientQueueSystem)**
  - [x] Add `delayed_clients` dictionary.
  - [x] Implement `enqueue_after_delay`.
  - [x] Implement `tick(delta)`.
  - [x] Implement deterministic delay calculation.
  - [x] Update `requeue_after_dropoff`.

- [x] **Patience System (ShiftPatienceSystem)**
  - [x] Update `tick_patience` signature.
  - [x] Implement queue decay logic.
  - [x] Ensure pool clients (not in list) do not decay.

- [x] **System Integration**
  - [x] Update `ShiftService.tick_patience`.
  - [x] Update `RunManager.tick_patience`.
  - [x] Update `RunManagerBase.tick_patience`.

- [x] **WorkdeskScene Integration**
  - [x] Update `_tick_patience` to collect queue clients.
  - [x] Call `_queue_system.tick(delta)` in `_process`.
  - [x] Pass seed to `ClientQueueSystem` via `WardrobeWorldSetupAdapter` (or similar).

- [x] **Queue UI Visualization**
  - [x] Update `QueueHudClientVM` to include `patience_ratio`.
  - [x] Update `QueueHudPresenter` to calculate and set `patience_ratio`.
  - [x] Update `QueueHudAdapter` to pass max patience data.
  - [x] Update `QueueHudView` to render progress bar.
  - [x] Update `WorkdeskScene` to pass `_patience_max_by_client_id` to adapter.

- [x] **Tests**
  - [x] Unit tests for decay rates.
  - [x] Unit tests for deterministic delay.
  - [x] Integration tests.