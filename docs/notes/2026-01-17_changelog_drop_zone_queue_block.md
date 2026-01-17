# Changelog: drop zone blocks desk assignment

- Added a drop-zone blocker callback to `DeskServicePointSystem` to prevent assigning a new client when the drop zone is occupied.
- Indexed desk drop zones in `WorkdeskScene` and wired the blocker callback.
- Updated `ClientDropZone` to detect overlapping item bodies for occupancy checks.
- Added a unit test covering the blocker behavior.
- Added debug logs for drop zone blocking and desk assignment skips.
- Added detailed drop zone overlap diagnostics and pre-check logs for desk assignment.
- Enforced drop zone collision mask/layer before overlap checks to ensure item bodies are detectable.
- Blocked desk assignment when tray slots contain items and added a unit test for it.
- Cleared desk assignment and set client presence to away after ticket delivery, even when tray items block new assignments.
- Triggered a desk assignment attempt when a tray slot is emptied.
