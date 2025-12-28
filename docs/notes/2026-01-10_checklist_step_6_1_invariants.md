# 2026-01-10 — Checklist: Step 6.1 invariants

## Global debug toggle
- [x] Single global bool lives in `scripts/wardrobe/config/debug_flags.gd`.
- [x] All debug logs route through `scripts/wardrobe/debug/debug_log.gd` with early return.
- [x] Workdesk scene enables logs via `debug_logs_enabled`.

## No one-way floors
- [x] FloorZone no longer uses `one_way_collision`.
- [x] Item transfer uses RISE (no floor collisions) → FALL (floor-only collisions).
- [x] Safe transition when item bottom is above floor plane.
- [x] Failsafe snap if item keeps falling after floor collisions are enabled.
- [x] Transfer fall uses a dedicated physics layer; regular item masks do not scan it.
- [x] Floor surfaces include transfer-fall layer in their collision mask.

## Transfer diagnostics
- [x] Transfer profile application emits `TRANSFER_PROFILE_APPLIED` with layer/mask payload.
- [x] Transfer sink detector emits `TRANSFER_SINK_DETECTED` with position/velocity payload.
- [x] Hit-by logs include transfer phase and layer/mask info.
- [x] Hit-by handling ignores bodies with zero collision layer/mask (drag proxy noise).

## Landing event pipeline
- [x] Stable landing point emits `EVENT_ITEM_LANDED` (ShiftLog) with required payload.
- [x] ITEM_LANDED debug event emitted with same payload.
- [x] `surface_kind` resolved via `WardrobeSurface2D.get_surface_kind()`.
- [x] `cause` mapped from item state (DROP/REJECT/ACCIDENT/COLLISION).

## Landing behavior/outcome
- [x] LandingOutcome with effects (NONE/BOUNCE/BREAK) and future fields reserved.
- [x] LandingBehavior strategy per item_kind with registry and defaults.
- [x] App-layer record_item_landed returns outcome to UI.
- [x] UI applies outcome on landing (bounce impulse / break disable).

## Tests
- [x] Unit tests cover Default/Bouncy/Breakable and registry routing.
- [x] Functional test covers rise-then-fall transfer landing.
- [x] Functional test covers passive fall landing event.
- [x] Functional test covers item knocked from shelf landing on floor + ShiftLog event.
