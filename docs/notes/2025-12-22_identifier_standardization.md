# Identifier standardization (P2.1)

## Summary
- Standardized slot lookup keys to `StringName` in `scripts/ui/wardrobe_scene.gd`.
- Removed unnecessary `str(...)` conversions when resolving slots from event payloads.
- Adjusted `_record_interaction_event` to accept `StringName` ids.

## Rationale
- Keeps identifier handling consistent across UI logic.
- Reduces avoidable string conversions when working with slot IDs.

## References
- Godot 4.5 `StringName`: https://docs.godotengine.org/en/4.5/classes/class_stringname.html
