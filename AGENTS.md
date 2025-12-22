# <godot_repo>/AGENTS.md

## Scope
- These instructions apply to this repository and override global instructions when they conflict.
- Always follow additional tips in `docs/code_guidelines.md` when writing or refactoring code.

## Project
- Engine: **Godot 4.5 (stable)**.
- Primary language: **GDScript 2.0**.
- Formatting: follow repo formatting (prefer `.editorconfig` if present); otherwise use **tabs** for GDScript.

## Environment
- Assume required environment variables (e.g., `GODOT_BIN`) are already set; only mention them if a command fails due to a missing variable so the user can address it.
- Всегда сначала пробуй выполнить нужную команду, используя текущие значения переменных окружения; выясняй отсутствие/невалидность переменных только после реальной ошибки. Это правило распространяется на **все** переменные окружения, не только `GODOT_BIN`.
- Always run tests yourself after changes. If running tests is impossible (for example, the command is missing or dependencies are unavailable), report the error explicitly and state what the user should run. If tests fail, determine whether the issue is in the code or in the tests, fix it, and then rerun the tests.

## Notes / docs
- For non-trivial tasks, keep a dedicated note under `docs/notes/YYYY-MM-DD_<slug>.md`.
- Include short official-doc links in the note for any non-obvious engine behavior or API detail.
- Update docs (including `gdscript_guidelines.md` if it exists) whenever behavior/contracts change.

## References (Godot 4.5)
When working with Godot/GDScript, use sources in this priority order:
1. Official Godot **4.5** docs (tutorials + API): https://docs.godotengine.org/en/4.5/
2. Official **Class Reference** pages under `/en/4.5/classes/` for exact method/property/signal signatures
3. `godotengine/godot-docs` repository (docs sources; useful for deeper context/history): https://github.com/godotengine/godot-docs
4. context7 (helper only). If it conflicts with official docs, **official docs win**.

Rules:
- Never use `/en/latest/` for API correctness (version drift).
- If you are not 100% sure about an API call, enum name, signal, or signature: verify in the official 4.5 Class Reference first.

---

# Architecture: Magical Wardrobe (SimulationCore-first)

## Goal
Build editor-friendly scenes/prefabs while keeping gameplay rules deterministic, testable, and explainable:
- **Scenes/Nodes = presentation + adapters**
- **SimulationCore = rules + runtime state + outcomes**

## Core principles
- **Single Source of Truth:** all shift/run rules and runtime state live in `SimulationCore` (and its state objects), never in UI/Node scripts.
- **Commands in / Events out:**
	- Adapters (Nodes/UI) build **commands** and send them to SimulationCore.
	- SimulationCore produces **domain events** (ShiftLog + gameplay consequences).
	- Exactly one adapter node may translate domain events into Godot **signals** for UI/VFX.
- **Domain events are not Godot signals.**
	- Domain events are plain data objects (no Node dependencies).
	- Only adapter code may convert domain events into signals/animations/sounds.
- **No SceneTree in core:** core code must not call `get_tree()`, `get_node()`, use `NodePath`, scan groups, touch physics/render/input, or depend on autoloads.
- **Explainability contract:** end-of-shift summary must be derivable from ShiftLog events, not from scattered counters.

## Project layer mapping (current repo)
Rules of dependencies (match current folder layout):

- `res://scripts/domain/**` *(create as needed)* — pure domain types + invariants:
	- allowed: `RefCounted`, `Resource`, `Variant`, typed containers, pure functions
	- forbidden: `Node`, `SceneTree`, `Input`, physics/render APIs, `FileAccess/DirAccess`, `/root/*` autoload access
- `res://scripts/app/**` *(create as needed)* — use cases / systems orchestrators:
	- shift/waves, placement, scoring, queue/client FSM, magic, inspection
	- depends on `domain`, never depends on scenes
