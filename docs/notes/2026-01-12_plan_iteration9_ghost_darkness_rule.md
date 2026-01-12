# Iteration 9 — Plan: Ghost darkness interaction

## Goals
- Block ghost item pick in darkness.
- Keep non-ghost behavior unchanged.
- Provide feedback only after a blocked attempt.
- Log blocks in DebugLog only.

## Plan steps
1) **Extend item config**
   - Add `is_ghost` (or `archetype_id == GHOST`) and `ghost_dark_alpha`.

2) **Rule provider**
   - Implement `ItemInteractionRules.can_pick(item_state, is_in_light)`.
   - Ghost + dark -> false.

3) **Light query integration**
   - Use Light Query contract to compute `is_in_light(item)`.
   - Do not query scene in domain.

4) **Gate in drag/drop adapter**
   - Check rule before `execute_interaction`.
   - If blocked: cancel interaction, show feedback, debug log.

5) **UI feedback**
   - Apply a short alpha/flash effect after blocked attempt.
   - Do not pre-emptively show hints.

6) **Debug logging**
   - `GHOST_PICK_BLOCKED item_id=... reason=darkness`
   - Guarded by debug flag.

7) **Tests**
   - Unit tests for rule provider.
   - Integration test: blocked pick does not mutate state.

## Verification
- Run canonical tests:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Launch Godot once:
  - `"$GODOT_BIN" --path .`
