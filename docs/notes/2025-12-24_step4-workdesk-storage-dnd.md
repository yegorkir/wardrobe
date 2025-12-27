# Step 4 — Workdesk + Storage Hall (Drag-and-drop)

## Context
- Реализован новый экран Workdesk (без персонажа) с drag-and-drop, сохранив доменные/апповые правила Step 3.
- Workdesk подключен как дефолтный экран `wardrobe`, старый proximity-флоу остаётся как debug harness.

## Decisions + tradeoffs
- Новый DnD-адаптер выделен в `WardrobeDragDropAdapter`, без объединения со старым `WardrobeInteractionAdapter` (меньше риска/связности).
- `StorageCabinetLayout_Simple` сделан минимальным префабом с парными слотами `_SlotA/_SlotB` и детерминированными `slot_id`.
- Hover-подсветка реализована через `SlotSprite.modulate` без изменения `WardrobeSlot` (минимальные UI-правки).
- HUD контейнеры переведены в `mouse_filter=IGNORE`, чтобы не блокировать мир, оставляя STOP только кнопке End Shift.

## Implementation notes
- `CursorHand` держит предметы и делает chameleon preview через tween масштабирования.
- DnD-адаптер делает линейный поиск ближайшего слота с tie-break по `slot_id`, без сортировок и генерации массивов на каждом move.
- Потеря фокуса/отпускание кнопки мыши вне окна сбрасывает drag state без очистки руки.
- В главном меню добавлен явный выбор стартовой сцены: Workdesk (DnD) или Wardrobe legacy (proximity).

## References
- Control.mouse_filter: https://docs.godotengine.org/en/4.5/classes/class_control.html#class-control-property-mouse-filter
- Node.create_tween: https://docs.godotengine.org/en/4.5/classes/class_node.html#class-node-method-create-tween

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0, лог содержит `ERROR: Condition "ret != noErr" is true. Returning: ""`).
