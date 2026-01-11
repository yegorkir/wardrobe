# Wrong item fall + patience penalty (MVP)

## Summary
- Implemented wrong-item rejection consequences in app layer: idempotent desk slot pop, optional patience penalty, and item drop events.
- Added deterministic floor resolution based on desk slot id with configurable floor ids.
- Wired UI adapters to render item drops without deciding outcomes.

## Data and contracts
- `content/archetypes/*.json` now carries `wrong_item_patience_penalty` per archetype.
- `ClientState` carries `archetype_id` and `wrong_item_patience_penalty` so app logic stays data-driven.
- `EVENT_ITEM_DROPPED` payload includes `item_instance_id`, `from`, `to`, `cause`, `client_id`.

## Determinism notes
- Floor selection uses a stable hash of `desk_slot_id` against sorted floor ids to avoid randomness.

## References
- String.to_utf8_buffer: https://docs.godotengine.org/en/4.5/classes/class_string.html#class-string-method-to-utf8-buffer
