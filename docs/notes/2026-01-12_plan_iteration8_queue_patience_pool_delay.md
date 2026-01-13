# Iteration 8 — Plan: Queue patience decay + pool delay

## Goals
- Add queue patience decay with configurable rates.
- Add deterministic pool delay after dropoff.
- Preserve strike/lose behavior.
- **[New]** Visualize patience in the queue HUD.

## Non-goals
- No complex animations for patience loss (just bar update).
- No nondeterministic RNG for delays.

## Plan steps
1) **Extend shift config**
   - Add keys to `ShiftService.SHIFT_DEFAULT_CONFIG` (or where loaded):
     - `slot_decay_rate`
     - `queue_decay_multiplier`
     - `queue_delay_checkin_min/max`
     - `queue_delay_checkout_min/max`
     - `seed_override` (optional)

2) **Deterministic seed setup**
   - In `ShiftService.setup`, resolve seed:
     - use `seed_override` if set
     - else compute from shift metadata (run_id/shift_index)
   - Expose seed via getter or pass to systems.

3) **Queue delay tracking (ClientQueueSystem)**
   - Update `ClientQueueSystem` to hold state (ref counted, but needs tick).
   - Add `delayed_clients: Dictionary` (client_id -> time_left).
   - Add `enqueue_after_delay(client_id, delay, is_checkout)`.
   - Add `tick(delta)`: decrement timers, enqueue when <= 0.
   - Use hash-based delay:
     - `ratio = abs(hash(client_id + seed)) / MAX_INT`
     - `delay = lerp(min, max, ratio)`
   - Update `requeue_after_dropoff` to use `enqueue_after_delay`.

4) **Patience system update**
   - Update `ShiftPatienceSystem.tick_patience` to accept:
     - `active_client_ids`
     - `queue_client_ids`
     - `slot_decay_rate`
     - `queue_decay_multiplier`
   - Apply decay to slot and queue separately.
   - Keep strike logic unchanged (>0 -> 0 only).

5) **System Integration (RunManager/ShiftService)**
   - Update `ShiftService.tick_patience` to accept queue clients.
   - Update `RunManager.tick_patience` to accept queue clients.
   - Update `ShiftPatienceSystem` calls to use new config values.

6) **WorkdeskScene integration**
   - In `_tick_patience`:
     - Collect active desk clients (existing).
     - Collect queue clients (checkin + checkout) from `_world_adapter.get_client_queue_state()`.
     - Remove active clients from queue list (safety check).
     - Call `_run_manager.tick_patience` with both lists.
   - In `_process`:
     - Call `_world_adapter.get_queue_system().tick(delta)` (ensure queue system is accessible).

7) **Pool delay integration**
   - Ensure `WardrobeWorldSetupAdapter` passes the seed to `ClientQueueSystem`.
   - Ensure `requeue_after_dropoff` is called correctly (it is called by `InteractionService/EventAdapter`, need to verify it uses the updated system).

8) **Queue UI Visualization**
   - **QueueHudClientVM**: Add `patience_ratio: float`.
   - **QueueHudPresenter**: Update `build_result` to accept `patience_max_by` and calculate ratio.
   - **QueueHudAdapter**: 
     - Update `configure` to accept `patience_max_by`.
     - Pass max patience to presenter.
   - **QueueHudView**:
     - `_create_item`: Add `ProgressBar` (bottom anchored, simple style).
     - `_update_item`: Set `value` from `vm.patience_ratio`.
   - **WorkdeskScene**: Pass `_patience_max_by_client_id` to `_queue_hud_adapter.configure`.

9) **Debug logging**
   - Optional debug log per tick for queue decay, guarded by debug flag.

10) **Tests**
   - Unit: decay rates (slot vs queue), pool no decay.
   - Unit: deterministic delay per client_id + seed.
   - Integration: dropoff -> pool delay -> queue -> slot; strike once.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`
