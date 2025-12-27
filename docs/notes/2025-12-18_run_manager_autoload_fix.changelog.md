# Changelog — 2025-12-18 RunManager Autoload Fix

## Investigation
- Reproduced the reported `Class "RunManagerBase" hides a global script class` parser error by running `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/godot" ./addons/gdUnit4/runtest.sh -a ./tests` while the autoload script originally declared `class_name RunManagerBase`; the stack trace pointed back to `scripts/autoload/bases/run_manager_base.gd:1`.
- Confirmed that the root of the warning is the autoload publishing the same global class as the base script, which prevents other scripts and tests from typing against `RunManagerBase` safely.

## Changed
- `scripts/autoload/run_manager.gd` now simply `extends RunManagerBase` and no longer defines `class_name RunManagerBase`, so the autoload no longer re-registers the singleton class and relies on the shared base.
- `scripts/autoload/bases/run_manager_base.gd` now begins with `class_name RunManagerBase`, preserving the named type for UI adapters and tests while keeping the autoload implementation anonymous.

## Tests
- `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/godot" ./addons/gdUnit4/runtest.sh -a ./tests` (before the fix the run crashed with the reported parser error; after switching the scripts the command still aborts early because the CLI runner cannot find `GdUnitTestCIRunner` / `CmdOption` etc., so rerun once the gdUnit4 helper classes are available again to verify the full suite).
