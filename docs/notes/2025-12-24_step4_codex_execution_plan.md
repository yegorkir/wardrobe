# 2025-12-24 — Step 4 (Codex plan): Workdesk + Storage Hall, Drag & Drop, no player

## Контекст
Step 4 переводит MVP-сцену на drag-and-drop и убирает персонажа. Step 2/3 остаются debug harness (не трогаем), а Step 4 становится “по умолчанию”.

## Цель шага (Definition of Done)
- Экран `wardrobe` открывает новую сцену `WorkdeskScene` (без игрока).
- Можно выполнить базовый цикл Step 3, но управляя только DnD:
  - PICK из storage,
  - PUT/SWAP в storage,
  - PUT/SWAP на desk slot.
- Есть `CursorHand` + chameleon preview:
  - hover storage → превью small (плавно),
  - hover service/desk → превью big (плавно).
- End Shift в HUD работает и не запускает DnD “под кнопкой”.
- Тесты запускаются через Taskfile и проходят.

## Non-goals (чтобы не жечь токены)
- Не менять `scripts/domain/**` и `scripts/app/**` ради UI.
- Не “унифицировать” старые адаптеры: `WardrobeInteractionAdapter` остаётся как есть (Step 2/3).
- Не добавлять механику света/архетипов/терпения/волн — только сцена + DnD-поток.
- MVP: мышь обязательно. Тач — только если получается “без разрастания” (не блокер).

---

## Ключевые правила истинности (anti-архитектурный расползун)
- Commands in / Events out: UI инициирует действие только через `WardrobeInteractionService` (build/execute), последствия приходят доменными events, UI их применяет.
- UI не вычисляет “примет ли клиент”/правила выдачи — только домен.
- `WardrobeSlot` остаётся единственным типом слота; “типы шкафов” = разные prefab-раскладки (другая геометрия), а не другая логика.

---

## Границы изменений (минимальный diff)
### New files
- `scenes/screens/WorkdeskScene.tscn`
- `scripts/ui/workdesk_scene.gd`
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
- `scripts/wardrobe/cursor_hand.gd`
- `scenes/prefabs/StorageCabinetLayout_Simple.tscn`
- `scripts/wardrobe/storage_cabinet_layout.gd`  ← presentation-only script (не домен/апп)

### Edit (точечно)
- `scripts/ui/main.gd` — заменить mapping экрана `wardrobe` на `WorkdeskScene`

### Запрещено трогать в Step 4
- `scripts/domain/**`
- `scripts/app/**`
- `scripts/ui/wardrobe_interaction_adapter.gd` (старый proximity-поток)
- любые “чистки/рефакторы мира” не связанные напрямую с Step 4

---

## План работ (Codex tasks)

### Task 1 — Создать сцену `WorkdeskScene` (без игрока)
**Создать:**
- `scenes/screens/WorkdeskScene.tscn`
- `scripts/ui/workdesk_scene.gd`

**Скелет узлов (минимально):**
- `WorkdeskScene (Node2D)` + script
  - `StorageHall (Node2D)`
    - `CabinetsGrid (Node2D)` (6 шкафов: 2×3)
    - `CurtainsColumn (Node2D)` (визуал/переключатель, без геймплей-логики)
    - `BulbsColumn (Node2D)` (визуал/переключатель, без геймплей-логики)
  - `ServiceZone (Node2D)`
    - `ServiceSlots (Node2D)` (2 инстанса `DeskServicePoint.tscn`)
  - `HandRoot (Node2D)`
    - `CursorHand (Node2D)` (из Task 3)
  - `HUDLayer (CanvasLayer)` (переиспользовать структуру HUD из `WardrobeScene`)

**Acceptance:**
- Сцена открывается в редакторе без ошибок.
- HUD кнопка кликается.

---

### Task 2 — Шкафы как prefab-раскладки на едином принципе `WardrobeSlot`
**Создать:**
- `scenes/prefabs/StorageCabinetLayout_Simple.tscn`
- `scripts/wardrobe/storage_cabinet_layout.gd` (только presentation)

