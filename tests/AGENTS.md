````md
# <repo>/tests/AGENTS.md

## Scope
- These rules apply to anything related to automated tests and test infrastructure:
  - files under `tests/`
  - CI workflows that run tests
  - test-only utilities and fixtures
- If this file conflicts with root `<repo>/AGENTS.md`, follow the more specific rule (this one).

## Testing goals (Magical Wardrobe)
- Tests must reinforce **SimulationCore-first** boundaries:
  - Core logic stays **Node-free** and is tested as pure GDScript.
  - Adapters/Scenes are tested only where behavior depends on SceneTree wiring.
- Prefer tests that validate **determinism** and **explainability**:
  - outcomes are derived from **Domain Events / ShiftLog**, not UI counters.

## Testing stack (Godot 4.5 / GDScript)
- Default framework: **GdUnit4 v6.x** (compatible with Godot 4.5).
- Optional/legacy: **GUT 9.x** may exist, but do not introduce new coverage with it unless explicitly asked.
- Keep Godot version pinned in CI (4.5.x). Do not “float” to “latest stable”.
- Functional/Scene tests must use GdUnit4 suites + SceneRunner; do not write custom headless `SceneTree` scripts or bespoke runners.

## Test levels and where they live
Use a clear pyramid (fast → slow):

### `tests/unit/`
- Pure logic only:
  - Prefer `extends Object` / `extends RefCounted` / `extends Resource`.
  - **No SceneTree**: no `Node`, no `PackedScene.instantiate()`, no `get_tree()`, no autoload access.
- Target modules:
  - `scripts/domain/**` and `scripts/app/**` (or extracted logic from `scripts/sim/**` during migration).
- Assertion style:
  - Assert **Domain Events** and **state snapshots** from public APIs.

### `tests/integration/` (optional, create when needed)
- Node-to-node integration, autoload wiring, adapter ↔ core bridging.
- Minimal scenes, controlled dependencies, use doubles.
- Allowed: verifying that a `SimulationCoreNode` translates domain events to Godot signals correctly.

### `tests/functional/`
- Scene-level behavior and user-flow simulations.
- Must use **GdUnit4 Scene Runner**.
- Keep scenes tiny and purpose-built.

Suggested layout:
- `tests/scenes/` — tiny test scenes and fixtures
- `tests/helpers/` — test utilities (builders, fakes, data factories)
- `tests/assets/` — versioned data fixtures (JSON, configs, etc.)

## Conventions (GdUnit4)
- Each test suite is a GDScript file under `tests/**` that:
  - `extends GdUnitTestSuite`
  - contains test functions named `test_*`
- Keep tests deterministic:
  - no reliance on wall-clock timing
  - no random without a fixed seed (or use framework fuzzing intentionally and record failures)
- Prefer table-driven tests where it improves coverage/readability.

## Architectural test rules (SimulationCore-first)
- Unit tests must never depend on SceneTree:
  - **Forbidden in unit tests:** `Node`, `SceneTree`, `Input`, `RenderingServer`, `PhysicsServer`, `ProjectSettings`, `/root/*`.
- Validate boundary discipline:
  - Core returns/records **Domain Events** for any meaningful consequence (penalties, decay, wrong item, patience, etc.).
  - Shift summary must be computable from the ShiftLog stream in tests.

## Test design rules (data, observability, contracts)

### Content data (JSON/Definitions)
- Do not assert fixed values of production content (IDs, full JSON payloads, exact tuning).
  - Content changes are not regressions.
  - Prefer verifying:
    - file is loadable
    - schema/required fields exist
    - definitions are immutable at runtime
- If exact values must be asserted, use **versioned fixtures** under `tests/assets/` (not `res://content/`).

### Observability
- Do not rely on stdout/log text for assertions.
  - Assert structured outcomes:
    - signals + payload
    - return values
    - state snapshots
    - Domain Events / ShiftLog entries (structured)
- When asserting signals/events, validate payload fields (not only “fired”).

### API-first testing
- Prefer testing via public API.
  - If behavior must be tested, add an official method (e.g., `get_snapshot()`, `apply_command()`, `build_shift_summary()`).
  - Do not reach into internal arrays/dicts of aggregates.

### Isolation
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
  - pass collaborators into constructors / `_init` / `setup(...)`
  - or provide interfaces via base classes (Base Class Pattern)
- If you must touch an autoload:
  - access instance via `/root/<Name>` and cast to the **base type**
  - handle missing singleton gracefully (warnings + early exit)
- Never `preload()` / `load()` autoload implementation scripts globally in tests.

## GDScript correctness rules (test code too)
- Use `await` (Godot 4), never `yield`.
  - For delays (only if truly needed): `await get_tree().create_timer(1.0).timeout`
- Always explicitly type `@onready` variables:
  - Good: `@onready var label: Label = $Label`
  - Bad:  `@onready var label = $Label`
- Treat `JSON.parse_string()` results as `Variant` and cast immediately.
- Prefer `StringName` for event/command types and keys in typed dictionaries.

## Verification
- Always attempt to run the canonical suite (`just tests`) after code changes; only if it fails should you inspect environment variables like `GODOT_BIN`.
- Prefer a CLI parse check for any edited/added test GDScript (when Godot binary is available):
	`godot --path . --headless --check-only --script res://path/to/test_script.gd`
- If `godot` is not in PATH, do not claim checks were run.

## Running tests locally (preferred)
Use GdUnit4 command line tool (cross-platform) from repo root.

### 1) Ensure GODOT_BIN is set
- macOS/Linux:
  - `export GODOT_BIN=/path/to/Godot`
  - `chmod +x ./addons/gdUnit4/runtest.sh`
- Windows (PowerShell/CMD):
  - set an env var pointing to `Godot.exe` (system-wide is OK)

### 2) Run all tests
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
````

## Non-hallucination rule

* Never claim tests were executed unless you explicitly saw the output.
* If tests could not be run (missing Godot binary, no CI runner, etc.):

  * state what you checked statically
  * state the exact command(s) the user should run to verify.
