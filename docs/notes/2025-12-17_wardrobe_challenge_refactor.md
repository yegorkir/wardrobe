# Wardrobe challenge refactor

## Observations
- `scripts/ui/wardrobe_scene.gd` currently owns UI binding, input handling, challenge state, metrics, and persistence logic in a single Node script (~600 lines). This mixes presentation and domain responsibilities and makes the challenge flow hard to test or reuse.
- Challenge persistence (`user://challenge_bests.json`) is performed directly from the scene script, so file I/O cannot be substituted or mocked.
- Challenge state is represented by a dozen `_challenge_*` vars that leak into unrelated methods (HUD, seeding, etc.), which complicates reasoning about the state transitions.

## Refactor goal
Introduce a dedicated challenge controller object that encapsulates challenge session state (definition, metrics, best results). `WardrobeScene` will ask the controller what to show and notify it about player actions/slots. This keeps slot/item wiring inside the scene while isolating the domain rules.

## Implementation plan
1. Add `scripts/app/challenge/challenge_controller.gd` (RefCounted) with a focused API: load definition/best data, expose derived state (overlay text, summary values), and advance orders/metrics.
2. Replace the `_challenge_*` fields/methods with a controller instance inside `WardrobeScene`, delegating calls such as `start_challenge`, `handle_interaction`, `record_best_results`, and overlay/summary formatting.
3. Keep existing behaviour by moving the original helper logic into the controller; adapt usages and ensure tests still cover the new flow (`tests/functional/wardrobe_scene_test.gd`).

## Outcome
- Added `WardrobeChallengeController` that encapsulates challenge definition, metrics tracking, overlay/summary view models, and best-results persistence flags.
- Simplified `scripts/ui/wardrobe_scene.gd` so it now instantiates/configures the controller, delegates interaction metrics + order advancement, and only deals with Node/scene wiring (slots, HUD widgets, ticket indicators).
- Persisted best results through the controller, with `WardrobeScene` acting as the infrastructure layer that loads/saves JSON data.

## Follow-up (data service extraction)
- Introduced `WardrobeDataService` to centralize all JSON-based file loading/saving (challenges, seeds, best-results). `WardrobeScene` now injects this service into the challenge controller bootstrap and uses it whenever it needs fresh seeds or to persist best runs, keeping the scene script focused on presentation logic only.
