# Changelog — 2025-12-24 Step 4 Workdesk Storage DnD

## Added
- Новая сцена `WorkdeskScene` с зонами Storage Hall/Service Zone, `CursorHand`, `HandRoot` с гарантированным z-order и HUD на базе текущего шаблона.
- Префаб `StorageCabinetLayout_Simple` и `storage_cabinet_layout.gd`, который детерминированно назначает `slot_id` по схеме `{cabinet_id}_P{index}_SlotA/B`.
- `CursorHand` (визуальная рука) с поддержкой reparent в руку и chameleon preview через tween масштабирования.
- `WardrobeDragDropAdapter` для DnD-пайплайна: hover picking, подсветка слота, вызов существующего interaction pipeline, обработка событий и watchdog на потерю фокуса.

## Changed
- `scripts/ui/main.gd`: маппинг экрана `wardrobe` направлен на `WorkdeskScene.tscn`.
- Главное меню теперь позволяет выбрать сцену старта (Workdesk или Wardrobe legacy) через `start_shift_with_screen`.

## Notes
- Доменные/апповые системы не тронуты; DnD остаётся UI-адаптером.
- `_SlotA/_SlotB` схема сохранена для совместимости с Step 3 seeding.

## Tests
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (pass; log содержит `ERROR: Condition "ret != noErr" is true. Returning: ""`, exit code 0).
