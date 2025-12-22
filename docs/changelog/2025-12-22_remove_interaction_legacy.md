# Changelog: Remove legacy interaction path

- Recorded the legacy-removal task and plan in `docs/notes/2025-12-22_remove_interaction_legacy_analysis.md`.
- Removed unused Node-level legacy interaction files: `scripts/wardrobe/interaction_engine_legacy.gd` and `scripts/wardrobe/interaction_target.gd`.
- Removed `.uid` metadata for the deleted scripts.
- Verified no remaining references to the legacy interaction API in scripts/scenes.
- Ran `./addons/gdUnit4/runtest.sh -a ./tests/unit`; all 25 tests passed (warnings about duplicate class names and macOS certificate lookup reported by Godot).
