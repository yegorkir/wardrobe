# <repo>/tests/AGENTS.md

## Scope
- These rules apply to anything related to automated tests and test infrastructure:
  - files under `tests/`
  - CI workflows that run tests
  - test-only utilities and fixtures
- If this file conflicts with root `<repo>/AGENTS.md`, follow the more specific rule (this one).

## Testing stack (Godot 4.5 / GDScript)
- Default framework: **GdUnit4 v6.x** (compatible with Godot 4.5).
- Optional/legacy: **GUT 9.x** may exist, but do not introduce new coverage with it unless explicitly asked.
- Keep Godot version pinned in CI (4.5.x). Do not “float” to “latest stable”.
- Functional/Scene tests must use GdUnit4 suites + SceneRunner; do not write custom headless `SceneTree` scripts or bespoke runners.

## Test levels and where they live
Use a clear pyramid (fast → slow):
- `tests/unit/`:
  - Pure logic only (prefer `extends Object` / `extends Resource`)
  - No SceneTree, no real input, no rendering assumptions
- `tests/integration/`:
  - Node-to-node integration, autoload wiring, signals between nodes
  - Minimal scenes, controlled dependencies, use doubles
- `tests/functional/`:
  - Scene-level behavior, user-flow simulations, input simulation
  - Prefer small dedicated test scenes under `tests/scenes/`

Suggested layout:
- `tests/scenes/` — tiny test scenes and fixtures
- `tests/helpers/` — test utilities (builders, fakes, data factories)
- `tests/assets/` — data files used by tests (JSON, configs, etc.)

## Conventions (GdUnit4)
- Each test suite is a GDScript file under `tests/**` that:
  - `extends GdUnitTestSuite`
  - contains test functions named `test_*`
- Keep tests deterministic:
  - no reliance on wall-clock timing
  - no random without a fixed seed (or use framework fuzzing intentionally and record failures)

## Test design rules (data, observability, contracts)
- Do not assert fixed values of external/content data (IDs, full JSON payloads, etc.).
  - Content changes are not regressions. Tests should verify validity, structure, schema/contracts, and that data is loadable (e.g., via ContentDB), not exact content.
  - If exact values must be asserted, use versioned test fixtures under `tests/assets/` (not production content).

- Do not rely on stdout/log text for assertions.
  - Assert structured outcomes: signals + payload, return values, state snapshots, or a structured log API (e.g., `get_log_entries()`), not string matching on logs.

- Prefer testing via public API.
  - If behavior must be tested, add an official method (e.g., `reload_meta_from_disk()`) instead of reaching into internal vars.
  - Tests use the same public mechanisms as production code.

- When asserting signals/events, validate payload.
  - Not only “signal fired”, but also that payload fields are correct (path/hash/unlocks/etc.) to avoid false greens.

- Do not leak state between tests.
  - After filesystem/save/config manipulations, restore defaults (e.g., `clear_save()`).
  - Each test must be runnable independently and in any order.


## Scene tests and input
- For any test that needs SceneTree / input simulation:
  - use **GdUnit4 Scene Runner** instead of calling `_input()` manually or faking engine internals
  - prefer waiting on signals / runner sync points rather than sleeping
- Avoid long real delays:
  - do not use “wait 2 seconds” patterns in CI
  - if timing is required, keep delays minimal and prefer frame simulation / signal-based waiting

## Autoloads in tests
- Do not rely on real autoload implementations in unit tests.
- Prefer dependency injection:
  - pass collaborators into constructors / init methods
  - or provide interfaces via base classes (Base Class Pattern)
- If you must touch an autoload:
  - access instance via `/root/<Name>` and cast to the **base type**
  - handle missing singleton gracefully (warnings + early exit)

## GDScript correctness rules (test code too)
- Use `await` (Godot 4), never `yield`.
  - For delays (only if truly needed): `await get_tree().create_timer(1.0).timeout`
- Always explicitly type `@onready` variables (autocomplete matters in tests too):
  - Good: `@onready var label: Label = $Label`
  - Bad:  `@onready var label = $Label`

## Running tests locally (preferred)
Use GdUnit4 command line tool (cross-platform) from repo root:

### 1) Ensure GODOT_BIN is set
- macOS/Linux:
  - `export GODOT_BIN=/path/to/Godot`
  - `chmod +x ./addons/gdUnit4/runtest.sh`
- Windows (PowerShell/CMD):
  - set an env var pointing to `Godot.exe` (system-wide is OK)

### 2) Run a suite directory
- macOS/Linux:
  - `./addons/gdUnit4/runtest.sh -a ./tests`
- Windows:
  - `./addons/gdUnit4/runtest -a ./tests`

Notes:
- By default reports go to `res://reports/`. Use:
  - `-rd <dir>` to change report directory
  - `-rc <n>` to keep more/less report history
- Return codes are meaningful (0 success; non-zero indicates failures/warnings).

## CI (GitHub Actions)
- Prefer `MikeSchulze/gdunit4-action` and pin:
  - `godot-version: '4.5.x'`
  - `version: '<gdunit4 version>'` (or a pinned tag)

Minimal example (adjust versions/paths):
```yaml
name: Tests
on: [push, pull_request]
jobs:
  gdunit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: MikeSchulze/gdunit4-action@v1
        with:
          godot-version: '4.5.1'
          version: '6.0.3'
          paths: 'res://tests'
```

## Non-hallucination rule

* Never claim tests were executed unless you explicitly saw the output.
* If tests could not be run (missing Godot binary, no CI runner, etc.):

  * state what you checked statically
  * state the exact command(s) the user should run to verify.
