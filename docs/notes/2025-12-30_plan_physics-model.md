# Plan: Adjust Shelf Physics Model (Overlap/Push)

## Goal
Reduce "push-back" behavior near shelf edges by correcting the overlap resolution model to be more physically consistent and less impulse-driven.

## Proposed Steps
1) Choose model variant (A: one-sided impulse, B: MTV position solve, C: shape-cast).
2) Implement the chosen model in `scripts/ui/wardrobe_physics_tick_adapter.gd`.
3) Adjust thresholds and logging to preserve "small overlap ok, big overlap reject" behavior.
4) Verify behavior via tests and a manual run.

## Chosen Design (Variant B - One-sided impulse)
- Remove reverse impulses to neighbors in `_apply_mass_aware_pushes`.
- Apply impulse only to the moving item and let physics contacts move others.
- Let neighbors wake via physical contacts (no direct impulse wake).
- Keep reject rules and COG-based bounds unchanged.
- Add a short per-item overlap cooldown to avoid repeated micro-push cycles.

## Files to Touch
- `scripts/ui/wardrobe_physics_tick_adapter.gd`
- `docs/notes/2025-12-30_analysis_physics-model.md`
- `docs/notes/2025-12-30_changelog_overlap-reject.md`
- `docs/notes/2025-12-30_checklist_overlap-reject.md`

## Validation
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`