- `res://scripts/sim/**` — **LEGACY CORE (migration-only)**:
	- contains existing gameplay systems today (e.g., `magic_system.gd`, `inspection_system.gd`)
	- allowed: bugfixes + refactors that MOVE logic into `domain/` + `app/`
	- forbidden: implementing new features here
	- rule: every change in `sim/` should reduce `sim/` or add a TODO pointing to the target file in `app/`/`domain/`
- `res://scripts/wardrobe/**` and `res://scripts/ui/**` — adapters:
	- read input, drive visuals, build commands, display state
	- may connect Godot signals to UI/VFX, but must not own rules/state
- `res://scripts/autoload/**` — infrastructure:
	- ContentDB / SaveManager / RunManager / Debug
	- no simulation rules inside autoloads (autoloads are thin services)

Rule of thumb:
- Change gameplay rules → `scripts/domain` or `scripts/app` (or migrate from `scripts/sim` into them)
- Change presentation/input/UI → `scripts/wardrobe` or `scripts/ui`

---

# Data vs Runtime state (critical)

## Source of truth
- **Design-time content source of truth:** `res://content/**/*.json`
- JSON is parsed **once** by `res://scripts/autoload/content_db.gd` (on load/start), producing immutable in-memory definitions.
- The simulation must not re-parse JSON per frame or per item creation.

## Definitions (immutable templates)
- Represent as Resources **only for definitions** (inspector-friendly, safe to share):
	- `ItemDefinition`, `ArchetypeDefinition`, `ModifierDefinition`, `WaveDefinition`, `ZoneDefinition`, `SpellDefinition`, `EffectDefinition`
- Definitions are **read-only at runtime**.

## Runtime state (mutable)
- Must be `RefCounted` state objects (never `Resource`, never `Node`):
	- `RunState`, `WardrobeStorageState`, `TicketLedgerState`, `ClientState`, `ItemInstance`, etc.
- Runtime objects may reference definition Resources, but must never mutate them.

---

# DDD-lite rules (aggregates & invariants)
- State is modified only via aggregate methods; invariants cannot be bypassed.
- Aggregates own their internal collections; external code must not write into internal `Array/Dictionary` fields directly.
- If a test needs a behavior, add a public method (API-first), not an internal-variable hack.

Core aggregates (examples):
- `RunState` (money/debt/magic/time/waves/entropy)
- `WardrobeStorageState` (hooks/slots/placements)
- `TicketLedgerState` (ticket ↔ items ↔ client)
- `ClientState` (FSM + patience)

---

# Commands (actions)

## Rule
All atomic player/magic actions are expressed as commands and executed in SimulationCore:
- pick / put / swap
- insurance link
- emergency locate
- anchor place/move (screwdriver time cost)

## Minimal command contract (MVP-friendly, still typed)
Preferred: small typed classes (Value Objects). If using dictionaries, keep them typed and constant-keyed.

- `type: StringName`
- `tick: int`
- `payload: Dictionary[StringName, Variant]`

Dictionary key safety:
- Do not use raw string keys in multiple places.
- Define payload keys as `const` `StringName` in the command class/file (or a shared keys file) and reuse them.

---

# Events and ShiftLog (the contract for fairness)

## Rule
Any meaningful consequence must be a domain event with payload (no “just happened” events):
- `PenaltyApplied{amount, reason_code, context}`
- `ItemDecayed{item_id, amount, cause}`
- `WrongItemGiven{client_id, expected_ticket_id, given_item_id}`
- `ClientWaitedTooLong{client_id, seconds}`

## ShiftLog
- **ShiftLog is the explanation truth.**
- ShiftSummary UI is built from ShiftLog, not from scattered counters.

---

# Rules / Archetypes / Effects (data-driven, no node-rules)
- Archetypes/effects are **data-driven** definitions (JSON-derived defs / Resources).
- Simulation systems operate on data:
	- `ItemDefinition + ItemInstance`, `ClientState`, storage state, zone state
- Node components are allowed only for **presentation** (VFX, highlights, UI helpers),
  never as rule sources.

Modifiers:
- Modifiers patch rules (strategy objects / RuleSet composition).
- Do not spread `if modifier_x` across unrelated systems.

---

