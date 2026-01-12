# Iteration 8 — Plan: Queue patience decay + pool delay

## Goals
- Add queue patience decay with configurable rates.
- Add deterministic pool delay after dropoff.
- Preserve strike/lose behavior.

## Non-goals
- No HUD indicators for queue decay.
- No nondeterministic RNG for delays.

## Plan steps
1) **Extend shift config**
   - Add:
     - `slot_decay_rate`
     - `queue_decay_multiplier`
     - `queue_delay_checkin_min/max`
     - `queue_delay_checkout_min/max`
     - `seed_override` (optional)

2) **Deterministic seed setup**
   - In ShiftService, resolve seed:
     - use `seed_override` if set
     - else compute from shift metadata (run_id/shift_index)

3) **Queue delay tracking**
   - Add `queue_delay_by_client_id` and delay-type mapping (checkin/checkout).
   - Add `enqueue_after_delay(client_id, delay, is_checkout)` and `tick_queue_delays(delta)`.
   - Use hash-based delay:
     - `ratio = abs(hash(client_id + seed)) / MAX_INT`
     - `delay = lerp(min, max, ratio)`

4) **Patience system update**
   - Update `ShiftPatienceSystem.tick_patience` to accept:
     - `active_client_ids`
     - `queue_client_ids`
     - `slot_decay_rate`
     - `queue_decay_multiplier`
   - Apply decay to slot and queue separately.
   - Keep strike logic unchanged (>0 -> 0 only).

5) **WorkdeskScene integration**
   - Collect active desk clients.
   - Collect queue clients (checkin + checkout).
   - Remove active clients from queue list (no double decay).
   - Pass lists to ShiftService.

6) **Pool delay integration**
   - After dropoff, enqueue client via delay system instead of immediate queue.
   - After pickup, do not enqueue.

7) **Debug logging**
   - Optional debug log per tick for queue decay, guarded by debug flag.

8) **Tests**
   - Unit: decay rates (slot vs queue), pool no decay.
   - Unit: deterministic delay per client_id + seed.
   - Integration: dropoff -> pool delay -> queue -> slot; strike once.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`
