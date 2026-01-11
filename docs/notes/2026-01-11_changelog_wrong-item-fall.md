# Changelog: Wrong item fall

- Added wrong-item rejection policy and outcome processing to emit `EVENT_ITEM_DROPPED` and apply patience penalties via app-layer callable.
- Extended event schema with wrong-item reason, item dropped event, penalty event, and additional reject payload fields.
- Added deterministic `FloorResolver` for desk-slot-based floor selection, with scene configuration from SurfaceRegistry floors.
- Updated UI interaction events adapter to detach items, clear surfaces, and drop to resolved floor with reject landing cause.
- Expanded client state with archetype id and wrong-item penalty, wired demo client setup to ContentDB wave archetypes.
- Added archetype data fields for wrong-item patience penalties in content JSON.
- Added unit coverage for reject policy, reject outcome idempotency, and penalty strike transitions; updated desk rejection test expectations.
- Extended wrong-item consequences to apply on drop-off rejects (drop + patience penalty).
- Emit desk reject event on drop-off when a non-ticket item is placed, enabling floor drop + penalty.
- Verified tests via Taskfile and attempted Godot startup validation (startup output observed before timeout).
