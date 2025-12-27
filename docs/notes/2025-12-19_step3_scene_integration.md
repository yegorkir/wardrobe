# Step 3 — сцена и интеграция desk/hook

## Что сделано
- Добавлены prefab `DeskServicePoint` и `HookBoard`, обновлена сцена `WardrobeScene.tscn` под 2 desk и 2 hook board.
- В `WardrobeScene` добавлена инициализация Step 3: генерация клиентов/очередей по seed, стартовые тикеты на hook и coat на desk.
- Подключена обработка desk событий: после PUT/SWAP на desk слоте Scene вызывает `DeskServicePointSystem` и применяет доменные события spawn/despawn.
- Добавлен декоративный anchor ticket в `hook_item.tscn`.
- Обновлены функциональные тесты сцены под Step 3 стартовые условия.

## Дизайн‑решения
- Сцена хранит только визуал и маппинг item_id → ItemNode; storage mutates только в core.
- Для маппинга desk используются `DeskServicePoint` адаптеры (desk_id + desk_slot_id), без SceneTree‑логики в core.
- Перемещение тикета на desk реализовано через перенос существующего ItemNode по item_id, чтобы избежать рассинхрона.

## Следующие шаги
- Подключить debug‑логи событий desk в HUD/overlay по необходимости.
- Проверить визуальные позиции новых desk/hook board в Godot.

## Ссылки
- Nodes and scenes: https://docs.godotengine.org/en/4.5/tutorials/scripting/nodes_and_scene_instances.html
