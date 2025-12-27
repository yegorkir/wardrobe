# Local note: web export crash during headless build

## Problem
`task web` crashes locally during Godot headless export with `libc++abi: Pure virtual function called!` after packing resources. The export log shows it is packing prior build outputs under `res://builds/**` and `res://reports/**`, which can cause export recursion and unstable behavior.

## Fix
Exclude build outputs and reports from all export presets:
- add `res://builds/*` and `res://reports/*` to `exclude_filter` in `export_presets.cfg`.

## Verification
- Run locally: `task web` and confirm it completes.
- Ensure the output folder exists at `builds/current/web_itch` and zip at `builds/current/web_itch.zip`.

## References
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html
