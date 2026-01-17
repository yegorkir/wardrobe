# Checklist: Bulb Visual Setup

- [x] Review existing bulb visual, light switch, and light rig scripts to understand current wiring expectations.
- [x] Add an exported external visual node reference to the bulb visual script for parent-scene wiring.
- [x] Implement `set_is_on` to toggle BulbOn/BulbOff sprites and propagate state to the external visual.
- [x] Initialize bulb sprite visibility and external visual sync on ready.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once with `"$GODOT_BIN" --path .`.
