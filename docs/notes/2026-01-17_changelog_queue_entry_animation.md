# Changelog: Queue Entry Animation

- Reviewed Queue HUD layout in `scenes/screens/WorkdeskScene.tscn` to confirm QueueItems sits left of QueueKpis and to align the new entry path.
- Updated `scripts/ui/queue_hud_view.gd` to add explicit animation constants and a QueueKpis reference for the entry tween.
- Replaced the small content nudge with a top-level tween that starts the new item at the QueueKpis right edge, fades it in, and slides it left into its slot, then restores container control.
- Added a fallback append animation for safety when QueueKpis is unavailable.
- Switched the QueueKpis lookup to `get_node_or_null("%QueueKpis")` to avoid missing-node errors in headless tests.
- Ran `task tests` and launched Godot to confirm startup logs after the animation update.
- Increased the queue entry travel distance by adding an explicit extra offset so the motion reads clearly on screen.
- Aligned the entry start position to the right edge of the QueueItems container so the client appears from the queue zone edge.
