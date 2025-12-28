# 2026-01-10 — Changelog: Step 6.1 no one-way + landing behavior

## Added
- Transfer-fall physics layer and mask constants for isolation:
  - `scripts/wardrobe/config/physics_layers.gd`
- Targeted transfer debug events:
  - `TRANSFER_PROFILE_APPLIED`
  - `TRANSFER_SINK_DETECTED`
  - see `scripts/wardrobe/item_node.gd`
- Global debug logging toggle + helper utilities:
  - `scripts/wardrobe/config/debug_flags.gd` (single bool)
  - `scripts/wardrobe/debug/debug_log.gd` (log/logf/event with early-return)
- Landing behavior pipeline in app layer:
  - `scripts/app/wardrobe/landing/landing_outcome.gd`
  - `scripts/app/wardrobe/landing/landing_behavior.gd`
  - `scripts/app/wardrobe/landing/default_landing_behavior.gd`
  - `scripts/app/wardrobe/landing/bouncy_landing_behavior.gd`
  - `scripts/app/wardrobe/landing/breakable_landing_behavior.gd`
  - `scripts/app/wardrobe/landing/landing_behavior_registry.gd`
  - `scripts/app/wardrobe/landing/landing_service.gd`
- New landing event schema fields in `scripts/domain/events/event_schema.gd`:
  - `EVENT_ITEM_LANDED`
  - payload keys (`item_id`, `surface_kind`, `cause`, `impact`)
  - cause/surface constants
- New tests:
  - `tests/unit/landing_behavior_test.gd` (behavior + registry)
  - `tests/functional/test_landing_floor_transfer.gd` (rise-then-fall landing + passive fall event)
  - `tests/functional/test_shelf_knockoff_landing.gd` (item knocked off shelf lands + logs EVENT_ITEM_LANDED)

## Changed
- Floor transfer now uses collision profiles (no one-way floors):
  - RISE ignores floor collisions, FALL collides with floor only
  - safe RISE→FALL transition with snap-above-floor
  - failsafe landing after N frames below target
  - see `scripts/wardrobe/item_node.gd`
- Hit-by handling ignores collisions from bodies with zero layer/mask to reduce transfer/drag noise:
  - `scripts/wardrobe/item_node.gd`
- Transfer fall now uses a dedicated collision layer; floor surfaces scan it:
  - `scripts/wardrobe/item_node.gd`
  - `scripts/ui/floor_zone_adapter.gd`
- Landing event emission and outcome application:
  - `scripts/ui/wardrobe_physics_tick_adapter.gd` emits ITEM_LANDED (debug) and app event via RunManager
  - applies LandingOutcome (BOUNCE/BREAK/NONE)
- Unified debug logging to the global flag:
  - `scripts/wardrobe/item_node.gd`
  - `scripts/wardrobe/cursor_hand.gd`
  - `scripts/ui/wardrobe_dragdrop_adapter.gd`
  - `scripts/ui/wardrobe_physics_tick_adapter.gd`
  - `scripts/ui/shelf_surface_adapter.gd`
  - `scripts/ui/floor_zone_adapter.gd`
- ShiftService + RunManager now expose landing event handling:
  - `scripts/app/shift/shift_service.gd` records landing events in ShiftLog
  - `scripts/autoload/bases/run_manager_base.gd` forwards record_item_landed + exposes get_shift_log
- Surface adapters now report `surface_kind`:
  - `scripts/wardrobe/surface/wardrobe_surface_2d.gd`
  - `scripts/ui/floor_zone_adapter.gd`
  - `scripts/ui/shelf_surface_adapter.gd`
- Workdesk scene debug toggle migrated to global flag:
  - `scripts/ui/workdesk_scene.gd`
  - `scenes/screens/WorkdeskScene.tscn`
- Removed per-node debug_log properties from scenes:
  - `scenes/prefabs/item_node.tscn`
  - `scenes/prefabs/StorageCabinetLayout_Simple.tscn`
  - `scenes/screens/WorkdeskScene.tscn`
- Step 6.1 docs updated to mention no one-way + ItemLanded + LandingOutcome:
  - `docs/steps/06_1_Surface_Placement.md`

## Removed
- one_way floor collisions on FloorZone:
  - `scripts/ui/floor_zone_adapter.gd`
