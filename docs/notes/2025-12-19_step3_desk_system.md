# Step 3 DeskServicePointSystem — старт реализации

## Что сделано
- Добавлены доменные стейты `ClientState` и `DeskState` (RefCounted, приватные очереди, StringName-константы).
- В app‑слое введён `DeskServicePointSystem`: обрабатывает результаты PUT/SWAP на desk‑слоте, продвигает фазы клиентов, эмитит доменные события и меняет storage только внутри core.
- `WardrobeStorageState` получил поиск слота по item_id (нужно для переносов тикета/coat без дублей).
- Добавлены unit‑тесты на drop‑off/pick‑up/reject и переход в PICK_UP.

## Дизайн‑решения
- Клиент хранит ссылки на `ItemInstance` (coat/ticket) и управляет фазами; match в pick‑up идет по `coat_item.id`.
- DeskSystem не полагается на SceneTree и использует только доменные стейты.
- Для событий и payload‑ключей используются `StringName` константы.

## Следующие шаги
- Встроить DeskServicePointSystem в Step 3 инициализацию (seed → клиенты/очереди/стартовые предметы).
- Подключить адаптер в сцене: применять события spawn/despawn для визуала.

## Ссылки
- RefCounted: https://docs.godotengine.org/en/4.5/classes/class_refcounted.html
- StringName: https://docs.godotengine.org/en/4.5/classes/class_stringname.html
