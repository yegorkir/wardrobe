# 2026-01-17 — Plan: infinite client flow metrics + spawn loop

## Preconditions
- Confirm hook slot definition and whether cabinet/tray slots should count.
- Confirm meaning of “tickets on hand”.
- Confirm spawn policy thresholds and client source (wave list vs infinite pool).

## Implementation steps
1) Add app-layer config + snapshot types
   - Add `scripts/app/clients/client_flow_config.gd` for thresholds and cadence.
   - Add `scripts/app/clients/client_flow_snapshot.gd` with typed fields.

2) Add app-layer flow service
   - Create `scripts/app/clients/client_flow_service.gd` with `configure()` and `tick()`.
   - Add pure `should_spawn(snapshot)` and `build_spawn_request(snapshot)` helpers.

3) Extend world adapter for metrics (adapter-only)
   - Add `WardrobeWorldSetupAdapter.get_hook_slots()` if using slot-based counting.
   - Add `WardrobeWorldSetupAdapter.get_hand_item_kind()` to expose hand item kind via `WardrobeInteractionService`.
   - Add `build_flow_snapshot()` in adapter (or WorkdeskScene) that converts world state to `ClientFlowSnapshot`.

4) Client creation (app-layer)
   - Extract client creation from `WardrobeStep3SetupAdapter` into `ClientFactory`.
   - Add a method to spawn a single client and enqueue it through `ClientQueueSystem`.

5) Wire flow tick
   - Call `ClientFlowService.tick(delta)` from `WorkdeskScene._process()` after queue tick.
   - On spawn decision, enqueue client and optionally assign to desks (reuse `DeskServicePointSystem`).

6) Update tests
   - Unit tests for flow logic and snapshot counting.
   - Integration test verifying spawn adds to queue when capacity exists.

7) Verification
   - Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
   - Launch `"$GODOT_BIN" --path .`.

## Open questions
- Spawn throttling: fixed interval vs event-driven (on slot/item updates).
- Maximum active clients on desks vs queue (limits per desk count).
- How to seed ticket items for newly spawned clients (reuse ticket slots or create new ticket items on demand).
