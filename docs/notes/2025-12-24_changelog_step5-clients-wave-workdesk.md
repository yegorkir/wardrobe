# 2025-12-24 — Changelog: Step 5 clients/wave workdesk

- Added `scenes/prefabs/DeskServicePoint_Workdesk.tscn` with client placeholder and patience bar UI controls, all using `mouse_filter = IGNORE` to keep DnD intact.
- Swapped Workdesk desk instances to the new prefab in `scenes/screens/WorkdeskScene.tscn` while preserving node names and positions.
- Created `scripts/ui/workdesk_clients_ui_adapter.gd` to render client presence, color, and patience ratio without per-refresh node lookups.
- Implemented local wave timer, patience ticking, and served-client win/fail flow in `scripts/ui/workdesk_scene.gd` using a desk-event bridge that counts `EVENT_CLIENT_COMPLETED`.
- Wired WorkdeskScene to initialize client UI state from existing Step 3 setup data and refresh visuals each tick.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log contains an audio init error line).
- Fixed Workdesk desk-events bridge typing by introducing `scripts/ui/workdesk_desk_events_bridge.gd` and wiring WorkdeskScene to the typed adapter.
- Fixed build parser errors by removing the duplicate `EventSchema` constant in the bridge and adding explicit typing for client coat colors.
- Re-ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log contains an audio init error line).
- Ran `task build-all`; build produced macOS editor settings save errors but completed with exit code 0.
