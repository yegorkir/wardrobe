# Changelog: Physics placement gate + terminal reject

- Added SSOT layer/mask/group configuration in `scripts/wardrobe/config/physics_layers.gd` and wired it into item/shelf/floor adapters.
- Consolidated `ItemNode` geometry helpers (AABB, bottom Y, snap) and routed legacy bottom helpers through the new API.
- Switched pass-through to floor-only collision masks and added explicit reject-fall state handling in `scripts/wardrobe/item_node.gd`.
- Introduced `SurfaceRegistry` autoload with floor/shelf registration, bounds-aware floor selection, and registry cleanup helpers.
- Registered shelf/floor adapters in the registry during `_ready()`/`_exit_tree()` and applied SSOT layers to `SurfaceBody`/`DropArea` nodes.
- Added `PhysicsPlacementGate` decision helper and refactored overlap handling to use ALLOW/ALLOW_NUDGE/REJECT decisions in `scripts/ui/wardrobe_physics_tick_adapter.gd`.
- Implemented terminal reject fall-through: reject now selects floor by `surface_y`, enables pass-through, and skips further overlap resolution while falling.
- Limited overlap nudges to the active item only to respect stable immunity (no neighbor impulses).
- Updated drag/drop adapter to use registry-based floor lookup, SSOT pick query mask, and bottom-Y-based pass-through thresholds.
- Synced prefab/scene collision layers for item pick areas, shelf bodies, and floor bodies.
- Added integration tests for ItemNode geometry contracts and physics layer SSOT expectations.
- Renamed the autoload class to avoid `SurfaceRegistry` name conflicts and adjusted adapters to resolve the registry via `SceneTree` where needed.
- Fixed GDScript typing/inference issues in registry usage and overlap decision logic after headless parse checks.
