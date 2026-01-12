# Plan: Iteration 5 Item Quality Stars

## Plan overview
Implement item quality as a domain-owned system with configuration, runtime state, damage application API, and UI-only star rendering. Integrate fall damage through the landing pipeline without embedding quality math in physics or UI.

## Steps
1) **Confirm scope and config source**
- Add per-client item quality overrides in client config (per item kind).
- Define domain defaults per item kind (used when client config does not override).
- Confirm max star range (5) and initial defaults (e.g., coat=3, vampire coat=5).

2) **Domain model additions**
- Add `ItemQualityConfig` and `ItemQualityState` (RefCounted) with typed fields and clamping rules.
- Add quantized quality step rules (e.g., allowed deltas `[0.5, 1.0, 2.0]`) and store `current_stars` as float.
- Add a domain `ItemQualityService` to apply damage and return change results/events.
- Preload collaborators in domain scripts to avoid headless warnings.

3) **Item state integration**
- Extend `scripts/domain/storage/item_instance.gd` to include quality state.
- Update `duplicate_instance()` and `to_snapshot()` to include quality data.
- Add an initialization path that sets current stars from config (default max).

4) **Damage API wiring (falls)**
- Add a domain-facing `ApplyDamage` entry point (source + amount).
- In landing flow, map fall impact to a damage amount and call quality service.
- Emit `ItemQualityChanged` event/log and update any state snapshots.

5) **UI rendering**
- Add a star strip to item visuals (likely `scripts/ui/wardrobe_item_visuals.gd`).
- Render stars as icons only (no text); update on state changes.
- Support half-star visuals for 0.5 steps.
- Add a simple star-loss animation (e.g., fade/scale) on quality decrease.

6) **Debug/dev hooks**
- Add a debug spawn action that accepts `current_stars` and initializes item quality.
- Log `ITEM_QUALITY_CHANGED` with item id, old, new, and source.

7) **Tests**
- Unit tests for quality initialization, clamping, and damage application.
- Regression coverage for existing item flows (quality unchanged behaves identically).
- If landing integration is added, add a test to assert fall damage triggers quality change.

8) **Docs updates**
- Update relevant docs/design notes if item contracts change.
- Record the new domain API and config source.

## Test command (canonical)
GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests

## Runtime check (canonical)
"$GODOT_BIN" --path .
