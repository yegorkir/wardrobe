# Analysis — Interaction adapter cleanup + logging pipeline

## Task summary
Нужно спланировать улучшения вне текущего плана, соблюдая чистую архитектуру:
- Упростить зависимости `WardrobeInteractionAdapter` через контекст/структуру.
- Вынести логирование интеракций в отдельный сервис/адаптер.
- Добавить легкий `check-only` прогон (опционально) и настроить вывод тестов так, чтобы в консоль шли только `ERROR/WARN` и итоговый статус, при этом сырой лог сохранялся в файл.
- Стандартизировать обработку `unhandled` desk‑events в `WardrobeInteractionEventsAdapter`.

## Current state (observations)
- `scripts/ui/wardrobe_interaction_adapter.gd` имеет длинный `configure(...)` со множеством зависимостей и данных, повышая связность и сложность тестирования.
- Логирование интеракций встроено в адаптер (`print` и `_record_interaction_event` заглушка), отсутствует единый лог‑pipeline.
- `scripts/ui/wardrobe_interaction_events.gd` выводит `unhandled` через `print` без уровня и политики.
- `Taskfile.yml` не содержит отдельного `check-only` таска, а `task tests` печатает шумные сообщения; есть запрос на файл сырого лога и фильтрацию консоли.

## Requirements
- Следовать чистой архитектуре (domain/app не знает про UI/Node, UI‑адаптеры не держат правила).
- Логика логирования должна быть тестируемой и отделённой от UI/интерактора.
- Логи тестов: сырой лог в файл; в консоль только `ERROR/WARN` + итоговый статус.
- Все вспомогательные заметки/планы/чеклисты должны лежать в `docs/notes/YYYY-MM-DD_<type>_<slug>.md`.

## Constraints and risks
- Нельзя править `res://addons/*`.
- Изменения в `Taskfile.yml` должны сохранять текущий workflow и переменные окружения (`GODOT_BIN`, `GODOT_TEST_HOME`).
- Фильтрация логов должна учитывать предупреждение Godot о CA‑сертификатах на macOS (обычно `ERROR` в консоли, но не фатально).

## Solution design (proposed)
### 1) Контекст для `WardrobeInteractionAdapter`
Создать `WardrobeInteractionContext` (RefCounted, UI‑слой), который объединит данные:
- Player, InteractionService, StorageState
- Slots/lookup/item_nodes/spawned_items
- ItemVisuals, EventAdapter, InteractionEvents, DeskDispatcher
- Desk states + queues + clients + callbacks

`WardrobeInteractionAdapter.configure(context)` получает один объект вместо 15+ аргументов. Контекст создаётся в `WardrobeScene` (UI‑слой), чтобы не нарушать слои.

### 2) Отдельный логгер интеракций (UI‑адаптер)
Создать `WardrobeInteractionLogger` в `scripts/ui/`:
- API: `record_success(action, slot, held_item, command)`, `record_reject(reason, slot, command)`.
- Внутри — форматирование строки и отправка в `WardrobeShiftLog` (или в новый лог‑sink), без зависимостей от domain.
- `WardrobeInteractionAdapter` вызывает логгер вместо `print`.

Решение соответствует чистой архитектуре: домен не знает про UI, лог‑политика находится в адаптере.

### 3) Лёгкий check-only в Taskfile
Добавить `task check-only` (опционально) с параметром для списка скриптов. Возможный вариант:
- `task check-only -- res://scripts/ui/wardrobe_interaction_adapter.gd ...`
- запуск: `"{{.GODOT_BIN}}" --path . --headless --check-only --script <path>`

### 4) Фильтрация логов тестов
В `task tests`:
- Записать сырой лог в `reports/test_run_<timestamp>.log`.
- Выводить в консоль только строки, содержащие `ERROR`/`WARN`/`WARNING` + итоговый статус (`Exit code`).
- Возможно добавить `TASK_LOG_FILTER` для гибкости.

### 5) Стандартизация unhandled desk‑events
В `WardrobeInteractionEventsAdapter`:
- Ввести `unhandled_policy` (enum/StringName): `IGNORE`, `WARN`, `DEBUG`.
- По умолчанию `WARN` (через `push_warning`) и возможность отключить.

## Architecture (clean layering)
- **UI/Adapters (`scripts/ui/**`)**: `WardrobeInteractionAdapter`, `WardrobeInteractionLogger`, `WardrobeInteractionContext`, `WardrobeInteractionEventsAdapter`.
- **App (`scripts/app/**`)**: `WardrobeShiftLog` (уже есть) как sink.
- **Domain**: без изменений.
- **Infra**: `Taskfile.yml` для инструментирования тестов/чека.

## Testing impact
- Использовать `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`.
- Если добавится `check-only`, он будет вспомогательным и не заменяет тесты.

## Open questions (resolved by user)
- Логи тестов: raw‑лог в файл + консоль только ERROR/WARN + итоговый статус.
- Чистая архитектура — обязательно.
