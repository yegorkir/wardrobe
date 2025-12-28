# Drag release logging

## Context
- Bug: items sometimes keep following the cursor after drag release.
- Goal: add targeted debug logging to trace drag state transitions without changing behavior.

## Logging points added
- `ItemNode`: logs enter/exit drag state transitions when `debug_log` is enabled.
- `CursorHand`: logs hand pickup/release transitions when `debug_log` is enabled.
- `WardrobeDragDropAdapter`: logs pointer down/up, watchdog cancel, pick/drop outcomes when `debug_log` is enabled.

## How to enable
- Toggle `debug_log` on the relevant scene nodes (Item nodes, CursorHand, DragDrop adapter owner) to capture logs during repro.

## Next capture focus
- Confirm that `pointer_up` and `take_item_from_hand` log lines appear when the bug happens.
- Check whether `exit_drag_mode` logs for the same item are missing when the cursor keeps following.
