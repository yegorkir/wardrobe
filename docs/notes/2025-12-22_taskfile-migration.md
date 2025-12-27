# Taskfile migration (from just)

## Goal
Replace `just` with `Taskfile` for cross-platform task running and to avoid shell availability issues in CI.

## Changes
- Added `Taskfile.yml` with tasks equivalent to previous `justfile` recipes.
- Updated CI to install and run `task` instead of `just`.
- Removed `justfile`.

## Task mapping
- `just web` -> `task web`
- `just web-local` -> `task web-local`
- `just mac-debug` -> `task mac-debug`
- `just tests` -> `task tests`
- `just save` -> `task save`

## Design notes
- Uses `GODOT_BIN` env var to keep behavior identical.
- `tests` task retains the same GdUnit4 invocation.
- No gameplay or runtime code changes.

## Verification
- CI should now run `task tests` and `task web`.
- Local check (if desired):
  - `export GODOT_BIN=/path/to/Godot`
  - `task web`
  - `task tests`

## References
- https://taskfile.dev/
