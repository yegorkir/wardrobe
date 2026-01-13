# docs/code_guidelines.md
# Code Guidelines (Lessons Learned)

These notes capture recurring pitfalls from recent refactors; follow them whenever writing new code.

## GDScript typing and construction
- When duplicating RefCounted instances, call `get_script().new(...) as ClassName` instead of referencing the class name directly; this prevents class resolution errors during headless checks and keeps type inference intact.
- Avoid ternary expressions that mix nullable and non-nullable branches; prefer explicit `if/else` to keep the static analyzer happy and to avoid headless warnings.
- Preload collaborator classes used inside a script (e.g., domain state depending on `ItemInstance`) to guarantee availability during headless test runs.

## Testing discipline
- In this repo, tests must be run via the canonical Taskfile command from `AGENTS.md` only:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- Do not suggest or document alternative test runner commands (including direct GdUnit4 scripts),
  to avoid repo-wide drift and agent confusion.
- Treat headless parser warnings as signals to clean up typing.
