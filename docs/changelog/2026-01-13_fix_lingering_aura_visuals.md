# Changelog: Fix Lingering Aura Visuals on Corrupted Items

## 2026-01-13
- Fixed a visual bug where aura transfer effects (particles) would persist even after the target item was fully corrupted.
- Updated `ExposureService.tick` to skip exposure calculations and explicitly clear `pending_transfers` for items with zero or negative quality. This ensures that the UI stops rendering transfer effects immediately upon item "death".