# Scene composition (nested scenes / prefabs)
- Prefer **scene instancing (nested scenes)** for building wardrobe/hook/item prefabs.
- Prefabs must stay “dumb”:
	- store IDs (`hook_id`, `slot_id`, `ticket_id`) and forward interactions as commands
	- no scanning the SceneTree to “decide rules”
- Avoid deep scene inheritance chains; prefer composition via instancing.

---

# Autoloads (Singleton Architecture)
- Autoloads are allowed for:
	- content loading, saves/config, debugging, audio, scene/screen routing (if needed)
- Autoloads must not contain simulation rules.

Base Class Pattern (canonical paths in this repo):
1. Base API + shared logic:
	- `res://scripts/autoload/bases/save_manager_base.gd` with `class_name SaveManagerBase` and `extends Node` (or chosen base type).
2. Autoload implementation:
	- `res://scripts/autoload/save_manager.gd` that `extends SaveManagerBase` (**do NOT** use `class_name` here).
3. Register implementation in Project Settings → Autoload as **SaveManager**.

Usage (safe):
- `var manager := get_node_or_null("/root/SaveManager") as SaveManagerBase`
- If `manager == null`, `push_warning(...)` and handle gracefully.

Rules:
- **Never** `preload()` / `load()` the autoload implementation script globally.
- Avoid top-level (file-scope) dependencies on other autoloads in both base and implementation; resolve them in `_ready()` or lazily.

---

# Anti-patterns (hard forbidden)
- “Slot/Hook emits domain signals to run the simulation” — forbidden.
- “PlacementSystem scans SceneTree / groups to apply rules” — forbidden.
- “UI reads truth from Label.text or Node properties as the source of state” — forbidden.
- “Simulation code reaches into `/root/*` autoloads” — forbidden.
- “New features implemented in `res://scripts/sim/**`” — forbidden.
- "Do not edit any files in `res://addons/*`" without permission

---

# GDScript guidelines

## Typing & Variant
- Static typing required for:
	- public APIs, state objects, command/event payload parsing, and `@onready` vars
		- Good: `@onready var label: Label = $Label`
		- Bad:  `@onready var label = $Label`
- Treat `JSON.parse_string()` results as `Variant`.
- Cast values returned from `Dictionary.get()`/Variant sources immediately to the expected type.
- Always return copies of dictionaries/arrays from “snapshot” APIs.

## Input & signals
- Use Godot 4 constants (`KEY_*`, `MouseButton.MOUSE_BUTTON_LEFT`).
- Connect signals only after ensuring the target exists.
- Prefer clear ownership: call down, signal up (presentation layer).

## Async
- Use `await` instead of `yield` (Godot 4).
- For delays use: `await get_tree().create_timer(1.0).timeout`
- Avoid wall-clock time in gameplay logic (`Time.get_ticks_msec()`) unless explicitly required and documented.

## Expressions
- Use `a if condition else b` (no C-style ternary).

## Scene/UI flow (repo conventions)
- Project boots via `scenes/Main.tscn`.
- `scripts/ui/main.gd` is the sole screen dispatcher.
- Call `apply_payload` only if present.
- Disconnect HUD signals in `_exit_tree`.
- Screens live under `scenes/screens/`.
- Prefabs live under `scenes/prefabs/`.

## Style
- Tabs throughout.
- Minimal comments (only for non-trivial blocks).

## Diagnostics
- Fix Godot/godot-tools warnings promptly.
- Prefer `push_warning(...)` when optional nodes might be absent.

---

# Verification
- Prefer a CLI parse check for any edited/added GDScript (when the Godot binary is available):
	`godot --path . --headless --check-only --script res://path/to/script.gd`
- If the `godot` command is not in the system PATH (common on Windows/macOS), do not claim you ran checks:
	- Assume the code is structurally correct, but be extra vigilant about GDScript syntax and exact API signatures.
	- Do not hallucinate test results.
- Note: `--check-only` may be fragile around autoload/plugin singletons; if it fails, verify by opening the project in Godot 4.5 and running the relevant scene.
