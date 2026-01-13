# Changelog: Restrict Zombie Corruption to Client Items

## 2026-01-13
- Fixed a logic issue where system items (Tickets, Anchor Tickets) were being corrupted by zombie aura.
- Added `can_be_corrupted()` method to `ItemInstance` to explicitly define susceptibility.
- Updated `ExposureService` to ignore immune items during corruption calculations. Tickets will no longer rot or emit transfer particles.
