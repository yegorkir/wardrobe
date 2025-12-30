# Shelf Size Tool Sync

## Задача
- Перевести настройку размера полки на `@tool`, чтобы изменения ширины были видны в редакторе.
- Добавить настройку высоты `DropArea/CollisionShape2D` через `@tool`.

## Решение
- Включен `@tool` режим в `ShelfSurfaceAdapter`, добавлены сеттеры, которые синхронизируют ширину/высоту в редакторе.
- Добавлена экспортируемая настройка `drop_area_height_px`, синхронизирующая высоту прямоугольника в `DropArea`.

## Детали реализации
- Введен защитный флаг `_syncing_from_editor`, чтобы изменения из `@tool` не вызывали рекурсию.
- Добавлен шаг инициализации `drop_area_height_px` из текущего `RectangleShape2D`, когда значение еще не задано.

## Ссылки
- https://docs.godotengine.org/en/4.5/tutorials/plugins/running_code_in_the_editor.html
