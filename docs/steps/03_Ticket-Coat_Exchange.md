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

### DeskState
- desk_id, desk_slot_id, phase (DROP_OFF | PICK_UP), очередь drop-off, очередь pick-up, текущий клиент.

## Сцена и префабы
- WardrobeScene.tscn: Player, DeskA, DeskB, HookBoard (TicketSlot + CoatSlot + anchor_ticket), опц. debug overlay.
- Prefab `scenes/prefabs/DeskServicePoint.tscn`:
	- Node2D с export desk_id.
	- DeskSlot (Slot) + опц. ClientStandPoint.
	- Никаких правил, только данные/идентификаторы.
- HookBoard: у каждого hook есть TicketSlot (стартово TICKET) и CoatSlot (пусто). Anchor ticket — визуал.

## Доменные события (контракт со сценой)
- desk_consumed_item{desk_id, item_instance_id, reason_code}
- desk_spawned_item{desk_id, item_instance_id, item_kind}
- desk_phase_changed{desk_id, from, to}
- client_phase_changed{client_id, from, to}
- client_completed{client_id}

Сцена обязана применять эти события: spawn/despawn только через них, без прямых мутаций storage.

## Логика обслуживания (DeskServicePointSystem)
### Инициализация (start)
- Создать RunState и WardrobeStorageState.
- Создать 2 DeskState; раздать 4 клиента по drop-off очередям детерминированно по seed.
- Создать 4 ClientState: phase = DROP_OFF, назначить coat/ticket/color.
- Разложить тикеты в TicketSlot крючков; anchor_ticket — визуал.
- На каждом desk заспавнить COAT текущего клиента (drop-off).

### Drop-off
Триггер: после PUT или SWAP, если target_slot_id принадлежит desk.
- Если в desk-слоте оказался TICKET:
	- desk_consumed_item(ticket) — тикет «забран».
	- client_phase_changed DROP_OFF → PICK_UP.
	- Если в drop-off очереди есть следующий клиент → desk_spawned_item(COAT).
	- Иначе → desk_phase_changed DROP_OFF → PICK_UP и спавн тикета текущего pick-up клиента.
- Требований «правильный тикет ↔ coat» на drop-off нет.

### Pick-up
Триггер: после PUT или SWAP на desk-слоте в режиме PICK_UP.
- Если в desk-слоте оказался COAT:
	- Если coat_instance_id совпадает с текущим клиентом:
		- desk_consumed_item(COAT)
		- client_completed
		- desk_spawned_item(TICKET) следующего клиента в pick-up очереди (если есть)
	- Иначе: отказ (action_rejected / desk_rejected_delivery), предметы не исчезают.

### Presence = AWAY (на будущее)
- DROP_OFF: desk может не принимать тикеты (reject).
- PICK_UP: desk может не принимать coat (reject/pending).

## Обязательный адаптер (WardrobeScene)
- На событиях InteractionEngine (item_picked/placed/swapped) — обновлять визуал через mapping.
- На desk_* событиях — спавнить/деспавнить ItemNode и синхронизировать storage ↔ сцена.
- Никаких storage_state.pick()/place() напрямую из сцены.

## Definition of Done
- На старте: 2 COAT на desk, тикеты на крючках, coat-слоты пусты.
- Drop-off: тикет исчезает и тут же появляется новый COAT следующего клиента.
- Переход в pick-up: после исчерпания drop-off очереди desk показывает тикет клиента.
- Pick-up: правильный COAT → исчезает, следующий тикет появляется; неправильный → отказ без исчезновений.
- Нет рассинхрона storage/сцены после spawn/despawn.
- DeskSystem готов к 3+ desk и presence=AWAY.

## Реализационные задачи
- Ввести ClientState/DeskState (domain).
- Реализовать DeskServicePointSystem (app) с описанными правилами и событиями.
- Собрать prefab DeskServicePoint и HookBoard.
- Инициализация Step 3 (seed → клиенты, очереди, стартовые предметы).
- Обновить WardrobeScene/адаптер: триггер DeskSystem на PUT/SWAP, применять доменные события, debug-логи.
- Добавить unit-тесты на DeskServicePointSystem (drop-off, pick-up, reject неверного coat, переход в PICK_UP при пустой drop-off).
- Вынести ключи команд/событий в StringName-константы и использовать их во всех местах.
