# Step 4 — Workdesk + Storage Hall (Drag-and-drop, без персонажа)

> Дополняет [TDD §11](../technical_design_document.md#11-step-4--workdesk--storage-hall-drag-and-drop-без-персонажа).  
> Цель шага: собрать **новую игровую сцену MVP** на drag-and-drop, не ломая уже работающую доменную/апповую логику из Step 3.

## 0. Что считаем «готово» на этом шаге

- В игре **по умолчанию** открывается новая сцена «Workdesk + Storage Hall» (без игрока/ходьбы).
- Можно выполнить базовый цикл Step 3 (перекладывать предметы между storage и service-слотами) **только через drag-and-drop**.
- Есть **CursorHand** (визуальная «рука»), которая держит предмет и следует за pointer.
- Есть **chameleon preview**: при наведении на storage — предмет в руке сжимается заранее; при наведении на service — снова крупный.
- Подсветка target-слота при наведении (snap/hover).
- Все изменения — в пределах UI/scene слоя: доменные/апповые системы не рефакторятся.

Не требуется на этом шаге:
- реальный таймер терпения/волны;
- геймплейный эффект света (Vampire/Zombie/Ghost);
- новый контент/экономика/инспекция.

---

## 1. Новая сцена: структура и зоны

### 1.1 Новый screen scene

Создать новую сцену:

- `res://scenes/screens/WorkdeskScene.tscn`
- `res://scripts/ui/workdesk_scene.gd`

Рекомендуемый скелет (узлы можно переименовать, но смысл сохранить):

- `WorkdeskScene (Node2D)`
	- `StorageHall (Node2D)` — верхняя часть
		- `CurtainsColumn (Node2D)` — слева (клик-переключатель, пока визуально)
		- `CabinetsGrid (Node2D)` — 2×3 шкафов
		- `BulbsColumn (Node2D)` — справа (3 лампы, пока визуально)
	- `ServiceZone (Node2D)` — нижняя часть
		- `ServiceSlots (Node2D)` — контейнер N слотов обслуживания
	- `CursorHand (Node2D)` — поверх всего, следует за pointer
	- `HUDLayer (CanvasLayer)` — можно скопировать из `WardrobeScene.tscn` без изменений

### 1.2 Переключение по умолчанию на новую сцену

Минимальный безопасный путь без правок `RunManager`:

- в `res://scripts/ui/main.gd` заменить маппинг `"wardrobe"` на новую сцену:
	- было: `WardrobeScene.tscn`
	- стало: `WorkdeskScene.tscn`

Старую `WardrobeScene.tscn` не удалять (это debug harness/регрессия Step 2–3).

---

## 2. Storage Hall: шкафы как префабы-раскладки (единый принцип)

### 2.1 Что делаем в Step 4 (минимум)

Сделать **одну** рабочую раскладку шкафа и 6 инстансов (2×3). Остальные типы раскладок оставить как расширение (позже добавляются новыми префабами).

### 2.2 Единый принцип сборки

- Шкаф — это **Node2D-префаб** с:
	- внешним спрайтом/декором;
	- дочерним контейнером `Slots` с набором `WardrobeSlot` в фиксированных местах.
- «Тип шкафа» = конкретный префаб (без генерации в коде на этом шаге).
- Внутри шкафа слоты создаются **из одного и того же узла `WardrobeSlot`** (без новых типов слотов).

### 2.3 Совместимость со Step 3: slot_id и ticket slots

Текущее Step 3 seeding использует правило:

- «ticket slots» = те, у кого `slot_id.ends_with("_SlotA")`.

Поэтому в Step 4 **не менять** эту идею: каждая позиция хранения в шкафу должна иметь пару слотов:

- `..._SlotA` — слот под TICKET
- `..._SlotB` — слот под COAT

Минимальная схема идентификаторов (пример):

- шкаф: `Cabinet_L0_R0` (Left col, row 0)
- позиция внутри шкафа: `P0`, `P1`, ...
- итоговые слоты:
	- `Cabinet_L0_R0_P0_SlotA`
	- `Cabinet_L0_R0_P0_SlotB`

Важно:
- `slot_id` должен быть уникальным в рамках сцены.
- Не переименовывать суффиксы `_SlotA/_SlotB`, иначе сломается `get_ticket_slots()` в `WardrobeWorldSetupAdapter`.

---

## 3. Service Zone: N service slots

### 3.1 Минимальный MVP

На этом шаге можно оставить **2 service slots** (как сейчас в `WardrobeScene`), но разместить их в контейнер `ServiceSlots`, чтобы N стало очевидным масштабированием.

Рекомендуемый подход без новой логики:
- инстансить `res://scenes/prefabs/DeskServicePoint.tscn` N раз;
- не менять `DeskServicePoint.gd`, чтобы `desk_slot_id` формировался штатно.

### 3.2 Плейсхолдер под клиента/терпение

Допустимо добавить простой UI-оверлей (силуэт + статичный progress bar), без тикающего таймера.
Главное — не смешивать это с доменной логикой: пока это только визуальный каркас.

---

## 4. Drag-and-drop: архитектура без рефакторинга домена

### 4.1 Ключевая идея

DnD — это только другой способ выбрать slot-таргет.  
Сама операция должна идти через существующий пайплайн:

- `build_auto_command(hand_item, slot_item, target_slot_id)`
- `execute_command(command)`
- `InteractionResult.events` → existing adapters (`WardrobeInteractionEventAdapter`, `DeskEventDispatcher`, `WardrobeInteractionEventsAdapter`)

### 4.2 Новый UI-адаптер

Создать новый адаптер, отдельный от `WardrobeInteractionAdapter` (не пытаться «унифицировать» сейчас):

- `res://scripts/ui/wardrobe_dragdrop_adapter.gd` (RefCounted)

Он отвечает за:
- поиск `WardrobeSlot` под курсором (best slot);
- старт/продолжение/завершение drag;
- hover-подсветку;
- chameleon preview;
- вызов существующего interaction pipeline.

**Не должен:**
- менять доменные правила;
- лезть в `scripts/domain` или `scripts/app` (кроме абсолютно минимального, если без этого нельзя).

### 4.3 Визуальная «рука» (CursorHand)

Создать узел-контейнер для предмета в руке:

- `res://scripts/wardrobe/cursor_hand.gd` (Node2D)

Минимальный API (duck-typing, без интерфейсов):
- `hold_item(node: ItemNode) -> void`
- `take_item_from_hand() -> ItemNode`
- `get_active_hand_item() -> ItemNode`

`CursorHand` в `_process`/`_physics_process` просто следует за `get_global_mouse_position()` (и для тача — за активным pointer).

### 4.4 Event handlers: как переносим логику «в руку»

В `wardrobe_dragdrop_adapter.gd` реализовать обработчики сигналов event-адаптера по образцу `WardrobeInteractionAdapter`, но вместо Player использовать `CursorHand`:

- `item_picked`:
	- снять `ItemNode` со slot (`slot.take_item()`), положить в `CursorHand.hold_item(node)`;
	- `_interaction_service.set_hand_item(...)`
- `item_placed`:
	- взять из `CursorHand.take_item_from_hand()`, положить в slot (`slot.put_item(node)`);
	- `_interaction_service.clear_hand_item()`
- `item_swapped`:
	- slot.take_item() → в руку; рука → в slot; обновить hand snapshot и т.д.

Так мы сохраняем SSOT: доменная «рука» остаётся в `WardrobeInteractionService`, а визуальная — в `CursorHand`.

---

## 5. Chameleon preview и hover-подсветка

### 5.1 Chameleon preview (требование)

- Когда предмет в руке и курсор наведен на storage-слот:
	- уменьшить масштаб предмета в руке (pre-drop), чтобы он не перекрывал цель.
- Когда курсор над service-слотом:
	- вернуть предмет в «крупный» вид.

Это только визуал. Доменные данные не трогаем.

### 5.2 Hover-подсветка

Минимум:
- хранить ссылку на текущий hovered slot;
- включать/выключать подсветку через его `SlotSprite` (или иной узел в префабе слота).

---

## 6. Чеклист «не потратить токены и не сломать архитектуру»

Самые частые token-провалы в этом шаге:

- Попытка «унифицировать» `WardrobeInteractionAdapter` под Player и DnD → дорого и рискованно.
- Переименование slot_id схемы → ломает Step 3 seeding (`*_SlotA`).
- Перенос логики в `WardrobeSlot`/префабы слотов → превращает view в SSOT.
- Генерация всех типов шкафов кодом вместо 1 рабочего префаба → лишняя сложность.

На этом шаге выбираем «меньше магии, больше предсказуемости».

---

## 7. Definition of Done

- `RunManager.start_shift()` открывает новый экран и можно выполнять drag-and-drop между storage и service.
- `ShiftSummary` открывается и завершает смену как раньше.
- Старые сцены/системы не удалены; тестовые/юнит-тесты не поломаны.
- Slot IDs стабильны и детерминированы; `get_ticket_slots()` продолжает работать.
