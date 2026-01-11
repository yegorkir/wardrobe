# Swap and click logging expansion

## Summary
- Added detailed swap logs (incoming/outgoing, slot, hand/slot before and after) and explicit "PUT missing" reasons in interaction adapters.
- Added click snapshots that capture cursor position, hover target, hand item, and per-item state/position.

## Rationale
- Investigate cases where swap appears to "detach" items or skips a visible PUT, and retain full interaction context for debugging.

## References
- ProjectSettings (file logging options): https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html
- Data paths and `user://`: https://docs.godotengine.org/en/4.5/tutorials/io/data_paths.html

## Follow-up
- Centralized slot anchoring cleanup so items always exit drag state when placed into a slot.
