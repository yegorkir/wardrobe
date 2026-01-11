# Changelog: Iteration 4.2 Queue HUD

- Added Queue HUD app-layer DTOs and presenter (`queue_hud_client_vm.gd`, `queue_hud_snapshot.gd`, `queue_hud_build_result.gd`, `queue_hud_presenter.gd`) to build deterministic HUD snapshots and timeout flags.
- Implemented Workdesk Queue HUD UI (`queue_hud_view.gd`, `queue_hud_adapter.gd`) with append/pop/timeout animations and debug event logging.
- Wired Queue HUD into Workdesk scenes and added preview injection to allow fake snapshot rendering in debug mode.
- Removed the legacy HUD placeholder panel from Workdesk scenes and repositioned the end-shift button to the bottom-right so the Queue HUD strip is unobstructed.
- Introduced client content definitions (`content/clients/*.json`) and ContentDB support for client configs, with wave configs updated to reference client definitions.
- Updated client state and Step 3 setup to carry client definition IDs and portrait keys from content.
- Added presenter unit tests and expanded content validation tests for client configs.
- Updated docs to reflect Workdesk-only HUD and client config presence.
