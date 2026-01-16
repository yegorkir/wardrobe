# Changelog: Queue Entry Animation

- Reviewed Queue HUD layout in `scenes/screens/WorkdeskScene.tscn` to confirm QueueItems sits left of QueueKpis and to align the new entry path.
- Updated `scripts/ui/queue_hud_view.gd` to add explicit animation constants and a QueueKpis reference for the entry tween.
- Replaced the small content nudge with a top-level tween that starts the new item at the QueueKpis right edge, fades it in, and slides it left into its slot, then restores container control.
- Added a fallback append animation for safety when QueueKpis is unavailable.
- Switched the QueueKpis lookup to `get_node_or_null("%QueueKpis")` to avoid missing-node errors in headless tests.
- Ran `task tests` and launched Godot to confirm startup logs after the animation update.
- Increased the queue entry travel distance by adding an explicit extra offset so the motion reads clearly on screen.
- Aligned the entry start position to the right edge of the QueueItems container so the client appears from the queue zone edge.
- Added queue exit animation in `scripts/ui/queue_hud_view.gd` to move clients down, scale them to 50%, and fade them out over 0.4s when they leave the queue.
- Implemented desk entry animation in `scripts/ui/workdesk_clients_ui_adapter.gd` that delays 0.4s, then slides the client down into place while scaling from 50% to normal and fading in.
- Added desk client tracking to only run entry animation on new assignments and to reset visuals when a desk clears.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (log includes `ERROR: Condition "ret != noErr" is true` but exit code 0) and launched Godot (`"$GODOT_BIN" --path .`), which timed out after 10s with startup logs present.
