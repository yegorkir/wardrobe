# Wardrobe (Магический гардероб)

Godot 4.5-проект, который демонстрирует вертикальный срез «Магического гардероба»: сцены экранов, автозагрузки (`RunManager`, `ContentDB`, `SaveManager`, `Debug`), демо-контент в `content/` и тесты на GdUnit4 (`tests/`).

## Требования

- **Godot 4.5 (stable)** — скачайте стандартную сборку с [официального сайта](https://godotengine.org/download) и запомните путь к бинарю (он используется во всех CLI-командах).
- **Taskfile (go-task)** — менеджер задач для экспорта и тестов (https://taskfile.dev/).
- Базовые Unix-утилиты (`zip`, `rm`, `mkdir`). На Windows удобнее запускать команды через WSL или адаптировать вручную.

Экспортируйте путь к Godot один раз за сессию (или пропишите в `.zshrc`/`.bashrc`):

```bash
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot   # поправьте под свою ОС
```

## Первый запуск

1. Клонируйте репозиторий и перейдите в каталог проекта.
2. Убедитесь, что раннер GdUnit исполняемый: `chmod +x addons/gdUnit4/runtest.sh`.
3. Запустите тесты: `task tests` (использует `GODOT_BIN`, заданный выше).
4. Откройте `project.godot` и проиграйте `scenes/Main.tscn`, чтобы посмотреть текущую сцену.

## Ежедневные команды

`task` настроен в корневом `Taskfile.yml`. Все задачи требуют настроенного `GODOT_BIN`.

| Команда | Назначение |
| --- | --- |
| `task web` | Экспорт web-сборки для itch.io (`builds/current/web_itch/`). |
| `task web-local` | Экспорт веба в режиме debug для локальных smoke-тестов. |
| `task mac-debug` | Собирает debug-билд для macOS (`builds/current/macos/Wardrobe.app`). |
| `task tests` | Запускает все GdUnit4-суиты (`addons/gdUnit4/runtest.sh -a ./tests`). |
| `task save` | Архивирует содержимое `builds/current/` в `builds/archive/` и очищает текущие сборки. |

Набор команд синхронизирован с CI (`.github/workflows/tests.yml`), поэтому одинаковый `GODOT_BIN` гарантирует идентичность локальных и CI-результатов.
Экспортные пресеты исключают `tests` и `addons/gdUnit4`, так что сборки не содержат тестовые сцены и плагин.

## Ручной запуск тестов

`task tests` — рекомендованный путь, но можно дернуть скрипт напрямую:

```bash
GODOT_BIN=/path/to/Godot ./addons/gdUnit4/runtest.sh -a ./tests
```

Коды возврата показывают успешность (0) или наличие предупреждений/ошибок. Отчеты падают в `res://reports/`. Сменить директорию можно флагом `-rd`. За правилами по тестам смотрите `tests/AGENTS.md`.

## Документация и развитие

- `docs/project.md` — структура сцен/автолоадов.
- `docs/technical_design_document.md` — дизайн и план следующих шагов.
- `docs/notes/*.md` — заметки задачи (CI, GdUnit, skeleton-тесты).

Перед добавлением новых подсистем обязательно пробегитесь по этим документам, чтобы сохранить целостность архитектуры.
