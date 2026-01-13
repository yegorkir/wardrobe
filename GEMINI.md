# Instructions for Gemini CLI agent (repo: wardrobe)

## Base rules (mandatory)
- Always start by reading `AGENTS.md` and follow it. If you work in `tests/`, read `tests/AGENTS.md` first.
- When refactoring or editing code, also follow `docs/code_guidelines.md`.
- Format GDScript with tabs (unless `.editorconfig` says otherwise).
- Do not invent alternative test commands: run only the canonical command from `AGENTS.md`.

## My practical tips (repo-specific)
### How to avoid waiting on hung tests
If `task tests` hangs or stays silent for too long:
1) Check the latest run log in `reports/`:
   - Logs are named `reports/test_run_YYMMDD_HHMMSS.log`.
   - The current log is the one with the newest timestamp in the name or the newest mtime.
   - Quick command: `ls -t reports/test_run_*.log | head -n 1`
2) If the log contains `debug>` or `Parser Error`, the test crashed and is waiting for input.
3) Also check the HTML report in `reports/report_*`:
   - The newest folder by mtime is the latest: `ls -td reports/report_* | head -n 1`
   - Inside, check `index.html` and `results.xml`.
4) If the CLI shows a long-running `task tests` panel with no new output:
   - Do not wait indefinitely; cancel the command in the CLI.
   - Immediately inspect the latest `reports/test_run_*.log` and `reports/report_*` to see what actually happened.
   - If the log ends at `debug>` or a parser error, Godot is waiting for input and the run will not finish on its own.

### How to pick the latest result
- Priority: the freshest `test_run_*.log` by timestamp in the filename.
- If several logs are close in time, compare mtime or the last error lines.
- For HTML reports, use the newest `reports/report_*` folder by mtime.

### When Godot hangs due to debug mode
- If you see `debug>` in the console, Godot is waiting for commands and will not exit.
- Try a graceful exit first: type `quit` in the Godot console and press Enter.
- If it does not respond, kill the process manually (usually `kill <pid>`; get PID via `ps`).

### Where runtime logs are written (repo-local)
- Runtime logs are configured in `project.godot` to write into the repo at `/.godot/logs/`.
- Primary file: `/.godot/logs/godot.log`.
- Rotated files: `/.godot/logs/godotYYYY-MM-DDTHH.MM.SS.log`.
- If you need the latest log quickly: `ls -t .godot/logs/godot*.log | head -n 1`.

## Required checks after changes
- Always run tests: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
- After tests, always launch Godot: `"$GODOT_BIN" --path .`
