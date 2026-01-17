# 2026-01-17 checklist_client_ticket_flow

- [x] Inspected drag/drop delivery and desk assignment code paths to find early client clearing on tray pickup.
- [x] Verified desk assignment logic only spawns coat items for drop-off clients, not tickets for pickup clients.
- [x] Guarded tray-based auto-assignment so it does not run when the desk already has a current client.
- [x] Implemented pickup ticket spawning by inserting the client's stored ticket into a free tray slot during assignment.
- [x] Added a unit test that asserts pickup tickets are spawned into tray slots.
- [ ] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [ ] Launch Godot with `"$GODOT_BIN" --path .`.
- [x] Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0; warning about `ret != noErr` logged).
- [!] Launched `"$GODOT_BIN" --path .` but the command timed out while the editor stayed open; rerun if you want a clean completion signal.
