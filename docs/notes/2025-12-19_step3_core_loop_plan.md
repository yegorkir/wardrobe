# Step 3 — 2 Desk + 4 Clients + Ticket/Coat Exchange (план + задачи)

## Цель шага
- Собрать минимальный core loop гардероба без волн/таймера: 2 desk, 4 клиента, обмен COAT↔TICKET через pick/put/swap, все исчезновения/появления только через доменные события.

## Ключевые правила истинности
- Runtime state хранится только в RefCounted стейтах (RunState, DeskState, ClientState, WardrobeStorageState, ItemInstance); сцена — чистая визуализация/адаптер.
- Commands in / Events out: действия игрока → InteractionCommand → InteractionEngine; DeskSystem реагирует на события интеракций, все последствия — доменные события (не Godot-сигналы).
- Предметы: COAT, TICKET, ANCHOR_TICKET (декор, не участвует в логике).
- ClientState: client_id, coat_instance_id, ticket_instance_id, phase (DROP_OFF | PICK_UP | DONE), assigned_service_point_id, presence (PRESENT | AWAY), color_id (визуал).
- Storage изменяется только в core; сцена не вызывает pick/place напрямую, а лишь применяет доменные события и синхронизирует визуал.
- Ключи команд/событий не дублируются строками: использовать StringName-константы (единый источник правды).

## Модель и сцена
- WardrobeScene: Player, DeskA/B (prefab), HookBoard (prefab: TicketSlot + CoatSlot + визуальный anchor_ticket), опц. debug overlay.
- Desk prefab (`DeskServicePoint.tscn`): Node2D c export desk_id, DeskSlot, опц. ClientStandPoint; хранит desk_slot_id для адаптера, без правил.
- HookBoard: каждый hook имеет TicketSlot (стартово TICKET) и CoatSlot (пустой); anchor_ticket — визуал.

## Потоки drop-off / pick-up
- Старт: 2 DeskState (drop-off очереди по 2 клиента); 4 ClientState (phase=DROP_OFF, coat/ticket/color связаны с клиентом); в storage тикеты на TicketSlot крючков, на каждом desk лежит coat текущего drop-off клиента.
- Drop-off: при PUT/SWAP на desk_slot с TICKET → desk_consumed_item (тикет забран), client_phase DROP_OFF→PICK_UP, desk спавнит COAT следующего клиента drop-off очереди или переходит в PICK_UP, если очередь пуста.
- Pick-up режим: desk_spawned_item тикета текущего pick-up клиента. При COAT на desk_slot: если coat совпадает с клиентом → desk_consumed_item (coat забран), client DONE, desk спавнит следующий тикет; иначе отказ (action_rejected / desk_rejected_delivery), предметы остаются.
- Нет требований «правильного тикета» на drop-off; порядок/хаос разрешён. Все spawn/despawn идут событиями, сцена применяет их, чтобы не было рассинхрона storage/визуала.

## Доменные события и DoD
- Обязательные события: desk_consumed_item{desk_id, item_instance_id, reason_code}; desk_spawned_item{desk_id, item_instance_id, item_kind}; desk_phase_changed{desk_id, from, to}; client_phase_changed{client_id, from, to}; client_completed{client_id}.
- DoD: корректный старт (2 coat на desk, тикеты на крючках, coat-слоты пусты); drop-off цикл спавнит/деспавнит по событиям; переход в pick-up и выдача coat по тикету; reject на неверный coat; отсутствие рассинхрона storage/сцены; DeskSystem готов к 3+ desk и presence=AWAY.

