# Iteration 9 — Analysis: Ghost darkness interaction

## Scope
Add ghost archetype interaction rules tied to light: ghost items cannot be picked in darkness, but behave normally in light. Show feedback only after a blocked attempt. Log blocking in debug only.

## Requirements (confirmed)
- Ghost settings live in item archetype (`is_ghost`).
- No pre-emptive UI hint; show effect after failed attempt only.
- Log `GHOST_PICK_BLOCKED` in DebugLog only (not ShiftLog).
- Rule implemented via a rule provider (`InteractionRules`); input code must not check light/archetype directly.

## Architecture (clean boundaries)
- **Domain (`InteractionRules`)**: Owns the rule logic (`can_pick(archetype, is_in_light)`).
- **App/Adapter (`WorkdeskScene`)**: Coordinates the check. It has access to `ItemInstance` (Archetype) and `LightZonesAdapter` (Light State).
- **UI (`WardrobeDragDropAdapter`)**: Enforces the rule during input handling. It requests validation via a callback before allowing a pick.
- **Visuals (`ItemNode`)**: displays the rejection feedback (e.g., alpha flash) when triggered by the adapter.

## Domain model
- `ItemArchetypeDefinition`: Add `is_ghost`.
- `InteractionRules` (new static class):
  - `can_pick(archetype: ItemArchetypeDefinition, is_in_light: bool) -> bool`

## Flow
1) Input (Mouse Down) detected in `WorkdeskScene`.
2) `WardrobeDragDropAdapter` identifies target item.
3) Adapter calls injected `validate_pick_callback(item_id)`.
4) `WorkdeskScene` (inside callback):
   - Looks up `ItemInstance` -> `ItemArchetypeDefinition`.
   - Checks `LightZonesAdapter.is_item_in_light(item_node)`.
   - Calls `InteractionRules.can_pick(...)`.
   - If blocked: returns `false`.
5) If blocked:
   - `WardrobeDragDropAdapter` cancels pick.
   - Calls `item_node.play_reject_effect()`.
   - Logs `GHOST_PICK_BLOCKED` to DebugLog.
6) If allowed: proceed with pick (`hold_item` or `build_interaction_command`).

## Risks & mitigations
- **Archetype confusion**: Enforce use of `ItemArchetypeDefinition` from domain, not ad-hoc flags.
- **Light dependency**: Use existing `LightZonesAdapter` in `WorkdeskScene`.
- **Feedback timing**: Ensure effect plays *immediately* on click, even if pick is rejected.
- **State mutation**: Ensure `ItemNode` physics/state doesn't change (e.g., doesn't enter `DRAGGING` state) if rejected.

## Risk checklist (clean architecture)
- [ ] `ItemArchetypeDefinition` extended with `is_ghost`.
- [ ] `InteractionRules` created in `domain/interaction`.
- [ ] `WardrobeDragDropAdapter` decoupled from domain rules via callback.
- [ ] `ItemNode` implements `play_reject_effect` (visual only).
- [ ] Debug-only logging (no ShiftLog noise).
- [ ] Edge case: item already in hand when lights go dark? (Rule applies to *pick* action, so holding is fine per current scope).

## Tests (requirements)
- Unit (`InteractionRules`):
  - ghost + light -> true
  - ghost + dark -> false
  - non-ghost + any -> true
- Integration (`WorkdeskScene`):
  - Toggle light off -> click ghost -> assert not picked, feedback played.
  - Toggle light on -> click ghost -> assert picked.