# 2026-01-17 — Plan: infinite client flow metrics + spawn loop

## Preconditions (resolved)
- Hooks count = cabinet slots on the scene; tray slots excluded.
- Track two metrics: total hooks and client items on scene (derive free capacity later).
- Tickets taken = total tickets - tickets on scene (approximate).
- Only metrics collection now; spawn decisions deferred.

## Implementation steps
1) Add app-layer snapshot types
 - Add `scripts/app/clients/client_flow_config.gd` for thresholds and cadence.
 - Add `scripts/app/clients/client_flow_snapshot.gd` with typed fields.

2) Add app-layer flow service (metrics only)
  - Create `scripts/app/clients/client_flow_service.gd` with `configure()` and `tick()`.
  - Add `build_snapshot()` helper; no spawn logic yet.

3) Extend world adapter for metrics (adapter-only)
  - Add `WardrobeWorldSetupAdapter.get_cabinet_slots()` or reuse `get_cabinet_ticket_slots()` to count total hooks.
  - Add `WardrobeWorldSetupAdapter.get_spawned_items()` filtering helpers for item counts.
  - Add `build_flow_snapshot()` in adapter (or WorkdeskScene) that converts world state to `ClientFlowSnapshot`.

4) Client creation (deferred)
  - No new client creation or spawn logic in this iteration.

5) Wire flow tick
  - Call `ClientFlowService.tick(delta)` from `WorkdeskScene._process()` after queue tick.
  - Publish snapshot for future decision logic (no spawning).

6) Update tests
  - Unit tests for snapshot counting.
  - Integration test verifying metrics update on item add/remove.

7) Verification
   - Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
   - Launch `"$GODOT_BIN" --path .`.

## Open questions (deferred)
- How to track total tickets more reliably when tickets can be destroyed or moved off-scene.
