# Iteration 10 MVP rescope — FINAL analysis + implementation plan (delta only, Codex-ready)

## Scope

* Source of truth: `docs/steps/10_Iteration_MVP_Rescope.md`.
* Scan target: current scripts + scenes to identify gaps and concrete change points.
* Output: delta plan only (no implementation here).

---

## Canon (закрепить, чтобы не было “как понял”)

### Главный принцип

**Пола нет.** Любой `REJECT` / `invalid drop` / “нельзя положить сюда” приводит к **return-to-origin**: предмет/тикет анимированно возвращается **туда, откуда начался drag**.

### Что игрок делает

* **Check-in**: клиент “вываливает” предмет(ы) в `ClientTray` (в MVP сейчас `items_per_client=1`, но tray на 4 слота).
* Игрок переносит предметы **только**: `ClientTray → StorageSlots(шкафы/крючки)`.
* Игрок берёт **тикет** (из `TicketRack` или из storage, если вы это оставляете) и **выдаёт клиенту через hover-deliver** (навести на клиента и отпустить).
* **Check-out**: игрок берёт **вещь** из storage и **выдаёт через hover-deliver**.

  * правильная вещь → `ACCEPT_CONSUME_ITEM` (вещь исчезает)
  * неправильная → `REJECT_RETURN_TO_ORIGIN + patience_penalty`

### Что игрок НЕ делает

* Нельзя класть вещи на BigDesk/стойку/куда-либо ещё, кроме разрешённых слотов.
* Нет “desk slot” для приёма/выдачи.
* Любая попытка положить не туда → return-to-origin (с заметным фидбеком).

### Tray blocking

* `ClientTray` **блокирует только check-in** (клиенту нужно место “вывалить вещи”).
* **Check-out может занять сервис-поинт даже если tray не пуст** (хаос “забытых вещей” допустим).

---

## Current state scan (relevant files)

* Service desk scene + prefab

  * `scenes/screens/WorkdeskScene.tscn` (2 `DeskServicePoint_Workdesk`; BigDesk = `DeskSprite`, без коллизий).
  * `scenes/prefabs/DeskServicePoint_Workdesk.tscn` (один `DeskSlot`/`WardrobeSlot`; нет tray, dropzone, layout injection).
* Drag/drop + slot placement

  * `scripts/ui/wardrobe_dragdrop_adapter.gd` (hover slot targeting; fallback на shelf/floor; нет dropzone; нет return-to-origin).
  * `scripts/wardrobe/slot.gd` (occupancy без reservation/origin).
  * `scripts/wardrobe/item_node.gd` (drag/physics states; reject effects; нет return tween).
* Desk/domain flow

  * `scripts/app/desk/desk_service_point_system.gd` (desk-slot модель).
  * `scripts/app/desk/desk_reject_outcome_system.gd` (reject -> drop to floor + patience).
  * `scripts/domain/events/event_schema.gd` (нет deliver attempt/result).
  * `scripts/ui/desk_event_dispatcher.gd` + `scripts/ui/wardrobe_interaction_events.gd`.
* World setup

  * `scripts/ui/wardrobe_world_setup_adapter.gd` (slots по group; тикеты по `_SlotA`).
  * `scripts/ui/wardrobe_step3_setup.gd` (seed тикетов в `*_SlotA`; нет rack/tray).
* Save/load

  * `scripts/autoload/bases/run_manager_base.gd`, `scripts/app/shift/shift_service.gd` + `SaveManager`.

---

## Gap analysis vs Iteration 10 requirements

1. **Layout injection + service point geometry**

* Required: `DeskServicePoint_Workdesk` = клиент + `LayoutRoot`; tray+dropzone инжектятся PackedScene; строгая валидация (4 tray slots, 1 dropzone).
* Current: только desk slot.

2. **Return-to-origin + reservation + limbo safety**

* Required: drag хранит origin slot; origin slot в RESERVED; reject/invalid всегда return-to-origin; во время return tween предмет **не pickable**.
* Current: fallback на shelf/floor, нет reservation, нет limbo.

3. **Input priority**

* Required priority (жёстко):
  **any WardrobeSlot > ticket rack validation (tickets only) > client dropzone deliver > invalid(return)**
  (input сначала выбирает любой slot, дальше валидирует: rack принимает только тикеты, tray/storage — по общим правилам).
* Current: только hover slot, без dropzone.

4. **TicketRack**

