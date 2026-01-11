# Iteration 4.1 cleanup: targets vs clients, wave timer removal

## Summary

This pass removes legacy wave-timer fail logic from the Workdesk flow and ensures shift targets are configured explicitly (N_checkin/N_checkout) rather than inferred from client counts. Wave roster data now stays separate from client count to avoid accidental shortening when the roster is just a list of archetypes.

## Key changes

- Shift targets are set from wave config (`target_checkin`/`target_checkout`) and no longer overridden by `configure_shift_clients`.
- Wave timer and fail path were removed from `scripts/ui/workdesk_scene.gd`.
- Wave roster (`clients`) is now distinct from `client_count`; roster remains for archetype selection only.

## Follow-ups

- Decide whether targets should remain in wave config or move to a separate shift config once wave timing is fully retired.
- Consider hiding/removing wave/time HUD labels if they become misleading in the new flow.
