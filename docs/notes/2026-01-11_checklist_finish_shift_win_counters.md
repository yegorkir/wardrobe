# Checklist: Finish shift win counters (Iteration 4.1)

- [x] Update plan to map checkout completion to `EVENT_CLIENT_COMPLETED` and require `client_id` threading for dedup.
- [x] Update plan to note `content/waves` as the single source of target thresholds.
- [x] Update analysis with confirmed event mapping and `client_id` payload availability.
- [x] Update analysis to reflect the config boundary (`content/waves` -> app layer).
- [x] Record documentation updates in a dedicated changelog note.
- [x] Add domain-level dedup for checkin/checkout counters keyed by `client_id`.
- [x] Thread `client_id` through desk event bridge and workdesk handlers for counter updates.
- [x] Align client count creation with `content/waves` to keep targets config-driven.
- [x] Update unit tests for new counter APIs and add dedup coverage.
