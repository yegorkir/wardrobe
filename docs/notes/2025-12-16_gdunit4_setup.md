# 2025-12-16 — GdUnit4 setup

## Контекст
- Для покрытия пирамиды тестов по `tests/AGENTS.md` нужно добавить GdUnit4 v6.x в проект.
- Ранее тесты запускались через кастомный headless-скрипт; теперь появится стандартный `runtest.sh`.

## Шаги
1. Склонирован репозиторий `MikeSchulze/gdUnit4` (тег `v6.0.3`) и скопирован каталог `addons/gdUnit4` в проект.
2. В `project.godot` включён плагин (`[editor_plugins] enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")`).
3. Проверена исполняемость `addons/gdUnit4/runtest.sh`.

## Команды
- Установка: `git clone --depth 1 --branch v6.0.3 https://github.com/MikeSchulze/gdUnit4.git /tmp/gdunit4` → `cp -R /tmp/gdunit4/addons/gdUnit4 addons/`.
- Запуск тестов (после экспорта `GODOT_BIN`): `./addons/gdUnit4/runtest.sh -a ./tests`.

## Дальнейшие действия
- Когда появятся новые тесты (unit/integration/functional), переносить их в GdUnit4-сuites.
- При обновлении версии фиксировать её в заметках и CI.
