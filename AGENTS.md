# <godot_repo>/AGENTS.md

## Scope
- These instructions apply to this repository and override global instructions when they conflict.

## Project
- Engine: **Godot 4.5 (stable)**.
- Primary language: **GDScript**.
- Formatting: follow repo formatting (prefer `.editorconfig` if present); otherwise use **tabs** for GDScript.

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

## Verification
- Prefer a CLI parse check for any edited/added GDScript (when the Godot binary is available):
	`godot --path . --headless --check-only --script res://path/to/script.gd`
- If the `godot` command is not in the system PATH (common on Windows/macOS), do not claim you ran checks:
	- Assume the code is structurally correct, but be extra vigilant about GDScript syntax and exact API signatures.
	- Do not hallucinate test results.
- Note: `--check-only` may be fragile around autoload/plugin singletons; if it fails, verify by opening the project in Godot 4.5 and running the relevant scene.

## GDScript guidelines

- **Autoloads (Singleton Architecture)**:
	- Use the **Base Class Pattern** to reduce init-order/cyclic-dependency risks while keeping strict typing.
	- Structure:
		1. Base API + shared logic:
			`res://autoloads/bases/save_manager_base.gd` with `class_name SaveManagerBase` and `extends Node` (or chosen base type).
		2. Autoload implementation:
			`res://autoloads/save_manager.gd` that `extends SaveManagerBase` (**do NOT** use `class_name` here).
		3. Register `save_manager.gd` in Project Settings → Autoload as **SaveManager**.
	- Usage (safe):
		`var manager := get_node_or_null("/root/SaveManager") as SaveManagerBase`
		- If `manager == null`, `push_warning(...)` and handle gracefully.
	- **Never** `preload()` / `load()` the autoload implementation script (`res://autoloads/save_manager.gd`) globally.
		- Refer only to the base type (`SaveManagerBase`) and access the instance via `/root/SaveManager`.
	- Avoid top-level (file-scope) dependencies on other autoloads in both base and implementation; resolve them in `_ready()` or lazily.

- **Input & signals**:
	- Use Godot 4 constants (`KEY_*`, `MouseButton.MOUSE_BUTTON_LEFT`).
	- Connect signals only after ensuring the target exists.

- **Types & Variant**:
	- Treat `JSON.parse_string()` results as `Variant`.
	- Cast values returned from `Dictionary.get()`/Variant sources immediately to the expected type.
	- Keep node references typed where it helps.
	- Always return copies of dictionaries/arrays from “snapshot” APIs.
	- Always explicitly type `@onready` variables (preserves IDE autocomplete):
		- Good: `@onready var label: Label = $Label`
		- Bad:  `@onready var label = $Label`

- **Async**:
	- Use `await` instead of `yield` (Godot 4).
	- For delays use: `await get_tree().create_timer(1.0).timeout`

- **Expressions**:
	- Use `a if condition else b` (no C-style ternary).

- **Scene/UI flow**:
	- `Main.gd` is the sole screen dispatcher.
	- Call `apply_payload` only if present.
	- Disconnect HUD signals in `_exit_tree`.

- **Style**:
	- Tabs throughout.
	- Minimal comments (only for non-trivial blocks).

- **Safety & saves**:
	- RunManager must verify SaveManager before use.
	- SaveManager logs when save files are missing.

- **Structure**:
	- Project boots via `Main.tscn`.
	- Screens live under `scenes/screens/`.

- **Diagnostics**:
	- Fix Godot/godot-tools warnings promptly.
	- Prefer `push_warning(...)` when optional nodes might be absent.
