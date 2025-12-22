# Checklist: Remove legacy interaction path

- [x] Confirm legacy scope (Node-level interaction engine/target) and current usage.
- [x] Remove `scripts/wardrobe/interaction_engine_legacy.gd` and `scripts/wardrobe/interaction_target.gd`.
- [x] Remove related `.uid` files for deleted scripts.
- [x] Re-scan `scripts/` and `scenes/` for any remaining references.
- [x] Run `./addons/gdUnit4/runtest.sh -a ./tests/unit`.
- [x] Update `docs/notes/2025-12-22_remove_interaction_legacy_analysis.md` with verification results.
