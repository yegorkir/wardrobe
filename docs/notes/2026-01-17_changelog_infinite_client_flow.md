# 2026-01-17 — Changelog: infinite client flow metrics

## Summary
- Added app-layer client flow metrics snapshot and tick service.
- Exposed ticket and active client counts from run state to support metrics.
- Wired Workdesk scene to build and update client flow snapshots each frame.
- Added debug logging to compare computed metrics with live scene items.
- Added unit tests for client flow service cadence and ticket counting.

## Details
- Added `ClientFlowSnapshot`, `ClientFlowConfig`, and `ClientFlowService` in `scripts/app/clients/`.
- Extended `RunState` to track total ticket count and expose it.
- Exposed `get_total_tickets()` and `get_active_client_count()` through `ShiftService` and `RunManagerBase`.
- Added `WorkdeskScene._build_client_flow_snapshot()` to compute:
  - cabinet hook slot count
  - client items on scene (coats + tickets)
  - tickets on scene and tickets taken
  - queue counts (total/checkin/checkout)
  - active client count
- Logged cabinet slot ids + spawned item ids/kinds alongside the computed snapshot.
- Added tests:
  - `tests/unit/app/clients/client_flow_service_test.gd`
  - `tests/unit/domain/run_state_ticket_count_test.gd`
