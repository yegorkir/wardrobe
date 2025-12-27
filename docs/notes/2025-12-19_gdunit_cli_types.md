# GdUnit CLI Type Resolution Bug

## Summary
- Running `just tests` fails early with `Parser Error: Could not find type "GdUnitTestCIRunner" in the current scope.` since the CLI helper scripts in `addons/gdUnit4/bin` reference plugin classes before the engine knows about them.
- The failure cascades through the log-copy helper, which trips on every `class_name` from the plugin (`CmdOptions`, `GdUnitResult`, `GdUnitCSIMessageWriter`, etc.) because the scripts are not preloaded when the CLI helpers run headless.

## Root cause
Godot only registers a `class_name` after the corresponding script is loaded, so a CLI script that directly references the type (e.g., `var _cli_runner: GdUnitTestCIRunner`) must load the script before parsing. Headless runs that execute `addons/gdUnit4/bin/GdUnitCmdTool.gd` or `GdUnitCopyLog.gd` never load the plugin's `src` scripts first, which means the `class_name`s are unknown at parse time and trigger `Identifier "Foo" not declared` errors.

## Fix approach
- Preload every GdUnit helper script that the CLI binaries reference, ensuring the engine registers the classes before the binaries are parsed.
- Keep the fix localized to the CLI helpers so the rest of the addon stays unchanged.

## Reference
- `class_name` registration notes: https://docs.godotengine.org/en/4.5/getting_started/scripting/gdscript/gdscript_basics.html#class-names