**Важно (совместимость Step 3):**
- ticket slots определяются по суффиксу `*_SlotA`. Это правило не менять.
- Каждая “позиция хранения” должна иметь пару:
  - `..._SlotA` (TICKET),
  - `..._SlotB` (COAT).

**Prefab структура (MVP):**
- `StorageCabinetLayout_Simple (Node2D)` + script `storage_cabinet_layout.gd`
  - `Slots (Node2D)`
    - `Pos0 (Node2D)`
      - `SlotA (WardrobeSlot)`
      - `SlotB (WardrobeSlot)`
    - `Pos1 ...` (желательно 2–3 позиции, но можно начать с 1)

**`storage_cabinet_layout.gd`:**
- `@export var cabinet_id: StringName`
- `_ready()` назначает `slot_id` детерминированно:
  - `{cabinet_id}_P{index}_SlotA`
  - `{cabinet_id}_P{index}_SlotB`
- Никаких доменных правил внутри (только ids/геометрия).

**В `WorkdeskScene`:**
- поставить 6 инстансов `StorageCabinetLayout_Simple.tscn`
- проставить уникальные `cabinet_id` (например `Cab_L0_R0` …)

**Acceptance:**
- На старте мира `collect_slots()` находит все слоты.
- Ticket slots (`*_SlotA`) находятся и не пустые.

---

### Task 3 — `CursorHand`: визуальная рука + chameleon preview (плавно)
**Создать:**
- `scripts/wardrobe/cursor_hand.gd` (Node2D)

**API (минимум):**
- `hold_item(node: ItemNode) -> void`
- `take_item_from_hand() -> ItemNode`
- `get_active_hand_item() -> ItemNode`
- `set_preview_small(enabled: bool) -> void`

**Reparent нюанс (обязательно):**
В `hold_item(node)`:
- отсоединить от старого родителя,
- `add_child(node)`,
- сбросить локальный трансформ:
  - `node.position = Vector2.ZERO`
  - `node.rotation = 0.0`
  - `node.scale = Vector2.ONE` (базовый “big”)
- (опционально) `node.z_index = 0`

**Z-order (дешево и надёжно):**
- В `WorkdeskScene.tscn`:
  - `HandRoot.z_as_relative = false` ✅
  - `HandRoot.z_index = 1000`
- HUD остаётся выше через `CanvasLayer`.

**Chameleon preview scale (минимум строк, “дорого” выглядит):**
- внутри `CursorHand` хранить `_scale_tween: Tween?`
- `set_preview_small(enabled)`:
  - target = `small_scale` / `big_scale`
  - если есть `_scale_tween` → `kill()`
  - `_scale_tween = create_tween()`
  - tween’ить `item.scale` (или контейнер-узел превью) за ~0.08–0.12 сек
- если в руке нет предмета — метод должен безопасно выйти.

---

### Task 4 — Новый DnD-адаптер поверх существующего interaction pipeline (простое hover picking без sort)
**Создать:**
- `scripts/ui/wardrobe_dragdrop_adapter.gd` (RefCounted)

**Жёсткий принцип:**
- Адаптер НЕ меняет доменные правила.
- Он только:
  - находит hovered slot,
  - вызывает `build_auto_command + execute_command`,
  - применяет доменные events, двигая `ItemNode` между slot ↔ hand.

**Важно про токены/сложность:**
- НЕ делать `duplicate + sort_custom` на каждый move.
- Делать линейный поиск ближайшего (это и быстрее, и меньше кода, и Codex меньше “оптимизирует”).

**Slot picking (MVP, линейно, стабильно):**
- `_slots_array` кешируется один раз в `configure()` (из `slot_lookup.values()`).
- На `pointer_move(cursor_pos)`:
  - `best: WardrobeSlot = null`
  - `best_d2 = INF`
  - `for s in _slots_array:`:
    - `d2 = cursor_pos.distance_squared_to(s.global_position)`
    - если `d2 < best_d2` → best = s, best_d2 = d2
    - если `d2 == best_d2` или “почти равно” → tie-break по `s.slot_id` (лексикографически), чтобы не дрожало
  - если `best != null` и `best_d2 < 64*64` → hover = best, иначе hover = null

