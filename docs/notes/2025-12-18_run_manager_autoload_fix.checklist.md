# Checklist — 2025-12-18 RunManager Autoload Fix

- [x] Reproduce the `RunManagerBase` parser crash by running `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/godot" ./addons/gdUnit4/runtest.sh -a ./tests` with the autoload still declaring `class_name RunManagerBase`.
- [x] Remove the `class_name` from `scripts/autoload/run_manager.gd`, extend the shared `RunManagerBase` type, and reintroduce the global class in `scripts/autoload/bases/run_manager_base.gd`.
- [x] Record the investigation, fix, and test outcomes in `docs/notes/2025-12-18_run_manager_autoload_fix.changelog.md`.
- [x] Attempt to rerun `./addons/gdUnit4/runtest.sh -a ./tests`; the updated setup now aborts before the suite loads because `gdUnit4` cannot resolve CLI helper types (`GdUnitTestCIRunner`, `CmdOption`, `GdUnitResult`, etc.), so rerun once the plugin classes are compiled/mapped.
