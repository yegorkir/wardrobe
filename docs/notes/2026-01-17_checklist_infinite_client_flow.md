# 2026-01-17 — Checklist: infinite client flow metrics

- [x] Add app-layer client flow snapshot/config/service types in `scripts/app/clients/`.
- [x] Track total tickets in `RunState` and expose counts via `ShiftService` and `RunManagerBase`.
- [x] Build client flow snapshot in `scripts/ui/workdesk_scene.gd` and tick the service.
- [x] Add debug logs to compare snapshot metrics with live scene items.
- [x] Add unit tests for client flow service cadence.
- [x] Add unit test for ticket counting in `RunState`.
- [x] Run canonical tests and launch Godot once (Godot startup timed out after logs).
