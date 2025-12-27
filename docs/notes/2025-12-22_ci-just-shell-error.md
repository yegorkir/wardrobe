# CI analyze: just shell error on Build web (itch)

## Problem summary
GitHub Actions fails at `Build web (itch)` with:
`just could not find the shell: No such file or directory (os error 2)`.
The job sets `GODOT_BIN`, downloads Godot, and warms cache successfully, but `just web` fails before invoking Godot.

## Root cause
`justfile` explicitly sets `shell := ["zsh", "-c"]`. The ubuntu runner does not include `zsh` by default, so `just` fails before running any recipe, including `_require_godot_bin`.

## Constraints and context
- CI uses `ubuntu-latest`.
- Godot binary is installed at `/usr/local/bin/godot`.
- `just` is installed via `extractions/setup-just@v3`.
- The failure is not a Godot path issue; it happens earlier in `just`.

## Solution design (options + tradeoffs)
1) **Use bash in CI only (preferred minimal change)**
	- Set `JUST_SHELL` or `SHELL` in the workflow step to `bash -c`.
	- Pros: No repo-wide behavior change; smallest diff; no extra packages.
	- Cons: Must remember to set per CI job if new jobs call `just`.
2) **Make `justfile` default to bash unless zsh is available**
	- Example: remove `set shell` line or gate it via env (e.g., `set shell := env_var_or_default("JUST_SHELL", "bash -c")` using just vars).
	- Pros: Works locally and in CI without extra setup; single fix.
	- Cons: Behavior change for local devs who rely on zsh features (if any).
3) **Install zsh in CI**
	- Add `sudo apt-get update && sudo apt-get install -y zsh` before `just web`.
	- Pros: No changes to `justfile`.
	- Cons: Slower CI; adds dependency; unnecessary if recipes are bash-compatible.

## Architecture / system design impact
- **CI layer**: `tests.yml` orchestrates build steps; failure is in shell execution, not Godot.
- **Build tooling**: `justfile` is the recipe driver; its shell setting defines all CI command execution.
- **Runtime**: No impact on Godot/game runtime behavior.

## Module and class design (future-proofing)
No gameplay modules/classes involved. If we want to reduce CI brittleness:
- Introduce a small "CI bootstrap" recipe (`just ci-web`) that sets env-safe defaults (shell, paths) and calls `web`.
- Alternatively, add a `scripts/ci/` helper shell script that normalizes env and invokes `just`.

## Test/verification considerations
- Existing test runner uses `./addons/gdUnit4/runtest.sh` directly and succeeds before the build job.
- No new tests needed; CI change should be validated by rerunning the `build` job.
- If modifying `justfile`, verify locally with `just web` and in CI.

## Proposed plan (next implementation)
1) Decide on fix strategy (CI-only vs repo-wide). Target files:
	- CI-only: `.github/workflows/tests.yml`
	- Repo-wide: `justfile` (and optionally docs/README if behavior changes)
2) Implement chosen fix with minimal diff.
3) Re-run CI build job (or trigger workflow) to confirm `just web` succeeds.

## References
- https://just.systems/man/en/chapter_7.html (shell configuration in just)
