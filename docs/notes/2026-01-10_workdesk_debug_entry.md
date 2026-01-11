# 2026-01-10 — Workdesk debug entry

## Context
Need to expose the debug Workdesk scene from the main menu so it is reachable from the editor without toggling flags on the production scene.

## Changes
- Added `WorkdeskScene_Debug.tscn` to the screen registry (`scripts/ui/main.gd`) and RunManager (`SCREEN_WARDROBE_DEBUG`) so it can be requested like other screens.
- Wired a dedicated “Start Run (Workdesk Debug)” button in the main menu (`scenes/screens/MainMenu.tscn`, `scripts/ui/main_menu.gd`) to start the shift with the debug scene.
- Kept the production scene defaults clean (no-fail off, logs off).

## Verification
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0; log shows existing landing behavior name warnings and `ret != noErr` audio line).
- `"$GODOT_BIN" --path .` (launch OK; shows standard PICK logs).
