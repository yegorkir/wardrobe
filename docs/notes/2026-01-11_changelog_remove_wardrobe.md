# Changelog: Remove Wardrobe Screen

- Removed the legacy Wardrobe screen assets (`scenes/screens/WardrobeScene.tscn`, `scripts/ui/wardrobe_scene.gd`), its interaction adapter (`scripts/ui/wardrobe_interaction_adapter.gd`), and the unused player controller (`scripts/wardrobe/player_controller.gd`).
- Replaced the Wardrobe-specific HUD adapter with `WorkdeskHudAdapter` and updated Workdesk wiring to keep HUD updates intact without Wardrobe dependencies.
- Loosened Wardrobe interaction context/validator typing to avoid references to the removed player controller while keeping validation available for Workdesk debug flows.
- Removed the Wardrobe legacy screen entry from `scripts/ui/main.gd`, trimmed the Start Wardrobe button from `scenes/screens/MainMenu.tscn`, and dropped the legacy start handler in `scripts/ui/main_menu.gd`.
- Updated functional tests to validate Workdesk HUD updates and removed the Wardrobe scene test coverage (`tests/functional/wardrobe_scene_test.gd`).
- Updated current documentation to describe Workdesk as the primary screen and removed Wardrobe screen references from project and step docs.
