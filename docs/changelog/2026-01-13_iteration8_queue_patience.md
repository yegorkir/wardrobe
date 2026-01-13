# Changelog: Iteration 8 (Queue Patience & Pool Delay)

## [Unreleased]
### Added
- **Queue Patience Decay**: Clients in the queue now lose patience at a configurable rate (`queue_decay_multiplier`).
- **Pool Delay**: Clients now wait in a "pool" for a deterministic duration after dropoff before rejoining the queue.
- **Shift Config**: Added `slot_decay_rate`, `queue_decay_multiplier`, `queue_delay_checkin_min/max`, `queue_delay_checkout_min/max`, and `seed_override`.
- **ClientQueueSystem**: Added state for tracking delayed clients and `tick(delta)` method.

### Changed
- **ShiftPatienceSystem**: Updated `tick_patience` to accept queue clients and apply separate decay rates.
- **ShiftService**: Updated to provide seed and pass queue clients to patience system.
- **RunManager**: Updated `tick_patience` signature.
- **WorkdeskScene**: Now collects queue clients and ticks `ClientQueueSystem`.
