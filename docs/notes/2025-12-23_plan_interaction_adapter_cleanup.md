# Plan — Interaction adapter cleanup + logging pipeline

## Goals
- Снизить связность `WardrobeInteractionAdapter` через контекст‑объект.
- Вынести логирование интеракций в отдельный UI‑логгер.
- Добавить `check-only` таск и фильтрацию логов тестов.
- Стандартизировать обработку `unhandled` desk‑events.
- Обновить `AGENTS.md` с требованием хранить все вспомогательные заметки в `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.

## Step 1 — Notes convention in AGENTS
Files:
- `AGENTS.md`

Actions:
- Добавить правило: все вспомогательные заметки (analysis/summary/changelog/checklist и т.п.) создавать в `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Step 2 — Interaction context object
Files:
- `scripts/ui/wardrobe_interaction_context.gd` (new)
- `scripts/ui/wardrobe_interaction_adapter.gd`
- `scripts/ui/wardrobe_scene.gd`

Actions:
- Создать `WardrobeInteractionContext` (RefCounted) с typed‑полями под текущие зависимости.
- Перевести `WardrobeInteractionAdapter.configure(context)` на один параметр.
- В `WardrobeScene` создать/заполнить контекст и передать его в адаптер.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Step 3 — Interaction logger adapter
Files:
- `scripts/ui/wardrobe_interaction_logger.gd` (new)
- `scripts/ui/wardrobe_interaction_adapter.gd`
- `scripts/app/logging/shift_log.gd` (если нужно расширение API)

Actions:
- Вынести логирование интеракций в логгер‑адаптер.
- Подключить логгер в `WardrobeInteractionAdapter` через контекст.
- Заменить `print` в адаптере на вызовы логгера.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Step 4 — Taskfile: check-only + filtered tests output
Files:
- `Taskfile.yml`

Actions:
- Добавить `task check-only` (опционально, принимает список скриптов).
- Модифицировать `task tests`:
  - Писать raw‑лог в `reports/test_run_<timestamp>.log`.
  - Выводить в консоль только `ERROR/WARN/WARNING` + итоговый статус.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Step 5 — Unhandled desk-events policy
Files:
- `scripts/ui/wardrobe_interaction_events.gd`

Actions:
- Добавить политику обработки `unhandled` (например, `StringName` с режимами).
- По умолчанию `WARN`, возможность отключать в конфигурации.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

## Step 6 — Documentation updates
Files:
- `docs/notes/2025-12-23_analysis_interaction_adapter_cleanup.md`
- `docs/notes/2025-12-23_plan_interaction_adapter_cleanup.md`
- `docs/notes/2025-12-23_wardrobe-refactor-implementation.md` (добавить реализацию после выполнения)
- `docs/changelog/2025-12-23_wardrobe_refactor.md`
- `docs/checklist/2025-12-23_wardrobe_refactor.md`

Actions:
- Обновить журналы/чеклисты после выполнения каждого шага.

Tests:
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
