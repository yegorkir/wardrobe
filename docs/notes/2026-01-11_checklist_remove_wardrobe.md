# Checklist: Remove Wardrobe Screen

- [x] Remove Wardrobe screen scene and Wardrobe-only scripts (`WardrobeScene.tscn`, `wardrobe_scene.gd`, `wardrobe_interaction_adapter.gd`, `player_controller.gd`).
- [x] Replace Wardrobe HUD adapter with a Workdesk-specific adapter and rewire Workdesk scene to use it.
- [x] Remove Wardrobe legacy routing and menu entry (`main.gd`, `main_menu.gd`, `MainMenu.tscn`).
- [x] Update tests to drop Wardrobe coverage and verify Workdesk HUD updates (`skeleton_validation.gd`, remove Wardrobe test file).
- [x] Update current documentation to reference Workdesk instead of Wardrobe (`docs/project.md`, step docs).
- [x] Run canonical tests.
- [x] Launch Godot once for runtime startup validation.
