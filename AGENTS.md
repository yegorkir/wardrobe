# AGENTS.md
# <godot_repo>/AGENTS.md

## Scope
- These instructions apply to this repository and override global instructions when they conflict.
- Always follow additional tips in `docs/code_guidelines.md` when writing or refactoring code.

## Project
- Engine: **Godot 4.5 (stable)**.
- Primary language: **GDScript 2.0**.
- Formatting: follow repo formatting (prefer `.editorconfig` if present); otherwise use **tabs** for GDScript.

## Environment
- Assume required environment variables (e.g., `GODOT_BIN`) are already set; only mention them if a command fails due to a missing/invalid variable so the user can address it.
- Always try running the command first with the current environment. Investigate missing/invalid env vars **only after** you see a real error.
- This rule applies to **all** environment variables, not just `GODOT_BIN`.

## Tests (canonical, no alternatives)
- **Always run tests yourself after any change** (including refactors).
- **Run tests via Taskfile only**:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- **After tests, launch Godot once to validate runtime startup**:
  - `"$GODOT_BIN" --path .`
- Do not suggest or document any other test runner command in this repo.
- If tests cannot be run (e.g., `task` missing, Taskfile target missing, Godot not available), explicitly report:
  1) the exact error output,
  2) what is required to make `task tests` runnable,
  3) and the exact canonical command above (unchanged).

## Notes / docs
- For non-trivial tasks, keep a dedicated note under `docs/notes/YYYY-MM-DD_<slug>.md`.
- All auxiliary notes (analysis, summary, changelog, checklist, etc.) must be created as `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.
- Include short official-doc links in notes for any non-obvious engine behavior or API detail.
- Update docs (including `gdscript_guidelines.md` if it exists) whenever behavior/contracts change.

## References (Godot 4.5)
When working with Godot/GDScript, use sources in this priority order:
1. Official Godot **4.5** docs (tutorials + API): https://docs.godotengine.org/en/4.5/
2. Official **Class Reference** pages under `/en/4.5/classes/` for exact method/property/signal signatures
3. `godotengine/godot-docs` repository (docs sources): https://github.com/godotengine/godot-docs

Rules:
- Never use `/en/latest/` for API correctness (version drift).
- If you are not 100% sure about an API call, enum name, signal, or signature: verify in the official 4.5 Class Reference first.

## MCP playbook (repo policy, mandatory)

### Servers in this repo
- `godot_tools` (Solomon): launch/run/stop + safe scene ops.
- `gdscript_diag`: GDScript diagnostics via Godot LSP.
- `godot_docs`: Godot docs/class reference lookup (4.5).

### Global safety rules
- Never write/edit `.tscn` by hand. Scene structure changes must go through `godot_tools` (`create_scene`, `add_node`, `save_scene`).
- Keep all operations scoped to this repo root. Do not read/write paths outside the repo.
- Prefer incremental checks: fix issues as soon as they appear (don’t stack 20 changes before checking).

### Scene editing rules (mandatory)
When you need to change scene structure (nodes, hierarchy, add/remove node, set script on node, etc.):
1) Use `godot_tools.create_scene` only when creating a new scene.
2) Use `godot_tools.add_node` for structural edits.
3) Immediately `godot_tools.save_scene` after each logical change set.
4) If a change touches UIDs or breaks references, run `godot_tools.update_project_uids` ONLY if necessary:
   - It can modify many files; do it only when there is evidence of UID mismatch/broken refs.
   - After running it, explicitly list which files changed.

### Script editing rules (.gd)
- Editing `.gd` directly is allowed.
- After any `.gd` edits, run `gdscript_diag.get_diagnostics` and fix all errors/warnings introduced by the change.
- Use `gdscript_diag.scan_workspace_diagnostics` only when the change is broad (refactor, moved files, renamed classes). Treat it as expensive.

### Docs usage rules (API correctness)
If you are not 100% sure about an API name/signature/signal/enum:
1) `godot_docs_search`
2) `godot_docs_get_class` (preferred) or `godot_docs_get_page`
Then implement using the verified signature (Godot 4.5; never assume “latest”).

### Debug / runtime loop
- For runtime debugging: `godot_tools.run_project` → `godot_tools.get_debug_output`.
- If the run hangs or produces no new output: immediately `godot_tools.stop_project`, then inspect repo logs (see GEMINI.md tips).
- Do not wait indefinitely for a run to finish.

### Required verification (still canonical)
- Always run tests via Taskfile only:
  - `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- After tests, launch Godot once:
  - `"$GODOT_BIN" --path .`
- Do not replace these commands with MCP alternatives.


---

# Architecture (SimulationCore-first, but prototype-friendly)

