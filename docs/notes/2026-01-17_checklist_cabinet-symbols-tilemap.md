# Checklist: Cabinet Symbols Tilemap

- [x] Locate cabinet layout scene, slot ids, and step3 ticket seeding to confirm how cabinet slots are indexed.
- [x] Add a shared atlas helper for 15x12 slicing and active tile count control (8 entries for now).
- [x] Assign a stable symbol index per cabinet slot and refresh cabinet plate icons after indexing.
- [x] Add plate icon placeholders to `StorageCabinetLayout_Simple` and apply `ankors.png` tiles to them.
- [x] Add a dedicated ticket symbol overlay scene and drive it with `symbols.png` tiles per slot.
- [x] Run `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- [x] Launch Godot once with `"$GODOT_BIN" --path .`.