## Задачи на реализацию
- [x] Ввести стейты desk/клиентов (ClientState с фазами/presence/coat+ticket refs, DeskState с очередями DROP_OFF/PICK_UP, текущими клиентами, фазой desk).
- [x] Реализовать DeskServicePointSystem (app слой): реагировать на interaction applied для desk_slot, продвигать очереди drop-off/pick-up, эмитить события desk_spawned_item / desk_consumed_item / desk_phase_changed / client_phase_changed / client_completed / queue_advanced (при необходимости).
- [x] Собрать prefab `scenes/prefabs/DeskServicePoint.tscn` с export desk_id и маппингом slot_id; подготовить HookBoard prefab (TicketSlot+CoatSlot+anchor_ticket визуал).
- [x] Инициализировать смену Step 3: создать RunState/WardrobeStorageState, сгенерировать 4 клиента и 2 desk очереди по seed (детерминированный), разложить тикеты в TicketSlot, повесить стартовые coat на desk.
- [x] Обновить WardrobeScene/адаптеры: триггерить DeskSystem на PUT/SWAP в desk_slot, применять доменные события для spawn/despawn, синхронизировать Node-инстансы по storage снапшоту, добавить debug-логи событий.
- [x] Добавить покрытие: unit-тест DeskServicePointSystem (drop-off/pick-up happy path, неверный coat reject, пустая очередь → pick-up тикет спавн), smoke на отсутствие рассинхрона storage/визуала.
- [ ] Вынести ключи команд/событий в StringName-константы и использовать их во всех местах.

