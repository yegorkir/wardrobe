# 2026-01-11 — Step3 win + queue mix

## Summary
- Reworked shift win tracking to use explicit check-in/check-out targets and counters in `RunState`.
- Added a queue mix policy that selects between check-in and check-out pools based on shift progress and outstanding checkouts.
- Wired desk events to register check-in vs check-out completion and pass shift mix snapshots into the queue selector.

## Notes
- Queue mix selection is deterministic and policy-driven; adapters only supply a snapshot via `Callable`.
- Shift win no longer depends on active clients; it depends solely on check-in/check-out targets.

## References
- Callable (Godot 4.5): https://docs.godotengine.org/en/4.5/classes/class_callable.html
