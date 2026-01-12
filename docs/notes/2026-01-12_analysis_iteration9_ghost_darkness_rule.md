# Iteration 9 — Analysis: Ghost darkness interaction

## Scope
Add ghost archetype interaction rules tied to light: ghost items cannot be picked in darkness, but behave normally in light. Show feedback only after a blocked attempt. Log blocking in debug only.

## Requirements (confirmed)
- Ghost settings live in item config.
- No pre-emptive UI hint; show effect after failed attempt only.
- Log `GHOST_PICK_BLOCKED` in DebugLog only (not ShiftLog).
- Rule implemented via a rule provider; input code must not check light/archetype directly.

## Architecture (clean boundaries)
- Domain/app owns the rule decision.
- UI/adapters only query the rule and render feedback.
- Light state provided via Light Query contract (no scene traversal in domain).

## Domain model
- Item config includes `is_ghost` (or `archetype_id == GHOST`) and `ghost_dark_alpha`.
- Rule provider API:
  - `can_pick(item_state, is_in_light) -> bool`

## Flow
1) Input attempts pick.
2) Adapter queries light state for the item.
3) Adapter calls rule provider.
4) If blocked:
   - cancel interaction
   - show feedback effect
   - debug log
5) If allowed: proceed normally.

## Risks & mitigations
- Archetype confusion: enforce item archetype separate from client archetype.
- Light dependency: only use Light Query contract.
- Gate timing: check before execute_interaction.
- No duplicate logic: single rule provider.
- Feedback timing: post-attempt only.

## Risk checklist (clean architecture)
- [ ] Item archetype defined in item config/state (no client archetype use).
- [ ] Light state comes only from Light Query contract.
- [ ] Gate before `execute_interaction` (no state mutation on blocked pick).
- [ ] Single Rule Provider (no duplicate logic in UI).
- [ ] Visual effect only after blocked attempt.
- [ ] Debug-only logging (no ShiftLog noise).
- [ ] Edge case: item already in hand when lights go dark explicitly handled.

## Tests (requirements)
- Unit:
  - ghost + light -> true
  - ghost + dark -> false
  - non-ghost + any -> true
- Integration:
  - toggle light on/off and attempt pick
  - ensure no state mutation on blocked pick

## Engine references (Godot 4.5)
- CanvasItem modulate/alpha (visual feedback):
  https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html
