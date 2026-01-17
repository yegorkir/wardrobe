# Changelog: Remove drag shake

- Disabled the drag-warning shake loop in `CursorHand` by always cancelling any existing shake tween and resetting the held item position to the cursor anchor.
- Kept the warning icon and color modulation intact so unsupported drag feedback remains visible without motion.
- Ran `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit code 0; log still reports the recurring `ret != noErr` line from Godot).
- Launched Godot with `"$GODOT_BIN" --path .` to verify startup; process produced normal startup logs before the command timed out at 10s.
