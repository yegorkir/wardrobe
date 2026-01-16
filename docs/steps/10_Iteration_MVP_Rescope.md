# Codex Task — Iteration 10 (v3, проверенная, закреплённая)

**Service Desk v2:** 2 клиента, у каждого свой `ClientTray` (4 слота) + `TicketRack` (7 слотов, псевдо-свободная выкладка тикетов) + выдача **“наведи и отпусти на клиента”**.
**Пола нет.** Любой `REJECT` или `invalid drop` возвращает предмет **в origin-слот**, откуда предмет был взят, с заметной анимацией возврата.
**Полки не трогаем** (уже отключены). **10meh.txt игнорировать.**

---

## 0) Канон итерации

### 0.1 Что игрок может делать

**Check-in (сдача):**

1. Клиент приходит в service point и выкладывает `items_per_client` предметов в **свой `ClientTray`**.

   * В MVP сейчас `items_per_client = 1`, но `ClientTray` всегда на **4 слота**.
2. Игрок переносит предмет **из `ClientTray` в слот шкафа**.
3. Игрок берёт **тикет** (обычно с `TicketRack`, опционально — с крючка в шкафу, если оставляете) и выдаёт клиенту через **hover-deliver**:

   * наводит тикет на клиента → отпускает
   * **ACCEPT:** тикет исчезает (зелёный VFX), клиент уходит
   * **REJECT:** красный VFX + минус patience, тикет возвращается в origin-слот

**Check-out (выдача):**

1. Клиент приходит за вещью/вещами.
2. Игрок берёт вещь из шкафа и выдаёт через **hover-deliver**:

   * **ACCEPT:** вещь исчезает (зелёный VFX), когда выдано всё — клиент уходит
   * **REJECT:** красный VFX + минус patience, вещь возвращается в origin-слот

### 0.2 Что игрок НЕ может делать (важно)

* Нельзя класть вещи на BigDesk/стойку.
* `TicketRack` — только для тикетов.
* Нет “desk slot” и нет “ticket slot” у клиента.
* **DropZone клиента НЕ используется для “сдачи предметов на клиента”**. Через DropZone:

  * тикет (check-in)
  * вещи (check-out)
  * и только валидные по владельцу

### 0.3 Правило про “забытые вещи в tray” и очередь (фикс противоречия)

* Если после выдачи тикета вещи остались на `ClientTray`, это создаёт хаос.
* **Tray блокирует только check-in** на этом service point (потому что check-in должен куда-то выкладывать вещи).
* **Check-out можно посадить даже если tray не пуст**, потому что check-out ничего не выкладывает.

---

## 1) Сцены (Godot)

### 1.1 `scenes/WorkdeskScene.tscn`

* `CabinetsGrid`: уже **8 шкафов (2 ряда)** — не меняем.
* `BigDesk`: **только визуал**. **Не должен иметь Area2D/CollisionShape2D**, чтобы не перехватывать input.
* `TicketRack`: отдельный узел поверх BigDesk, интерактивность только у слотов внутри `TicketRack`.
* 2 инстанса `DeskServicePoint_Workdesk` (A/B).

### 1.2 `scenes/DeskServicePoint_Workdesk.tscn` — инъекция layout через PackedScene

**Цель:** геометрия (tray + dropzone) живёт в отдельной layout-сцене.

**Внутри `DeskServicePoint_Workdesk.tscn` остаётся:**

* визуал клиента
* `LayoutRoot: Node2D`
* экспорт:

  * `@export var layout_scene: PackedScene`
  * `@export var layout_parent: NodePath = ^"LayoutRoot"`

**Инициализация (обязательно):**

1. instance layout
2. `add_child(layout_instance)` в `LayoutRoot`
3. `await get_tree().process_frame` (чтобы гарантировать, что группы/нодовая структура уже в дереве)
4. собрать ссылки:

   * 4 слота по группе `sp_tray_slot`
   * 1 dropzone по группе `sp_client_drop_zone`

**Валидация (fail-fast):**

* `tray_slots.size() == 4`
* `drop_zone ровно 1`
* `все tray_slots имеют уникальные ItemAnchor/slot_id` (страховка от “два слота указывают на один anchor”)

Поведение при ошибке:

* `push_error("…")`
* отключить processing у service point (чтобы не ломать всё молча)

### 1.3 `scenes/TicketRack.tscn`

* Node2D `TicketRack`
* 7 `WardrobeSlot`: `TicketRack_0..6`
* псевдо-свободная выкладка:

  * визуальный offset 2–6px
  * offset хранится стабильно по `ticket_id`, НЕ пересоздаётся при “взял/положил обратно”
  * offset удаляется только когда тикет **consumed** (ушёл клиенту) или уничтожен

