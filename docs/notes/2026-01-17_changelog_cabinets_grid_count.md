# 2026-01-17 — Changelog: reduce CabinetsGrid cabinet count

## Summary
- Removed four cabinet instances from `scenes/prefabs/CabinetsGrid.tscn` to reduce storage capacity.

## Details
- Deleted cabinet nodes:
  - `Cabinet_001` (`cabinet_id = Cab_001`)
  - `Cabinet_002` (`cabinet_id = Cab_002`)
  - `Cabinet_003` (`cabinet_id = Cab_003`)
  - `Cabinet_004` (`cabinet_id = Cab_004`)
- Remaining cabinets are unchanged: `Cabinet_100`, `Cabinet_010`, `Cabinet_200`, `Cabinet_020`.
