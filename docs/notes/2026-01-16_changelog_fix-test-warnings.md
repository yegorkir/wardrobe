# 2026-01-16 — Changelog: fix test warnings

## Summary
- Renamed conflicting test and runtime preloads, adjusted tests for strict typing, and cleaned minor script warnings surfaced during the suite.

## Details
- Updated test constants to use `*Script` suffixes where they preload scripts with global `class_name` values.
- Removed unused preloads in integration tests to avoid class-name shadow warnings.
- Swapped float literals for int where `ItemArchetypeDefinition` expects `int` in aura tests.
- Renamed runtime preloads (light systems, landing behaviors, exposure systems) to `*Script` and updated constructors.
- Cleaned warning sources in runtime scripts (unused `_light_zone`, shadowed `material`, unused curtain ratio parameter, floor selection naming).
- Fixed indentation in `ZombieExposureSystem.tick` after refactor.

## References
- GDScript class names (Godot 4.5): https://docs.godotengine.org/en/4.5/getting_started/scripting/gdscript/gdscript_basics.html#class-names
