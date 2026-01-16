# Iteration 9 — Plan: Ghost darkness interaction

## Goals
- Block ghost item pick in darkness.
- Keep non-ghost behavior unchanged.
- Provide feedback only after a blocked attempt.
- Log blocks in DebugLog only.

## Plan steps
1) **Domain: Archetype & Rules**
   - Modify `scripts/domain/content/item_archetype_definition.gd`: Add `is_ghost` flag and `ghost_dark_alpha` (float).
   - Create `scripts/domain/interaction/interaction_rules.gd`:
     - Implement `static func can_pick(archetype: ItemArchetypeDefinition, is_in_light: bool) -> bool`.

2) **Visuals: Item Feedback**
   - Modify `scripts/wardrobe/item_node.gd`:
     - Add `play_reject_effect()`: Simple tween (e.g., modulate alpha to 0.5 and back, or flash red).

3) **UI: DragDrop Adapter**
   - Modify `scripts/ui/wardrobe_dragdrop_adapter.gd`:
     - Add `configure_rules(validate_callback: Callable)`.
     - In `_try_pick_surface_item` and `_perform_slot_interaction`:
       - Call `validate_callback`.
       - If false: call `item_node.play_reject_effect()`, log debug, and return early.

4) **App: Integration in WorkdeskScene**
   - Modify `scripts/ui/workdesk_scene.gd`:
     - Update `_get_item_archetype` to handle "ghost_sheet" (or similar ID) and set `is_ghost = true`.
     - Implement `_validate_pick_rule(item_id: StringName) -> bool`.
       - Get instance, archetype, and light state (via `_light_zones_adapter`).
       - Delegate to `InteractionRules.can_pick`.
     - Pass this callback to `_dragdrop_adapter.configure_rules`.

5) **Tests**
   - Create `tests/unit/domain/interaction/test_interaction_rules.gd`.
   - Update/Create integration test in `tests/integration/` to verify ghost pick behavior.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`