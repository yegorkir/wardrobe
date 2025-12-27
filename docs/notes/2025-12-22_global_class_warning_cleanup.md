# Устранение предупреждений о совпадении глобальных классов и const-алиасов

## Цель
- Убрать шумные предупреждения Godot о совпадении имён глобальных классов с `const`-алиасами.
- Снизить время сканирования тестов и облегчить чтение логов.

## Решение
- Удалены `const`-алиасы с именами глобальных классов (например, `RunState`, `InteractionResult`, `ContentDefinition`) и/или заменены на `*Script`.
- В тестах переименованы `const`-алиасы (`StorageStateScript`, `ItemInstanceScript`, `RunStateScript`) без изменения поведения.

## Затронутые файлы
- `scripts/domain/interaction/interaction_engine.gd`
- `scripts/domain/storage/wardrobe_storage_state.gd`
- `scripts/domain/magic/magic_system.gd`
- `scripts/domain/inspection/inspection_system.gd`
- `scripts/app/shift/shift_service.gd`
- `scripts/app/interaction/interaction_service.gd`
- `scripts/ui/wardrobe_scene.gd`
- `scripts/autoload/bases/content_db_base.gd`
- `tests/unit/interaction_engine_test.gd`
- `tests/unit/interaction_service_test.gd`
- `tests/unit/desk_service_point_system_test.gd`
- `tests/unit/domain/wardrobe_storage_state_test.gd`
- `tests/unit/magic_system_test.gd`