## Goal
Build editor-friendly scenes/prefabs while keeping gameplay rules deterministic, testable, and explainable:
- **Scenes/Nodes = presentation + adapters**
- **Core = rules + runtime state + outcomes**

This is about **keeping code maintainable while the design changes**, not freezing the design.

## Layering (repo mapping)
Dependency rules (match current folder layout):

- `res://scripts/domain/**` — domain types + invariants (pure runtime state, policies):
  - allowed: `RefCounted`, pure functions, typed containers, `Variant` parsing at boundaries
  - forbidden: `Node`, `SceneTree`, `Input`, physics/render APIs, autoload access, file I/O

- `res://scripts/app/**` — use cases / orchestrators (shift flow, interactions, client flow):
  - depends on `domain`
  - must not depend on scenes/prefabs

- `res://scripts/wardrobe/**` and `res://scripts/ui/**` — adapters:
  - read input, drive visuals, build commands, display state
  - may convert domain events into Godot signals/animations/sounds
  - must not own gameplay truth

- `res://scripts/autoload/**` — infrastructure:
  - content loading, saving/config, debugging, routing
  - no gameplay rules inside autoloads

Rule of thumb:
- Change gameplay truth → `domain/` or `app/`
- Change visuals/input/UI → `wardrobe/` or `ui/`
- Any new feature must not be implemented in `sim/`

## Single Source of Truth (SSOT)
- Runtime gameplay truth lives in domain/app state objects.
- Nodes are views/adapters; they may cache visuals, but must not become “the truth”.

## Commands in / Outcomes out (pragmatic)
- Player actions that mutate gameplay state must go through an app-layer API (command or typed method call).
- Core produces outcomes (domain events + updated state snapshots) that UI renders.
- UI-only actions (open menu, highlight button, camera shake) may stay local and do not require commands/events.

## Events and explainability (ShiftLog contract)
- Any meaningful consequence (penalty, decay, rejection, client outcome) must be recordable as a domain event.
- ShiftSummary must be derivable from ShiftLog + state snapshots (not from label texts or scattered counters).

## Runtime state rules (DDD-lite)
- Mutable runtime state must be `RefCounted` (not `Resource`, not `Node`).
- Aggregates own their collections; external code must not mutate internal arrays/dicts directly.
- Snapshot APIs must return copies.

### RefCounted cyclic references
- Avoid strong reference cycles between RefCounted objects.
- If a bidirectional link is needed, use `WeakRef` for the back-reference or provide explicit `detach()/dispose()` cleanup at the end of a run/shift.

## Time model (no Node timers in core)
- Core time advances via an explicit `tick(delta: float)` called by an adapter.
- Do not rely on `Timer`/`Tween` for core rules. Presentation may use them for visuals.

## Data boundaries (content vs runtime)
- Source of content truth: `res://content/**/*.json` (or definitions generated from it).
- Content is parsed once by ContentDB into immutable definitions.
- Runtime state references definitions but never mutates them.

## Commands payload typing
- Prefer typed command/value objects for frequently used actions.
- If a dictionary payload is used, keys must be `const StringName` and validated at the boundary (fail fast with explicit errors).

---

# GDScript guidelines
## Typing & Variant
- Static typing required for:
  - public APIs, state objects, command/event parsing, `@onready` vars
- Treat `JSON.parse_string()` results as `Variant`.
- Cast values from `Dictionary.get()` immediately to expected types.
- Snapshot APIs return copies of arrays/dictionaries.

## Input & signals
- Use Godot 4 constants (`KEY_*`, `MouseButton.MOUSE_BUTTON_LEFT`).
- Prefer “call down, signal up” in adapters.

## Async
- Use `await` (Godot 4).
- Avoid wall-clock time (`Time.get_ticks_msec()`) in core logic unless explicitly documented.

## Scene/UI flow (repo conventions)
- Project boots via `scenes/Main.tscn`.
- `scripts/ui/main.gd` is the sole screen dispatcher.
- Screens live under `scenes/screens/`.
- Prefabs live under `scenes/prefabs/`.

## Diagnostics
- Fix warnings promptly.
- Prefer `push_warning(...)` when optional nodes might be absent.

## Verification (optional)
- You may use a parse check for edited scripts when available:
  - `godot --path . --headless --check-only --script res://path/to/script.gd`
- If `--check-only` is unreliable (autoload/plugin quirks), verify by opening the project in Godot 4.5 and running the relevant scene.

## One rule to prevent “repo rot”
- If you introduce a shortcut for speed, you must:
  - mark it clearly as `TODO(MIGRATE): ...` and
  - keep it isolated in adapters (never in domain/app), so it doesn’t poison the core.
