# CI note: web build artifact paths

## Problem
CI build job uploads `builds/current/web_itch.zip` and a Pages artifact at `builds/current/web-itch`, but the web task only exported the folder `builds/current/web_itch` and did not create a zip. This causes upload steps to fail.

## Fix
- Update `Taskfile.yml` to zip the exported web folder into `builds/current/web_itch.zip`.
- Update the Pages artifact path to `builds/current/web_itch` to match the export folder.

## Verification
- Run locally: `task web` (requires `GODOT_BIN`), confirm `builds/current/web_itch.zip` exists.
- In CI, ensure the `Upload web build` and `Upload Pages artifact` steps succeed.

## References
- https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html
