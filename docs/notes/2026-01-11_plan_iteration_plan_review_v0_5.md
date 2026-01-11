# Plan: Iteration plan review v0.5 (next implementation)

## Target scope

Implement Iteration 0 (cleanup) as the next development step:

- Remove legacy wave timer and wave-fail logic.
- Configure win targets from N_checkin/N_checkout (not total_clients).
- Keep win tests as a safety net; add coverage for configured targets.

## Step-by-step plan

### Step 1 - Remove wave timer and wave fail

- Delete `_wave_time_left`, `_wave_failed`, `_tick_wave_and_patience()`, and `_fail_wave()` from `scripts/ui/workdesk_scene.gd`.
- Remove any UI label updates tied to wave time.
- Ensure shift fail is still driven by patience strikes only.

DoD:
- No references to wave timer remain in `workdesk_scene.gd`.
- Running a shift no longer auto-fails due to time.

### Step 2 - Define N_checkin/N_checkout source of truth

- Decide data source (preferred: wave JSON fields):
  - Add `target_checkin` and `target_checkout` to `content/waves/*.json`.
  - Load these fields via ContentDB in the adapter layer.
- Update `workdesk_scene.gd` to call `configure_shift_targets` with those values.

DoD:
- Targets are no longer derived from total_clients.
- Targets are set via a single config path.

### Step 3 - Update tests

- Extend `tests/unit/shift_service_win_test.gd` or add a new test to assert:
  - shift win condition uses configured targets,
  - counters do not win early if targets are higher.

DoD:
- Tests cover config-driven targets and win condition boundaries.

### Step 4 - Validate

- Run canonical tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Launch Godot once: `"$GODOT_BIN" --path .`.

DoD:
- Tests pass and editor launches without new warnings tied to the changes.

## Follow-up (next iteration after cleanup)

- Start Iteration 1: Service Desk as surface table (new adapter + placement rules).
