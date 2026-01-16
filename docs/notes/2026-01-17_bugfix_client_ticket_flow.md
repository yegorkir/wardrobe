# 2026-01-17 bugfix_client_ticket_flow

## Context
Bug investigation for Workdesk client flow: clients vanish when picking up tray items and pickup-stage tickets are missing.

## Observed Symptoms
- Picking up a client tray item immediately clears the client from the desk, even if no ticket was delivered.
- During pickup stage, clients do not present their ticket item.

## Root Cause
- `WardrobeDragDropAdapter._try_assign_after_tray_pick()` assigns the next client whenever a tray slot becomes empty, even if the current client is still present at the desk.
- `DeskServicePointSystem._assign_next_client_to_desk()` only spawns coat items for drop-off clients; pickup clients never spawn their ticket onto tray slots.

## Fix Summary
- Guard tray-based auto-assign so it only runs when the desk has no active client.
- Spawn the stored ticket item onto the desk tray when a pickup-phase client is assigned.

## Docs
- StringName (used for empty-id checks in guards): https://docs.godotengine.org/en/4.5/classes/class_stringname.html
