# Plan: Remove Wardrobe Screen

## Plan overview
Remove Wardrobe screen/scene/adapters/tests/docs so the project only maintains the Workdesk flow.

## Steps
1) **Inventory references**
- Find references to Wardrobe scenes/scripts in `scripts/ui/main.gd`, `scenes/Main.tscn`, and autoloads.
- List tests and docs that mention Wardrobe.

2) **Remove Wardrobe scenes and scripts**
- Delete `WardrobeScene.tscn` (and any Wardrobe-only prefabs).
- Delete `scripts/ui/wardrobe_hud_adapter.gd` if it is Wardrobe-only.
- Remove any Wardrobe-only scripts under `scripts/ui/` or `scripts/wardrobe/`.

3) **Update screen routing**
- Ensure `scripts/ui/main.gd` routes directly to Workdesk as the sole screen.
- Remove Wardrobe routes or menu options if present.

4) **Adjust tests**
- Remove `tests/functional/wardrobe_scene_test.gd`.
- Update `tests/functional/skeleton_validation.gd` to validate Workdesk HUD if needed.

5) **Update documentation**
- Remove Wardrobe references in `docs/project.md`, `docs/technical_design_document.md`, and any step docs.
- Ensure docs describe Workdesk as the only active screen.

6) **Sanity check**
- Confirm the project starts into Workdesk without missing scene/script references.

## Test command (canonical)
GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests

## Runtime check (canonical)
"$GODOT_BIN" --path .
