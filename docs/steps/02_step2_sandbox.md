# Step 2 — Movement + Pick/Put/Swap Sandbox

> Дополняет [TDD §9](../technical_design_document.md#9-step-2--movement--pickputswap-sandbox). В TDD описаны цели и ответственность систем; этот документ хранит конкретные численные значения и рабочий чеклист, чтобы их можно было менять без переписывания TDD.

## 1. Layout и координаты

- Портретное окно `720×1280`.
- Player спаунится в точке `(360, 1100)`; `HandSocket` смещён на `(30, -36)`, чтобы визуал в руке был читаем.
- `Desk` стоит внизу по центру `(360, 920)`; его `ItemAnchor` остаётся в локальных координатах `(0, -20)`.
- `HookBoard` origin: `(360, 460)` — сетка `2×3` (смещение `Δx = 160 px`, `Δy = 200 px`):
	- Row 0: `Hook_0 (0, 0)`, `Hook_1 (160, 0)`, `Hook_2 (320, 0)`.
	- Row 1: `Hook_3 (0, 200)`, `Hook_4 (160, 200)`, `Hook_5 (320, 200)`.
- Каждый `Hook_i` содержит два слота, расположенных горизонтально вокруг двойного крючка:
	- `SlotA`: `(-40, 0)` относительно крючка.
	- `SlotB`: `(40, 0)` относительно крючка.
- `InteractArea` — `CircleShape2D` радиусом `90 px`, центр (`position = Vector2.ZERO`) совпадает с Player.

## 2. Управление и движение

- Input Map: `move_left/right/up/down`, `interact`, `debug_reset`.
- Скорость игрока: `240 px/s`.
- При вычислении направления движения `dir = Vector2(x, y).normalized()` (диагонали не ускоряют персонажа).

## 3. Targeting и взаимодействия

`find_best_slot()` применяет правила:

1. Минимальная дистанция до `slot.global_position`.
2. Если разница < `6 px`, выбираем слот с максимальным `dot(slot_direction, last_move_dir)`.
3. Если снова ничья — алфавитный порядок по `slot.name`.

## 4. Item data и перенос предметов

- `enum ItemType { COAT, TICKET, ANCHOR_TICKET }`.
- `item_id` формат `<type>_<nnn>` (`coat_001`, `ticket_003`, `anchor_ticket_001`).
- Поля на Step 2:
	- `item_id: String`
	- `item_type: ItemType`
	- `ticket_number: int = -1` (резерв)
	- `durability: float = 100.0` (резерв)
- Перемещение предмета:
	1. `item.reparent(anchor_node)` (или `remove_child`/`add_child`).
	2. Сброс трансформа `global_position = anchor.global_position`, `global_rotation = 0`, `global_scale = Vector2.ONE`. Если item остаётся дочерним `ItemAnchor`, допустимо `item.position = Vector2.ZERO`.

## 5. Seed раскладка

Seed описан в `res://content/seeds/step2_seed.json` (массив `items`). Таблица по умолчанию:

| Slot             | Item              |
| ---------------- | ----------------- |
| `DeskSlot_0`     | `coat_001`        |
| `Hook_0/SlotA`   | `ticket_001`      |
| `Hook_1/SlotB`   | `coat_002`        |
| `Hook_3/SlotA`   | `ticket_002`      |
| `Hook_5/SlotB`   | `anchor_ticket_001` |

Цвет (`color`) задаётся hex-строкой (`#FFEEDD`) или массивом `[r,g,b,a]`. Остальные слоты пусты. WardrobeScene читает файл и fallback'ит на таблицу выше, если файла нет/он пуст.

## 6. Debug и QA процедуры

- `debug_reset` (R): перезагружает текущую сцену.
- `validate_world()` после каждого `interact`:
	- каждый слот содержит 0/1 предмет;
	- активная рука содержит 0/1 предмет;
	- ни один `ItemNode` не числится одновременно в руке и слоте/нескольких слотах.
	Нарушения → `push_error()` + список; `assert()` только в editor/debug сборках.

## 7. Web smoke test

1. Export preset “Web (release)” в `build/web/`.
2. CLI (если нужно автоматизировать):  
	`godot --headless --export-release "Web" build/web/index.html`
3. Поднять локальный статиκ-сервер и открыть сцену в браузере.
4. Проверить WASD, `E` (pick/put/swap) и `R` (reset) на desktop. На mobile браузере убедиться, что сцена стартует без ошибок.

## 8. Step 2.1 — Color Match mini-challenge

- **Автозапуск**: WardrobeScene при старте пытается загрузить `res://content/challenges/<id>.json` (по умолчанию `color_match_basic`). Если файл найден и валиден, включается режим челленджа; иначе сцена работает как sandbox.
- **Формат JSON**:
	```json
	{
	  "id": "color_match_basic",
	  "seed_layout": [ { "slot_id": "...", "item_id": "...", "item_type": "COAT", "color": "#RRGGBB" } ],
	  "target_layout": [ { "slot_id": "DeskSlot_0", "item_id": "...", "item_type": "COAT", "color": "#RRGGBB", "display_name": "Red Coat" } ],
	  "par_actions": 12
	}
	```
	`seed_layout` задаёт стартовую раскладку (в Step 2.1 все пальто висят на крючках). `target_layout` — очередь заказов (какой предмет надо доставить на стойку). `par_actions` пока справочной.
- **Игровой цикл**:
	1. После загрузки сцены `DeskSlot_0` содержит тикет (реальный `ItemNode` типа `TICKET`, который можно подобрать/переместить), его цвет соответствует текущему заказу.
	2. Нужно забрать нужный `ItemNode` с крючка и положить в `DeskSlot_0`. Если `item_id` совпадает с текущим заказом (или тип+цвет), предмет удаляется из мира, очередь продвигается к следующему заказу.
	3. Когда список заказов пуст — челлендж завершён, появляется summary панель, overlay показывает `Solved`.
	4. `debug_reset` (`R`) возвращает seed из challenge JSON, сбрасывает таймер/метрики и увеличивает счётчик попыток.
- **Метрики**:
	- `time_to_solve` (сек, отображается как `MM:SS`).
	- `actions_total` — каждое нажатие `E` (успешное или нет).
	- `picks/puts/swaps` — успешные операции PickPutSwapResolver.
	- `move_distance` — сумма перемещений персонажа в px.
	- `attempts` — количество рестартов (R).
	- Все значения выводятся: overlay (`time | actions` во время игры) + summary панель после завершения + `print()` в консоль.
- **Best результаты**: сохраняем `min(time)` и `min(actions_total)` per challenge id в `user://challenge_bests.json`. Summary показывает сохранённые рекорды строкой `Best: ...`. Файл перезаписывается только при улучшении.
- **Fallback**: если challenge JSON отсутствует, WardrobeScene автоматически возвращается к `content/seeds/step2_seed.json` и отключает overlay/summary.
