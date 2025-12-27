# Checklist — 2025-12-24 Step 4 Workdesk Storage DnD

- [x] Создать `WorkdeskScene` с зонами Storage Hall/Service Zone, `HandRoot` и HUD, сохранив структуру HUD и добавив `mouse_filter=IGNORE` для контейнеров.
- [x] Добавить префаб `StorageCabinetLayout_Simple` и скрипт раскладки, назначающий `slot_id` по схеме `{cabinet_id}_P{index}_SlotA/B`.
- [x] Реализовать `CursorHand` с безопасным reparent и tween-based chameleon preview.
- [x] Реализовать `WardrobeDragDropAdapter` (hover picking, подсветка, DnD-логика, события и watchdog).
- [x] Подключить Workdesk как дефолтный экран в `scripts/ui/main.gd`.
- [x] Добавить выбор сцены старта в `MainMenu` (Workdesk vs Wardrobe legacy) через новый `start_shift_with_screen`.
- [x] Записать изменения и решения в `docs/notes/2025-12-24_step4-workdesk-storage-dnd.md` и обновить changelog.
- [x] Запустить тесты: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests` (exit 0, в логе есть `ERROR: Condition "ret != noErr" is true. Returning: ""`).
