# Analysis: Remove Wardrobe Screen

## Goal
Remove the Wardrobe screen and all supporting code/assets/tests/docs so the project only maintains Workdesk as the main gameplay screen.

## Scope
- Delete Wardrobe scenes, UI adapters, and related scripts.
- Remove Wardrobe-specific tests and test helpers.
- Update documentation to reflect Workdesk as the sole screen.
- Ensure build/startup still launches correctly with Workdesk.

## Non-goals
- No new gameplay features.
- No refactors unrelated to Wardrobe removal.

## Current touchpoints
- Scene(s): `WardrobeScene.tscn` and any prefabs/nodes unique to Wardrobe.
- UI adapter: `scripts/ui/wardrobe_hud_adapter.gd`.
- Tests: `tests/functional/wardrobe_scene_test.gd`, `tests/functional/skeleton_validation.gd` (HUD expectations).
- Docs: `docs/project.md`, `docs/technical_design_document.md`, step docs referencing Wardrobe HUD or Wardrobe screen.

## Clean architecture impact
- Removing Wardrobe should only affect UI/adapters/tests and documentation.
- App/domain layers should not depend on Wardrobe; no changes expected unless a UI adapter is currently the only consumer of a signal.

## Risks and mitigations
- **Broken references**: Scenes or scripts may be referenced by `Main.tscn`, `scripts/ui/main.gd`, or tests. Mitigate by updating dispatch to Workdesk.
- **Missing HUD adapter**: If Wardrobe HUD adapter is reused elsewhere, replace with a Workdesk-specific adapter or new queue HUD adapter.
- **Docs drift**: Remove or update any mention of Wardrobe as a supported screen.

## Open questions
- Confirm whether any non-Wardrobe scene depends on `WardrobeHudAdapter` or Wardrobe HUD nodes.

## References
- SceneTree (for screen switching impact): https://docs.godotengine.org/en/4.5/classes/class_scenetree.html
