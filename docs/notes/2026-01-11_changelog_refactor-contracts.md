# Changelog: P0 Refactor Pass — DTO Contracts

- Introduced DTOs for Magic, Inspection, Storage, Interaction, and Shift service contracts.
- Replaced Dictionary-based public APIs in domain and shift services with typed DTOs.
- Updated UI adapters and tests to consume DTOs (Shift HUD/summary, interaction events, shift log).
- Adjusted shift log entries and win/fail payloads to typed objects.
