# CI note: web export templates not found

## Problem
CI `task web` fails with missing web export templates:
- `web_nothreads_debug.zip`
- `web_nothreads_release.zip`
Godot looks in `~/.local/share/godot/export_templates/4.5.stable` but the unzip step can place files under a nested `templates/` directory, leaving the expected files absent.

## Fix
Make template extraction robust to both archive layouts by unzipping to a temp dir and copying either `templates/*` or the root contents into the versioned template folder.

## Verification
- CI build job: `Build web (itch)` completes without missing-template errors.

## References
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html
