# Отделение debug-проверок целостности мира (P2.2)

## Цель
- Вынести проверку целостности world из `wardrobe_scene.gd` в отдельный debug-валидатор.
- Запускать проверку только в debug-билдах, чтобы не тратить время на релизе.

## Решение
- Добавлен `scripts/ui/wardrobe_world_validator.gd` с методом `validate(...)`.
- В `scripts/ui/wardrobe_scene.gd` оставлен тонкий адаптер `_debug_validate_world()` с проверкой `OS.is_debug_build()`.

## Затронутые файлы
- `scripts/ui/wardrobe_world_validator.gd`
- `scripts/ui/wardrobe_scene.gd`

## Ссылки
- Godot 4.5: `OS.is_debug_build()` — https://docs.godotengine.org/en/4.5/classes/class_os.html#class-os-method-is-debug-build
