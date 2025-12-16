# 2025-12-16 — Skeleton validation tests

## Контекст
- Пользователь хотел автоматизировать проверку шага «Project skeleton» и добавить логирование, которое проверяет сами события, а не полный текст.

## Что сделано
- `res://tests/functional/skeleton_validation.gd` переписан как `GdUnitTestSuite`: теперь проверки сцен, InputMap, контента и автосинглтонов выполняются через GdUnit SceneRunner (без кастомного `SceneTree`-скрипта).
- Тест поднимает `WardrobeScene`, убеждается, что HUD получает снимок и реагирует на `hud_updated`.
- Создан `LogProbe`, который слушает сигналы `RunManager` и записывает события (`screen_requested`, `run_state_changed`, `hud_updated`), позволяя проверять ожидаемое поведение без точного сравнения строк логов.
- Добавлено описание запуска: `GODOT_BIN=/path/to/Godot ./addons/gdUnit4/runtest.sh -a ./tests`.
- Ослаблены проверки контента: тест сканирует каталоги `content/` и лишь убеждается в валидном JSON и ненулевых `id`, после чего сверяет только факт загрузки этих записей в `ContentDB`, не привязываясь к конкретным значениям.
- `SaveManagerBase` и `ContentDBBase` теперь аккумулируют историю событий (`get_log_entries()`), которую тест читает вместо анализа сырого stdout; skeleton-тест проверяет, что во время сценария прозвучали `meta_defaulted/meta_cleared/meta_saved` и `category_loaded/content_summary`.
- Добавлены методы `reload_meta_from_disk()`/`reload_run_from_disk()` и тестовый сценарий, который сохраняет кастомный словарь, перезагружает его с диска и убеждается, что `SaveManager` логирует `meta_loaded` и возвращает корректные данные (в дополнение к проверке ветки без файла).
- Проверка `meta_saved` теперь анализирует полезную нагрузку события: тест сравнивает `total_currency` и путь сохранения, чтобы убедиться, что RunManager записал именно те значения, что попали в `ShiftSummary`.
- Добавлены первые GdUnit4 suites: `tests/unit/magic_system_test.gd` (pure logic) и `tests/functional/wardrobe_scene_test.gd` (HUD сигнал), чтобы начать пирамиду тестов.

## Ссылки
- [SceneTree.process_frame](https://docs.godotengine.org/en/4.5/classes/class_scenetree.html#class-scenetree-signal-process-frame) — используется для ожидания кадров в headless-тесте.
