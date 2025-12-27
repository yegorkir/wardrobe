# Setup Godot script

## Что сделано
- Добавлен `scripts/tools/setup_godot.sh` для скачивания Godot 4.5 (stable) и вывода `export` для `GODOT_BIN` и `GODOT_TEST_HOME`.
- В README добавлена короткая инструкция `eval "$(scripts/tools/setup_godot.sh)"` и список переменных для переопределения.

## Использование
- Установка + выставление переменных в текущей сессии:
  - `eval "$(scripts/tools/setup_godot.sh)"`
- Если нужен кастомный URL:
  - `GODOT_DOWNLOAD_URL=... eval "$(scripts/tools/setup_godot.sh)"`

## Ссылки
- Godot downloads: https://godotengine.org/download
