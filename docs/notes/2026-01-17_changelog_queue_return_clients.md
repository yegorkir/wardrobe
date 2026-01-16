# Changelog: queue return after ticket dropoff

- Identified mismatch between desk-level queue system and world-level queue system; delayed checkout clients never reached the ticked queue.
- Added `DeskServicePointSystem.set_queue_system(...)` to allow sharing the queue system instance used by the scene tick.
- Wired `WardrobeWorldSetupAdapter` to pass its queue system into `DeskServicePointSystem` during configuration.
- Added unit coverage ensuring a dropoff requeues checkout clients when the shared queue system is ticked.