---

## 2) Drag&Drop и input (ключевая часть итерации)

### 2.1 DragSessionState: origin + резервация

При `PICK` из любого слота:

* записываем `origin_slot_id`
* ставим `origin_slot.RESERVED_BY = item_instance_id`
* item считается “in hand”

### 2.2 Возврат в origin (REJECT / invalid drop)

При `RETURN_TO_ORIGIN` запускается tween возврата:

* **на старте возврата:**

  * `item.input_pickable = false`
  * `drag_session.state = RETURNING`
  * `origin_slot остаётся RESERVED`
* **во время возврата:**

  * item не должен снова подбираться
  * origin-slot не должен принимать другой предмет
* **на tween.finished:**

  * ре-attach предмета в origin-slot (снимаем reservation)
  * `item.input_pickable = true`
  * `drag_session.state = IDLE`

Это закрывает “предмет в лимбе” и гонки.

### 2.3 Приоритеты: slot placement выше dropzone

На `pointer_up`:

1. если курсор над **любым slot-area** (включая TicketRack slots / tray slots / storage slots) → сначала пробуем placement в этот слот
2. иначе если курсор над `ClientDropZone` → deliver attempt
3. иначе → invalid drop → return to origin

Это убирает проблему “TicketRack маленький, DropZone за ним” без “особых правил только для тикетов”.

### 2.4 Ограничение: TicketRack принимает только тикеты

Если target slot принадлежит TicketRack и предмет не тикет:

* reject placement → return to origin (и можно дать мягкий SFX “nope”, без текста)

---

## 3) Доменные события и системы

### 3.1 Событие `DELIVER_TO_CLIENT_ATTEMPT`

Payload:

* `service_point_id`
* `item_instance_id`

Результат домена:

* `ACCEPT_CONSUME` (предмет/тикет уходит клиенту)
* `REJECT_RETURN_TO_ORIGIN` + `patience_delta`

Доменные системы НЕ анимируют возврат, только говорят “надо вернуть”.

### 3.2 `DeskServicePointSystem` (спавн + проверка tray)

**Посадка check-in:**

* разрешено только если tray имеет достаточно свободных слотов под `items_per_client`
* предметы создаются/перемещаются в tray слоты

**Посадка check-out:**

* разрешено независимо от заполненности tray

### 3.3 Deliver rules (чётко, без “скорее нет”)

* Если предмет = тикет:

  * VALID только если это тикет текущего check-in клиента на этом service point
* Если предмет = вещь:

  * VALID только если это вещь текущего check-out клиента на этом service point
* Deliver “сдачи” на клиента через dropzone в MVP **не существует**.

---

## 4) TicketRack jitter lifecycle (без дребезга)

* `offset_map[ticket_id]` создаётся:

  * либо при первом появлении тикета в rack (spawn)
  * либо при первом placement в rack, если тикет ранее не имел offset
* offset НЕ удаляется, когда тикет взяли в руку
* offset удаляется, когда тикет **consumed** (ACCEPT клиентом) или удалён из игры

---

## 5) Save/Load / Recovery (минимальный, но безопасный)

Если у вас есть сохранение:

* при сохранении: если item “in hand” или “returning” → форсируем запись item как находящегося в `origin_slot_id` (и снимаем reservation)
* при загрузке/старте: если находим item без parent_slot, но с origin_slot_id → вернуть в origin-slot

Если сохранений нет:

* хотя бы на старте сцены иметь recovery-проверку “висячих” предметов.

---

## 6) Тесты (минимальные, но по сути)

1. `deliver_accepts_correct_ticket_consumes`
2. `deliver_rejects_wrong_item_returns_to_origin`
3. `tray_blocks_only_checkin_spawn`

(если времени совсем нет — хотя бы 1 и 3)

---

## 7) Definition of Done

Функционально:

* 2 service points, у каждого layout-injected `ClientTray` (4 слота) + `ClientDropZone`
* check-in выкладывает предмет(ы) в tray
* выдача тикета/вещи клиенту только hover-deliver
* wrong item/ticket → REJECT + patience − + **return to origin**
* invalid drop → **return to origin**
* tray блокирует только check-in, check-out допускается
* TicketRack принимает только тикеты, jitter стабилен и не дребезжит

Технически:

* BigDesk не перехватывает input
* slot placement приоритетнее dropzone
* return animation: item непикабелен, origin-slot зарезервирован до конца анимации
* layout injection валидируется (4 слота + 1 dropzone + уникальные anchors)
* recovery на “предмет в руке” при save/load или на старте