## Исходный план (копия запроса)
```text
Step 3 — 2 Desk + 4 Clients + Ticket/Coat Exchange (TDD)
0. Цель шага

Собрать минимальный, но правильный “core loop гардероба” без волн/таймера:

Есть 2 desk (точки обслуживания).

Есть 4 клиента, которые случайно встают к одному из desk.

Есть крючки, у каждого крючка есть пара тикетов: ticket и anchor_ticket (якорный — декор/память, не связан логикой).

Игрок делает операции pick/put/swap (Step 2) и обслуживает клиентов в 2 фазах:

Drop-off: клиент приносит COAT → игрок меняет COAT на TICKET (ticket “клиент забирает”).

Pick-up: клиент приносит TICKET → игрок меняет TICKET на COAT (coat “клиент забирает”).

Критерий “правильно”: любое исчезновение/появление предмета происходит через доменные события, которые сцена применяет, чтобы не было ситуации “в симуляции исчезло, на экране осталось”.

1. Слои и правило истинности
1.1 Single Source of Truth

Runtime state: только RefCounted доменные стейты (RunState, DeskState, ClientState, WardrobeStorageState, ItemInstance).

Сцена содержит только визуальные ноды и адаптеры, которые:

формируют команды (interact)

применяют доменные события (move/spawn/despawn)

1.2 Commands in / Events out

Все действия игрока идут как InteractionCommand в InteractionEngine.

Все последствия систем обслуживания (клиент забрал тикет, новый coat появился, тикеты на pick-up) оформляются как domain events (не Godot signals).

2. Игровая модель Step 3
2.1 Предметы (instances)

В Step 3 есть только 3 типа предметов:

COAT

TICKET

ANCHOR_TICKET (декор; можно сделать неинтерактивным или интерактивным, но он не участвует в client↔coat логике)

Важно: “цвет” — это визуальное свойство, оно нужно для “совпадения пары”, но не означает привязку к крючку (игрок может вешать куда угодно).

2.2 Клиент (ClientState)

Клиент хранит свою пару:

client_id

coat_instance_id

ticket_instance_id

phase: DROP_OFF | PICK_UP | DONE

assigned_service_point_id (к какому desk пришёл)

presence: PRESENT | AWAY (на будущее: оборотень)

(опционально) color_id для визуала тикета/пары

Главная фиксация: связь идёт клиент → coat/ticket, а не “coat_id привязан к ticket_number без клиента”.

3. Сцена и префабы
3.1 Структура сцены (высокоуровнево)

WardrobeScene.tscn — песочница шага.

Содержит:

Player (как в Step 2)

DeskA (prefab)

DeskB (prefab)

HookBoard (prefab: крючки+слоты)

(опц.) Debug overlay

3.2 Desk — обязательно в prefab

Создаём prefab scenes/prefabs/DeskServicePoint.tscn:

DeskServicePoint (Node2D)

DeskSlot (Slot)

(опционально) ClientStandPoint (позиция, где стоит клиент визуально)

desk_id (export)

Prefab не содержит правил, только:

хранит desk_id

отдаёт desk_slot_id

помогает адаптеру найти “какой desk относится к этому slot_id”

3.3 HookBoard

Каждый hook содержит 2 интерактивных слота:

TicketSlot (изначально заполнен TICKET)

CoatSlot (изначально пуст)

Плюс якорный тикет как визуал (может быть отдельной нодой-иконкой, не участвующей в storage).

4. Доменные агрегаты и системы
4.1 WardrobeStorageState (уже есть)

Источник истины для размещения:

где лежит каждый ItemInstance (в слоте или в руке)

Инварианты:

предмет в одном месте

слот держит 0..1

операции атомарны

4.2 InteractionEngine (уже есть)

Поддерживает PICK/PUT/SWAP.
Выдаёт доменные события взаимодействия:

item_picked

item_placed

item_swapped

action_rejected

Step 3 не меняет эти правила. Step 3 реагирует на результаты.

4.3 NEW: DeskServicePointSystem (app слой)

Это главное Step 3: система, которая реагирует на изменения в DeskSlot и продвигает фазы клиентов.

Она принимает:

service_points_state (2 desk)

clients_state (4 клиента)

доступ к WardrobeStorageState

событие “interaction applied” (после PUT/SWAP на desk слот)

И возвращает domain events, которые изменят storage/спавны:

desk_consumed_item{desk_id, item_instance_id, reason}

desk_spawned_item{desk_id, item_instance_id, kind}

client_phase_changed{client_id, from, to}

client_completed{client_id}

queue_advanced{desk_id, next_client_id, phase}

Почему это решает твой текущий баг

Сейчас ты “деспавнишь тикет” внутри сервиса без событий, поэтому сцена не знает.
Теперь: любое despawn/spawn — событие, сцена обязана применить.

5. Поток обслуживания (строго фиксируем)
5.1 Инициализация (start)

На старте Step 3:

Создаём RunState и WardrobeStorageState.

Создаём 2 DeskState:

DeskA: очередь DROP_OFF содержит 2 клиента

DeskB: очередь DROP_OFF содержит 2 клиента
(распределение случайное, но детерминируемое seed’ом)

Создаём 4 ClientState, каждому назначаем:

coat_instance_id, ticket_instance_id, color_id

phase = DROP_OFF

Сидим крючки:

в каждый TicketSlot кладём TICKET (визуально цветные)

якорный тикет — визуал (не участвует в storage)

coat слоты пустые

Заполняем desk:

На каждом desk спавним COAT текущего клиента (phase=DROP_OFF).

Итого на старте:

На 2 desk лежат 2 COAT

На крючках лежат тикеты (в каждом hook TicketSlot)

Coat на крючках пока нет

5.2 Drop-off (сдача куртки)

Игрок должен добиться результата: COAT ушёл с desk, TICKET появился на desk, затем TICKET исчез (клиент забрал), и тут же появляется новый COAT следующего клиента (если очередь есть).

Триггер для DeskSystem:

После любого PUT или SWAP, если target_slot_id принадлежит desk’у.

Правило обработки desk в DROP_OFF:

Если в desk слоте оказался TICKET:

desk_consumed_item(ticket) (тикет исчезает, “клиент забрал”)

текущий клиент phase меняется на PICK_UP

desk берёт следующего клиента из своей dropoff-очереди:

если есть → desk_spawned_item(COAT of next)

если нет → desk переходит в PICK_UP режим (см. ниже)

Важно: мы НЕ требуем “правильный тикет к правильной куртке” на drop-off. Игрок может сделать хаос — это нормально. Наша цель Step 3 — обменная механика и корректные спавны.

5.3 Перенос COAT на крючок

Игрок переносит COAT и кладёт в любой CoatSlot (или swap’ает с тикетом).
Это не требует специальной логики, кроме правил storage.

5.4 Переход desk в Pick-up

Когда dropoff-очередь desk пуста:

desk начинает обслуживать клиентов в PICK_UP фазе.

Первым показываем тикет первого завершившего drop-off клиента этого desk (или глобально — но лучше per-desk).

DeskSlot должен отобразить тикет текущего клиента:

desk_spawned_item(TICKET of client)

5.5 Pick-up (выдача куртки)

Игрок должен:

принести COAT на desk и swap’нуть с тикетом (или swap’нуть тикет на крюке — как угодно).

Правило обработки desk в PICK_UP:

Если в desk слоте оказался COAT:

если это coat_instance_id текущего клиента → успех:

desk_consumed_item(COAT) (куртка исчезает, “клиент забрал”)

клиент DONE

desk спавнит следующий тикет следующего клиента в PICK_UP очереди

иначе → отказ:

action_rejected / desk_rejected_delivery (лог)

предметы не исчезают

6. События (контракт с WardrobeScene)

Step 3 вводит дополнительные доменные события, кроме событий взаимодействий.

6.1 Обязательные domain events

desk_consumed_item{desk_id, item_instance_id, reason_code}

desk_spawned_item{desk_id, item_instance_id, item_kind}

desk_phase_changed{desk_id, from, to}

client_phase_changed{client_id, from, to}

client_completed{client_id}

6.2 Adapter обязан уметь применять эти события

WardrobeScene (или отдельный Adapter) должен:

при desk_consumed_item → удалить ItemNode со сцены + удалить его mapping

при desk_spawned_item → создать ItemNode и положить в DeskSlot через storage/или напрямую но синхронно

рекомендуется: storage сначала, потом визуал “подтянуть” по снапшоту или по событию

Главное: никаких “storage_state.pick() без событий”.

7. Подготовка к будущему расширению
7.1 Несколько desk

DeskServicePointSystem работает с массивом DeskState.

Routing всегда идёт через desk_id и desk_slot_id.

Добавление 3-го desk не меняет логику — только данные (список desk в сцене и state).

7.2 Клиент уходит (оборотень)

В ClientState есть presence.
DeskSystem учитывает:

Если presence == AWAY:

DROP_OFF: desk может не принимать тикеты (reject)

PICK_UP: desk не принимает coat (reject или pending)

Это изменение локально для DeskSystem, InteractionEngine не трогаем.

8. UI/Feedback (минимум Step 3)

Визуально видно:

2 desk

на каждом либо coat, либо ticket

на крючках тикеты

coat, которые игрок повесил

Debug печать:

каждое desk_spawned_item / desk_consumed_item

client_phase_changed

HUD/иконки/подсветки не обязательны.

9. Definition of Done (Step 3)

Шаг готов, если:

Стартовая сцена корректна:

На 2 desk лежат COAT (два разных клиента).

На крючках видны TICKET в TicketSlot каждого hook.

Coat слоты пустые.

Drop-off цикл работает и видим:

Игрок может обменять COAT на TICKET на desk (через swap/put).

После появления тикета на desk: тикет исчезает (клиент “забрал”)
и на desk появляется новый COAT следующего клиента (пока dropoff не закончился).

После 2 dropoff на каждом desk — всего обслужено 4 dropoff.

Переход в pick-up:

После завершения dropoff очереди desk, на desk появляется тикет первого клиента для выдачи.

Pick-up корректен:

Если принесли правильный COAT для тикета этого desk → COAT исчезает и показывается следующий тикет.

Если принесли неправильный → ничего не исчезает, пишется reject-лог.

Нет рассинхрона:

Нельзя получить ситуацию “в storage пусто, а на сцене предмет лежит” после любого despawn/spawn.

Все despawn/spawn происходят через доменные события и применяются адаптером.

Расширяемость:

Desk логика не зашита в WardrobeScene; desk вынесен в prefab.

DeskSystem работает по desk_id/slot_id, готов к 3+ desk.

ClientState имеет presence, DeskSystem готов к клиенту AWAY без переписывания InteractionEngine.

10. Что изменится относительно Step 2.1 (важно зафиксировать)

Больше нет “цветного челленджа coat→desk исчезает”.
Теперь “исчезновение/появление” связано с фазами клиента и desk.

Связь “coat↔ticket” хранится в ClientState, а не выводится из цвета/слота.

Якорные тикеты — декор/подсказка, не constraint.
```
