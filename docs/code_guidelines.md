# Code Guidelines (Lessons Learned)

These notes capture recurring pitfalls from recent refactors; follow them whenever writing new code.

## GDScript typing and construction
- When duplicating RefCounted instances, call `get_script().new(...) as ClassName` instead of referencing the class name directly; this prevents class resolution errors during headless checks and keeps type inference intact.
- Avoid ternary expressions that mix nullable and non-nullable branches; prefer explicit `if/else` to keep the static analyzer happy and to avoid headless warnings.
- Preload collaborator classes used inside a script (e.g., domain state depending on `ItemInstance`) to guarantee availability during headless test runs.

## Testing discipline
- After modifying domain code, run the targeted GdUnit4 suites (e.g., `./addons/gdUnit4/runtest.sh -a ./tests/unit/...`) and fix parse warnings immediately; treat headless parser warnings as signals to clean up typing.
