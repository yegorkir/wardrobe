# 2025-12-16 — Skeleton тесты в CI

## Контекст
- Нужно было подключить автоматический прогон `tests/functional/skeleton_validation.gd` в CI, чтобы шаг «Project skeleton» проверялся на каждом push/PR.

## Что сделано
- Создан GitHub Actions workflow `.github/workflows/tests.yml`, который скачивает Godot 4.5 для Linux и запускает `./addons/gdUnit4/runtest.sh -a ./tests` (через `GODOT_BIN=godot`), чтобы покрывать все GdUnit-суиты.
- Триггеры: `push` в `main` и любой `pull_request`; логика изолирована в job `Skeleton validation`.

## Команды
- Локально/CI: `GODOT_BIN=/path/to/Godot ./addons/gdUnit4/runtest.sh -a ./tests`

## Ссылки
- [Command line tutorial — Running projects](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html#running-projects) — подтверждает использование `godot --headless --path . --script ...`.
