# Checklist: queue return after ticket dropoff

- [x] Review queue and desk flow to confirm dropoff uses a different queue system instance than the ticked one.
- [x] Add a queue-system setter to `DeskServicePointSystem` for dependency injection.
- [x] Pass the shared queue system from `WardrobeWorldSetupAdapter` into `DeskServicePointSystem`.
- [x] Add a unit test that fails if dropoff requeue is not processed by the shared queue system.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (log shows `ERROR: Condition "ret != noErr" is true. Returning: ""` but exit code was 0).
- [x] Run `"$GODOT_BIN" --path .`.