* Required: `scenes/TicketRack.tscn` с 7 слотами + стабильный jitter на `ticket_id`, живёт до CONSUME.
* Current: `_SlotA` convention, rack отсутствует.

5. **Tray rule**

* Required: check-in gate по `free_tray_slots >= items_per_client`; check-out не блокируется tray.
* Current: tray отсутствует.

6. **Deliver rules**

* Required: deliver attempt event + explicit result events:

  * `ACCEPT_CONSUME_*`
  * `REJECT_RETURN_TO_ORIGIN` (+ `patience_delta`, `reason`)
* Важно: тикеты в фазах:

  * **Check-in**: принимает **любой свободный тикет** (ticket ещё не “его” до выдачи).
  * **Check-out**: **не принимает тикеты вообще** (только вещи).
* Current: выдача через desk slot; reject падает на floor.

7. **Recovery**

* Required: startup recovery обязательно — всё, что в DRAGGING/RETURNING, возвращается в origin.
* Current: нет.

---

## Recommended solution design

### High-level architecture

* UI/Adapter владеет DragSession (origin, reservation, return tween, input_pickable).
* Domain/App решают “accept/reject + patience delta”, без координат/анкер-пасов.
* ServicePoint layout — data-driven через PackedScene + группы.

---

## Core module changes (by layer)

### Domain (res://scripts/domain/...)

**`scripts/domain/events/event_schema.gd`**

* Add (new path, do not reuse `EVENT_DESK_*`):

  * `EVENT_DELIVER_TO_CLIENT_ATTEMPT`
  * `EVENT_DELIVER_RESULT_ACCEPT_CONSUME`
  * `EVENT_DELIVER_RESULT_REJECT_RETURN`
* Payload:

  * attempt: `{ service_point_id, item_instance_id }`
  * accept: `{ service_point_id, item_instance_id, consume_kind }` (`ticket`/`item`)
  * reject: `{ service_point_id, item_instance_id, patience_delta, reason }`
* Domain **не** хранит origin/anchor/coords.

### App (res://scripts/app/...)

**`scripts/app/desk/desk_service_point_system.gd` (rewrite)**

* Add tray awareness:

  * хранит `tray_slot_ids[service_point_id]`
  * на check-in размещает `items_per_client` в свободные tray slots
* Gating:

  * если incoming client phase = check-in: разрешить посадку только если `free_tray_slots >= items_per_client`
  * если phase = check-out: разрешить посадку **всегда** (независимо от tray)
* Deliver validation (важно — тикеты):

  * Если доставляют `ticket`:

    * **если клиент phase=check-in** → ACCEPT, если тикет “свободный/неиспользованный”
      (ticket pool, no client binding before delivery; link client <-> ticket is created on delivery)
    * иначе (checkout или нет клиента) → REJECT
  * Если доставляют `item`:

    * **если клиент phase=check-out** → ACCEPT только если item принадлежит bundle клиента и ещё не выдан
    * иначе → REJECT
* Outcomes:

  * ACCEPT → emit `ACCEPT_CONSUME` (UI удаляет item node/очищает руку)
  * REJECT → emit `REJECT_RETURN` + patience delta (UI делает return-to-origin; App применяет patience)

**`scripts/app/desk/desk_reject_outcome_system.gd`**

* Убрать `drop_to_floor` полностью.
* Оставить только применение patience penalty (либо перенести penalty в desk_service_point_system и этот файл не трогать — но выбрать один путь и закрепить).

### Adapters/UI (res://scripts/ui/, res://scripts/wardrobe/...)

**`scripts/wardrobe/desk_service_point.gd`**

* Layout injection:

  * `@export var layout_scene: PackedScene`
  * `LayoutRoot` как parent
  * инстансить layout до поиска групп
* Validation:

  * `tray_slots.size() == 4` (жёстко)
  * `dropzone count == 1` (жёстко)
  * tray slot anchors уникальны (жёстко)
  * при ошибке: явный `push_error` + disable service point (чтобы не ломать всё тихо)
* Lookup через группы:

  * `sp_tray_slot` на 4 слотах
  * `sp_client_drop_zone` на dropzone

**`scripts/ui/wardrobe_dragdrop_adapter.gd` (rewrite)**

* Add `DragSessionState`:

  * `origin_slot_id`, `origin_slot_node`, `item_instance_id`, `state`
* Reservation lifecycle (строго):

  * `PICK` → reserve origin slot
  * `RETURNING` → item.input_pickable=false; slot остаётся RESERVED
  * `FINISH_RETURN` → attach → release reservation → pickable=true