**Hover feedback:**
- хранить `_hover_slot`, снимать/ставить подсветку.
- chameleon:
  - hover storage → `cursor_hand.set_preview_small(true)`
  - hover desk/service → `false`
  - hover null → `false`

**Drop semantics (одна модель):**
- `pointer_down`: если hand пуст и hovered slot занят → PICK.
- `pointer_up`: если hand занят и hovered slot есть → PUT/SWAP.
- если `pointer_up` без hovered slot → ничего не делаем (предмет остаётся в руке).

**Out-of-window / lost release (anti-stuck):**
- Watchdog (только если `_drag_active`):
  - если `!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)` → `cancel_drag()` (снять hover highlight, preview reset)
- В `WorkdeskScene._notification` обработать:
  - `NOTIFICATION_APPLICATION_FOCUS_OUT`
  - `NOTIFICATION_WM_WINDOW_FOCUS_OUT`
  и вызвать `dragdrop_adapter.cancel_drag()`.
- `cancel_drag()` НЕ должен очищать hand — только сброс “drag state”.

---

### Task 5 — Интеграция в `workdesk_scene.gd` (wiring как в WardrobeScene)
**Сделать в `scripts/ui/workdesk_scene.gd`:**
- Повторить оркестрацию как в `WardrobeScene`:
  - собрать slots и desk service points через world setup adapter,
  - поднять storage state, interaction service, event adapter, desk dispatcher,
  - настроить `WardrobeItemVisualsAdapter`,
  - подключить `WardrobeDragDropAdapter` вместо `WardrobeInteractionAdapter`.
- `WorldValidator.validate(slots, null)`:
  - вызывать только в debug/dev (если у проекта есть такой флаг/проверка),
  - передавать `null`,
  - не менять валидатор.

**Важно про `WardrobeItemVisualsAdapter` (anti-conflict):**
- использовать его только для spawn/конфигурации item nodes;
- реальный parenting в руку/слот — только в event-handlers внутри `WardrobeDragDropAdapter`.

**Input routing:**
- `_unhandled_input(event)` в `WorkdeskScene` → `dragdrop_adapter.on_pointer_*` (down/move/up)
- MVP: mouse-события обязательно. Touch-события — только если это 10–20 строк и не раздувает код.

---

### Task 6 — HUD input (чтобы не запускать DnD под кнопками и не блокировать мир)
**Правило:**
- `STOP` только у реально интерактивных элементов (кнопка End Shift).
- Фоновые/декоративные контейнеры HUD, которые перекрывают игровой мир:
  - `mouse_filter = IGNORE` (иначе мир перестанет получать input, и Codex полезет “чинить input”)

**Acceptance:**
- End Shift кликается, DnD под кнопкой не стартует.
- DnD в мире не блокируется невидимыми HUD контейнерами.

---

### Task 7 — Сделать Workdesk дефолтным экраном
**Edit:**
- `scripts/ui/main.gd` — заменить mapping `"wardrobe"` на `WorkdeskScene.tscn`.
- Старую `WardrobeScene` не удалять.

---

## Проверки
### Автотесты (Taskfile)
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

### Быстрый manual smoke (≤ 60 сек)
- Запуск → открывается Workdesk.
- Pick из storage → item в руке.
- Drop на desk-slot → item на desk.
- Hover storage → рука small (плавно).
- Увести курсор за окно + отпустить → вернуться → drag state не “завис”.
- End Shift работает и не делает DnD.

---

## Риски / anti-footguns (коротко)
- **Z-order**: `HandRoot.z_as_relative=false` + `z_index=1000`.
- **Reparent transform**: при hold_item всегда сбрасывать `position/rotation/scale`.
- **Hover picking**: линейный min-dist2 + tie-break по `slot_id`, без sort/duplicate в move.
- **Lost release**: watchdog + cancel on focus out.
- **HUD input**: STOP только кнопкам; большие контейнеры = IGNORE.
