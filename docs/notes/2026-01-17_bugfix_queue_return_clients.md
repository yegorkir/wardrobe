# Bugfix: clients return after ticket dropoff

## Summary
Clients received a ticket and left the desk, but never re-entered the waiting pool for checkout. The requeue delay was added to a different `ClientQueueSystem` instance than the one being ticked, so delayed clients never surfaced.

## Root cause
`DeskServicePointSystem` owned its own `ClientQueueSystem`, while `WorkdeskScene` ticked the queue system held by `WardrobeWorldSetupAdapter`. Delayed checkout entries were enqueued into the desk system's internal queue system and never processed by the ticking system.

## Fix
Share the same `ClientQueueSystem` instance between `WardrobeWorldSetupAdapter` and `DeskServicePointSystem`, so requeue delays are tracked and released by the ticked system. Added a focused unit test to cover the shared queue system path.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`
