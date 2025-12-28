# 2025-12-28 — FloorZone drop when item is below all zones

## Issue
When multiple FloorZone instances exist, drops are routed to the nearest zone that is visually below the item (positive Y delta, smallest delta). If an item is released below all FloorZones (no zone with positive delta), there is currently no valid target.

## Current behavior
The drop is ignored and a warning is logged. This is considered a level-design error for now.

## Future direction
Add a fallback strategy (e.g., clamp to lowest FloorZone, or create a temporary floor catch zone) once level validation rules are defined.
