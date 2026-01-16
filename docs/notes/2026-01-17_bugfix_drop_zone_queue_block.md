# Bugfix: block desk assignment when drop zone is occupied

## Summary
Prevent desks from assigning a new client when the client drop zone contains items. This keeps the client in the queue until the drop zone is cleared.

## Root cause
Desk assignment logic did not consider items lingering in `ClientDropZone`, so a new client could take the desk even when foreign items were still in the area.

## Fix
- Add a drop-zone blocker callback to `DeskServicePointSystem` and wire it from `WorkdeskScene`.
- Track drop zones by desk id and query them before assigning a new client.
- Update `ClientDropZone` to detect overlapping item bodies via `Area2D.get_overlapping_bodies()`.
- Clear desk assignment and mark clients away after ticket delivery even when tray items block new assignments.
- Trigger a desk assignment attempt when a tray slot is emptied so queued clients can fill the desk.

## Notes
- `Area2D.get_overlapping_bodies()` reference: https://docs.godotengine.org/en/4.5/classes/class_area2d.html#class-area2d-method-get-overlapping-bodies

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`
