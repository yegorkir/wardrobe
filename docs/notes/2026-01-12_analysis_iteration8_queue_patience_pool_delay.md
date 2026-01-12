# Iteration 8 — Analysis: Queue patience decay + pool delay

## Scope
Introduce queue patience decay with configurable rates and add a deterministic pool delay after dropoff before clients rejoin the queue. Preserve existing strike/lose rules.

## Requirements (confirmed)
- Patience decays in service slots (existing) and in queue (new), with a configurable multiplier.
- Clients in the pool (not in queue and not at desk) do not decay.
- Pool delay applies after dropoff only; after pickup the client does not return.
- Queue delay must be deterministic (seeded) and not rely on nondeterministic RNG.
- Separate delay ranges for checkin vs checkout are required.
- Decay logging per tick is debug-only and off by default.

## Constraints & architecture rules
- Domain/app must not depend on Node or SceneTree.
- Patience math lives in one system (ShiftPatienceSystem).
- Configuration is the only source of decay rates and delay ranges.
- Strike logic remains: only on >0 -> 0 transition; no repeat strikes at 0.

## Current behavior (codebase)
- `ShiftPatienceSystem.tick_patience(state, active_client_ids, delta)` applies decay only to active desk clients.
- `WorkdeskScene._tick_patience()` collects active desk clients only.
- No queue decay or pool delay exists.

## Solution design
### Patience decay
- Add `slot_decay_rate` and `queue_decay_multiplier` to shift config.
- New tick signature accepts both active (desk) and queue client lists.
- Decay formula:
  - slot: `delta * slot_decay_rate`
  - queue: `delta * slot_decay_rate * queue_decay_multiplier`
  - pool: `0`

### Pool delay (deterministic)
- Introduce a queue-delay tracker in app layer (ClientQueueSystem or dedicated helper).
- Delay is deterministic using a hash-based method, not runtime RNG:
  - `ratio = abs(hash(client_id + seed)) / MAX_INT`
  - `delay = lerp(min, max, ratio)`
- Separate ranges for checkin vs checkout.
- Seed comes from shift metadata with an override for tests.

## Architecture (system design)
### Modules
- `ShiftPatienceSystem` (domain/app): extends `tick_patience` to accept queue clients and rates.
- `ShiftService`: provides shift config rates and seed; owns deterministic seed setup.
- `ClientQueueSystem`: manages queue delay timers and enqueue-after-delay behavior.

### Data contracts
- Shift config keys:
  - `slot_decay_rate: float`
  - `queue_decay_multiplier: float`
  - `queue_delay_checkin_min: float`
  - `queue_delay_checkin_max: float`
  - `queue_delay_checkout_min: float`
  - `queue_delay_checkout_max: float`
  - `seed_override: int` (optional, tests)

### Determinism
- Use seed override in tests for stable delays.
- Hash-based delay avoids dependence on order of RNG calls.

## Logs
- Patience decay logging per tick is debug-only (off by default).
- Keep existing ShiftLog events for strikes and penalties.

## Tests (requirements)
- Unit: slot vs queue decay rates.
- Unit: pool clients do not decay.
- Unit: deterministic delay from seed and client_id.
- Integration: dropoff -> pool delay -> queue -> slot, strikes still only once.

## Engine references (Godot 4.5)
- No engine-specific APIs required beyond existing timing/tick integration.