* Pointer up resolve (строго и однозначно):

  1. если hover над **WardrobeSlot** → попытка положить (PlacementRules)
  2. else если item is ticket и hover над **TicketRackSlot** → попытка положить тикет
  3. else если hover над **ClientDropZone** → dispatch `DELIVER_TO_CLIENT_ATTEMPT`
  4. else → invalid → return_to_origin
* Любой REJECT/invalid → return_to_origin (никаких shelf/floor fallback)
* Отдельно: rack-слоты **не участвуют** в “перехвате”, если в руке не тикет.

**`scripts/wardrobe/slot.gd`**

* Reservation support:

  * `reserve(item_instance_id)`
  * `release_reservation()`
  * `is_reserved_by(item_instance_id)`
* Поведение:

  * slot считается “занятым для других”, если RESERVED (чтобы не класть туда вторую вещь, пока первая возвращается)

**`scripts/wardrobe/item_node.gd`**

* `return_to_origin(anchor: Node2D, on_complete: Callable)`

  * disable pickable
  * tween
  * enable pickable + callback

**`scripts/ui/wardrobe_interaction_events.gd` / dispatcher**

* Wire new deliver result events:

  * ACCEPT → clear hand, destroy/hide item node, play green flash
  * REJECT → play red flash, call drag_adapter.return_to_origin()

---

## Scenes (res://scenes/...)

1. `scenes/TicketRack.tscn` (new)

* Node2D + 7 `WardrobeSlot` (`TicketRack_0..6`)
* Jitter:

  * stable offset map `ticket_id -> Vector2`
  * offset **не удаляется на pick**
  * offset удаляется **только** на `ACCEPT_CONSUME` (тикет ушёл клиенту)
  * оффсет ограничен (clamp), чтобы тикет не “уплывал” за границы слота

2. Desk service point layout scene (new)

* `ClientTray` (4 `WardrobeSlot` в группе `sp_tray_slot`)
* `ClientDropZone` (Area2D в группе `sp_client_drop_zone`)
* DropZone не пересекается со слотами.
  - Validate at runtime (e.g., `get_overlapping_areas()` in `_ready()` + `push_error`) to catch bad layout.

3. `scenes/prefabs/DeskServicePoint_Workdesk.tscn`

* Удалить/не использовать desk slot как место для предметов.
* Оставить клиента + LayoutRoot; подключить layout_scene экспортом.

4. `scenes/screens/WorkdeskScene.tscn`

* Инстанс `TicketRack`
* Два service point с layout_scene назначенным в инспекторе

---

## World setup alignment

**`scripts/ui/wardrobe_world_setup_adapter.gd`**

* Перестать выводить “ticket slots” через `_SlotA`.
* Добавить сбор:

  * ticket rack slots
  * tray slots (через service points/layout groups или через регистрацию от service points)

**`scripts/ui/wardrobe_step3_setup.gd`**

* Seed “свободных тикетов” в TicketRack (7 штук).
  - Tickets are a pool and are not tied to clients until delivery (no per-client ticket instances on spawn).
* На spawn check-in клиента: desk_service_point_system кладёт item(s) в tray (не setup напрямую в slot, если хотите держать единый путь).
* Никаких “ticket slots в шкафах по умолчанию” — только если вы оставляете старую опцию осознанно (тогда это отдельный флаг, но MVP лучше без этого).

---

## Save/load / startup recovery (обязательно)

* На старте сцены:

  * если есть DragSession в DRAGGING/RETURNING → force attach item обратно в origin_slot
  * release any stale reservations
* Если SaveManager активен:

  * при save: всё в DRAGGING/RETURNING принудительно считается “в origin” (best effort)

---

## Tests (минимальный страховочный контур)

Заменить/добавить 3 теста:

1. `deliver_accepts_any_free_ticket_on_checkin_consumes`
2. `deliver_rejects_wrong_item_applies_patience_and_keeps_slot_state`
3. `tray_blocks_only_checkin_by_free_slots_condition`

---

## Rewrite vs patch

* Rewrite: `wardrobe_dragdrop_adapter.gd`, `desk_service_point_system.gd`
* Remove/gate legacy: `_try_drop_to_shelf/_try_drop_to_floor` (default off)

---

* Где хранить `ticket_id -> jitter_offset`: в компоненте TicketRack (как state)
