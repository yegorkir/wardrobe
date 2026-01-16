# 2026-01-17 changelog_client_ticket_flow

- Reviewed Workdesk drag/drop flow to locate where clients are reassigned when tray items are picked up.
- Confirmed tray picks call `_try_assign_after_tray_pick()` and that it can clear a desk immediately after a tray slot is emptied.
- Updated `WardrobeDragDropAdapter` to check the current desk state and skip auto-assign if a client is still present.
- Extended `DeskServicePointSystem` tray spawning to place pickup tickets on the tray when a returning client is assigned.
- Added a unit test covering pickup ticket spawn behavior.
- Added tray pickup guard to avoid assigning a new client while a desk is still occupied.
- Routed desk assignment through desk-id lookup when tray slots are cleared.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0; log still shows the existing "Condition \"ret != noErr\" is true" warning).
- Launched `"$GODOT_BIN" --path .` to validate startup; process started and logged scene initialization before timing out in the automation.
