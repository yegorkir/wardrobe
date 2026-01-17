# Client flow missing items bugfix (2026-01-17)

## Context
Clients spawned by the AI director appear without their coat/ticket items; logs show only cabinet tickets in `client_flow_items` and `client_items_on_scene` never counting client items.

## Repro
- Launch the Workdesk scene and observe `client_flow_items` only list cabinet tickets while active clients are present.
- `workdesk_scene.gd:517` throws `Trying to assign value of type 'Nil' to a variable of type 'Dictionary'` during `_find_available_coats_in_storage()` when a checkout spawn request occurs.

## Root cause
- `_find_available_coats_in_storage()` treated `WardrobeStorageSnapshot` like a dictionary, so `snapshot.get("slots_by_id")` returned `null` and caused a typed Dictionary assignment error.
- Client items created by `ClientFactory` were only registered via `RunManager`. When a `RunManager` exists but does not know about those items, `find_item_instance` resolves to `RunManager.find_item`, so desk spawn events cannot resolve client coat/ticket items, leaving trays empty.
- Checkout clients reach the desk in `PHASE_DROP_OFF` with tickets, but `DeskServicePointSystem` only attempted to spawn coat items on drop-off. This left checkout clients with no item on the tray.

## Fix
- Read `WardrobeStorageSnapshot.slots_by_id` directly to avoid the `Nil` dictionary assignment.
- Register client items through `WardrobeWorldSetupAdapter.register_item_instance` so items are tracked in the local item registry even when `RunManager` is present.
- Use a `RunManager` -> `WardrobeWorldSetupAdapter` fallback for `find_item_instance` so desk spawn events can always resolve client items.
- Register missing tray slots on-demand before putting items into `WardrobeStorageState` to prevent desk tray spawns from failing when slot IDs were not pre-registered.
- Add an integration test that clears tray state, spawns a check-in client via the director request path, assigns them to a desk, and asserts a coat item spawns on the tray.
- Add debug logs in the client spawn and desk assignment path to trace missing item creation/registration in live sessions.
- Spawn tickets for checkout drop-offs when no coat is present so AI-spawned checkout clients place their ticket on the tray.
- Add a unit test to assert checkout drop-off spawns a ticket on the tray.
- Cycle check-in client items through coat/bottle/chest/hat ids and force flow-spawned clients to use check-in items to avoid ticket-only spawns.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- `"$GODOT_BIN" --path .`

## Docs
- Godot 4.5 `Callable`: https://docs.godotengine.org/en/4.5/classes/class_callable.html
- Godot 4.5 `Node._process()`: https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-process
