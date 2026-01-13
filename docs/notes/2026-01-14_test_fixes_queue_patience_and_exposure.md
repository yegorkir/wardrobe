# 2026-01-14_test_fixes_queue_patience_and_exposure

## Summary
- Aligned queue/patience/exposure tests with current system signatures and behaviors.
- Added a queue system configurator to desk service tests to avoid delayed requeue in unit scenarios.
- Adjusted exposure-related test parameters to match current vampire/zombie thresholds.

## Changes
- Removed duplicate class header in `ClientQueueSystem` and added typed policy field.
- Added `configure_queue_system` to `DeskServicePointSystem` and used it in desk tests with zero-delay config.
- Updated patience tests for the new `tick_patience` signature and updated exposure tests for current thresholds.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (passes; warnings emitted in log).
- `"$GODOT_BIN" --path .` (timed out after 10s; Godot launched and logged startup messages).

## Diagnostics
- `gdscript_diag.get_diagnostics` failed because Godot LSP is not running.

## References
- https://docs.godotengine.org/en/4.5/classes/class_dictionary.html
- https://docs.godotengine.org/en/4.5/classes/class_callable.html
