# Analysis: Iteration 5 Item Quality Stars

## Goal
Introduce item quality as a core, extensible domain system with discrete stars that can be reduced by damage sources (MVP: falls), persist across item flows, and render as star icons on item cards.

## Context summary
- Iteration plan defines quality as domain-owned state with UI-only rendering.
- Landing flow already emits a domain landing outcome and includes reserved `quality_delta` fields.
- Item definitions are currently UI-centric (`scripts/ui/wardrobe_item_config.gd`) with no content-backed item schema.

## Requirements
- Item quality exists in domain state and is persisted with runtime items.
- Quality configuration (max stars) comes from immutable item definitions.
- Damage sources emit damage; quality math is centralized in a domain service.
- UI shows stars only (no text) and animates star loss.
- Quality persists through pick/place/drop/move.
- Debug tooling can spawn items with arbitrary initial quality.
- Quality deltas are quantized to allowed steps (e.g., 0.5, 1, 2), no arbitrary fractional loss (1.5 is not allowed).

## Proposed architecture (system design)
### Option A (preferred): Domain quality module + client-config overrides
- **Domain**
  - Add `ItemQualityConfig` and `ItemQualityState` to `scripts/domain/storage/` (or a new `scripts/domain/quality/`).
  - Add `ItemQualityService` in domain with:
    - `apply_damage(item_state, source, amount) -> ItemQualityResult`
    - clamps and emits `ItemQualityChanged` event payloads for logging/UI.
- **App**
  - Extend landing pipeline to translate fall impact into a damage request and call the domain quality service.
  - Reuse existing landing outcome `quality_delta` if applicable.
- **Content / config**
  - Max stars are defined per client config (per item kind) with domain defaults per kind.
  - Client-specific overrides allow, e.g., vampire coat max=5 while default coat max=3.
- **UI**
  - Item card (likely in `scripts/ui/wardrobe_item_visuals.gd`) renders `current_stars` using star TextureRects.
  - Listen to state changes (signal or snapshot) to update visuals.

Pros: clean separation, future corruption/light systems reuse same API; preserves domain ownership.
Cons: requires defining item config source of truth and per-client override parsing.

### Option B: App-level quality adapter (fallback)
- Keep domain item state minimal; store quality in an app-level wrapper around item instance.
- Use adapter to update UI and drive damage.

Pros: smaller domain change now.
Cons: violates SSOT and makes later corruption/lights harder; not recommended.

### Option C: Content-driven item definitions (future-ready)
- Introduce `content/items/*.json` with default `max_quality` per item kind.
- Client configs reference item kind overrides; ContentDB merges defaults + overrides.

Pros: aligns with content pipeline and keeps defaults centralized.
Cons: larger scope change; may be deferred if iteration scope tight.

## Data and module design
### Domain types
- `ItemQualityConfig` (RefCounted)
  - `max_stars: int`
- `ItemQualityStepConfig` (RefCounted, optional)
  - `allowed_steps: Array[float]` (e.g., `[0.5, 1.0, 2.0]`)
- `ItemQualityState` (RefCounted)
  - `current_stars: float`
  - `max_stars: int`
  - `apply_damage(source: StringName, amount: float) -> float` (returns delta or new value)
- `ItemQualityService` (RefCounted)
  - `compute_quality_loss(config, state, source, amount) -> float`
  - `apply_damage(...) -> ItemQualityChange` (old/new, clamped, source)

### Item state integration
- Extend `scripts/domain/storage/item_instance.gd` to include `quality_state` and update `duplicate_instance`/`to_snapshot`.
- Add a factory or constructor path to initialize quality using client config overrides or domain defaults.

### Damage hook integration
- Landing system should emit damage payloads (source: `Fall`) with impact-based amount.
- Quality math remains in domain service; landing only passes source + amount.

### UI projection
- Add a small star strip node under item visuals (use a `HBoxContainer` with star TextureRects).
- Update on item state change; animation for star loss in UI only.
- Support half-star rendering (full/half/empty star states).

## Tests
- Unit: quality initialization, clamping, damage application, and source independence.
- Regression: existing item flows unchanged when quality unchanged (no crash, no behavior change).
- If fall damage is wired: landing damage triggers quality change and event/log entry.

## Risks & mitigations
- **Missing item config source**: define a temporary domain map for max stars and plan migration to content items.
- **UI mismatch**: ensure UI reads runtime item state, not config.
- **Headless warnings**: preload any new domain scripts (per `docs/code_guidelines.md`).

## Open questions
1) Where in UI should star visuals live for the cleanest adapter boundary? I can recommend based on preferred ownership (see response).

## Decisions (confirmed)
- Fall impact maps linearly into quantized star steps, capped at 3 stars lost per fall.

## References
- RefCounted: https://docs.godotengine.org/en/4.5/classes/class_refcounted.html
- HBoxContainer: https://docs.godotengine.org/en/4.5/classes/class_hboxcontainer.html
- TextureRect: https://docs.godotengine.org/en/4.5/classes/class_texturerect.html
