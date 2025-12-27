# 2025-12-24 — Step 5 clients/wave workdesk (implementation notes)

## Summary
- Added client placeholder UI + patience bar to the Workdesk desk prefab.
- Added a UI adapter to drive client visibility, colors, and patience ratio.
- Implemented local wave/patience ticking and served-client win/loss flow in WorkdeskScene without touching domain/app code.

## Decisions
- Kept patience/wave state local to `WorkdeskScene` to respect the Step 5 scope and avoid domain changes.
- Used a small bridge wrapper to count `EVENT_CLIENT_COMPLETED` without modifying the drag-and-drop adapter.

## References
- Control.mouse_filter (to avoid blocking DnD): https://docs.godotengine.org/en/4.5/classes/class_control.html#class-control-property-mouse-filter
