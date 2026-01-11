# Step 3 — 2 Desk + 4 Clients + Ticket/Coat Exchange

## Цель шага
Собрать минимальный core loop гардероба без волн/таймера: 2 desk, 4 клиента, обмен COAT↔TICKET через pick/put/swap. Любые исчезновения/появления предметов происходят только через доменные события, которые сцена применяет синхронно со storage.

## Принципы дизайна (SimulationCore-first)
- Источник истины: только RefCounted стейты (RunState, DeskState, ClientState, WardrobeStorageState, ItemInstance).
- Сцена/ноды — адаптеры: строят команды и применяют доменные события, без правил и скрытого состояния.
- Commands in / Events out: все действия игрока → InteractionCommand → InteractionEngine; последствия обслуживания клиентов → доменные события (не Godot signals).
- Core не зависит от SceneTree/Node: никаких get_tree/get_node/NodePath/autoloads в домене и app.
- Storage изменяется только в core; сцена не вызывает pick/place напрямую, а лишь применяет доменные события и синхронизирует визуал.
- Ключи команд/событий не дублируются строками: использовать StringName-константы (единый источник правды).

## Сущности и состояния
### ItemInstance
- Типы: COAT, TICKET, ANCHOR_TICKET (декор, логикой не управляет).
- Цвет — только визуал, не инвариант и не привязка к крючку.

### ClientState
- Поля: client_id, coat_instance_id, ticket_instance_id, phase (DROP_OFF | PICK_UP | DONE), assigned_service_point_id, presence (PRESENT | AWAY), color_id (визуал).
- Связь идёт клиент → coat/ticket, а не «coat_id ↔ ticket_number».

### ClientQueueState
- Единая очередь ожидания клиентов: Array[client_id].
- Клиенты в очереди не сидят за desk; первый N обслуживаются desk-ами, остальные ждут.

### DeskState
- desk_id, desk_slot_id, текущий клиент.

## Сцена и префабы
- WorkdeskScene.tscn: DeskA, DeskB, HookBoard (TicketSlot + CoatSlot + anchor_ticket), опц. debug overlay.
- Prefab `scenes/prefabs/DeskServicePoint.tscn`:
	- Node2D с export desk_id.
	- DeskSlot (Slot) + опц. ClientStandPoint.
	- Никаких правил, только данные/идентификаторы.
- HookBoard: у каждого hook есть TicketSlot (стартово TICKET) и CoatSlot (пусто). Anchor ticket — визуал.

## Доменные события (контракт со сценой)
- desk_consumed_item{desk_id, item_instance_id, reason_code}
- desk_spawned_item{desk_id, item_instance_id, item_kind}
- client_phase_changed{client_id, from, to}
- client_completed{client_id}

Сцена обязана применять эти события: spawn/despawn только через них, без прямых мутаций storage.

## Логика обслуживания (DeskServicePointSystem)
### Инициализация (start)
- Создать RunState и WardrobeStorageState.
- Создать 2 DeskState; создать единый ClientQueueState.
- Добавить 4 клиента в очередь в фиксированном порядке, назначить первых N клиентов на desk (по порядку).
- Создать 4 ClientState: phase = DROP_OFF, назначить coat/ticket/color.
- Разложить тикеты в TicketSlot крючков; anchor_ticket — визуал.
- На каждом desk заспавнить предмет текущего клиента (DROP_OFF → COAT, PICK_UP → TICKET).

### Drop-off
Триггер: после PUT или SWAP, если target_slot_id принадлежит desk.
- Если в desk-слоте оказался TICKET:
	- desk_consumed_item(ticket) — тикет «забран».
	- client_phase_changed DROP_OFF → PICK_UP.
	- Клиент встаёт в конец общей очереди.
	- Desk берёт следующего клиента из очереди (если есть) и спавнит предмет по фазе клиента.
- Требований «правильный тикет ↔ coat» на drop-off нет.

### Pick-up
Триггер: после PUT или SWAP на desk-слоте, когда текущий клиент в фазе PICK_UP.
- Если в desk-слоте оказался COAT:
	- Если coat_instance_id совпадает с текущим клиентом:
		- desk_consumed_item(COAT)
		- client_completed
		- Desk берёт следующего клиента из очереди (если есть) и спавнит предмет по фазе клиента
	- Иначе: отказ (action_rejected / desk_rejected_delivery), предметы не исчезают.

### Presence = AWAY (на будущее)
- DROP_OFF: desk может не принимать тикеты (reject), когда текущий клиент в DROP_OFF.
- PICK_UP: desk может не принимать coat (reject/pending), когда текущий клиент в PICK_UP.

## Обязательный адаптер (WorkdeskScene)
- На событиях InteractionEngine (item_picked/placed/swapped) — обновлять визуал через mapping.
- На desk_* событиях — спавнить/деспавнить ItemNode и синхронизировать storage ↔ сцена.
- Никаких storage_state.pick()/place() напрямую из сцены.

## Definition of Done
- На старте: 2 COAT на desk, тикеты на крючках, coat-слоты пусты.
- Drop-off: тикет исчезает и тут же появляется предмет следующего клиента по его фазе.
- После drop-off: клиент уходит в конец очереди, desk показывает предмет следующего клиента по его фазе.
- Pick-up: правильный COAT → исчезает, следующий предмет появляется по фазе; неправильный → отказ без исчезновений.
- Нет рассинхрона storage/сцены после spawn/despawn.
- DeskSystem готов к 3+ desk и presence=AWAY.

## Реализационные задачи
- Ввести ClientState/DeskState (domain).
- Реализовать DeskServicePointSystem (app) с описанными правилами и событиями.
- Собрать prefab DeskServicePoint и HookBoard.
- Инициализация Step 3 (seed → клиенты, очереди, стартовые предметы).
- Обновить WorkdeskScene/адаптер: триггер DeskSystem на PUT/SWAP, применять доменные события, debug-логи.
- Добавить unit-тесты на DeskServicePointSystem (drop-off, pick-up, reject неверного coat, назначение следующего клиента из очереди).
- Вынести ключи команд/событий в StringName-константы и использовать их во всех местах.
