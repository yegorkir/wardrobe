# Event schema unification (P1.2)

## Summary
- Unified interaction and desk event schema constants into `scripts/domain/events/event_schema.gd`.
- Updated interaction/desk systems and UI adapters to reference the shared schema module.
- Removed the deprecated `scripts/domain/interaction/interaction_event_schema.gd`.

## Rationale
- Keeps event key/payload naming consistent across domain systems and UI adapters.
- Reduces duplicated schema constants in `DeskServicePointSystem`.
- Simplifies future additions of event types and payload keys.

## Notes
- No behavior changes expected; event payloads and event names are unchanged.

## References
- Godot 4.5 GDScript basics (constants): https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_basics.html#constants
