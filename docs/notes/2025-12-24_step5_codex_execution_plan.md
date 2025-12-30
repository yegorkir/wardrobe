# 2025-12-24 — Step 5 (Codex execution plan): Clients + Patience + Wave (Workdesk)

## Цель (DoD кратко)
- Workdesk: на Desk_A и Desk_B видны клиент + patience bar.
- Patience у активных клиентов убывает; при 0 → FAIL → end_shift().
- Есть локальный wave timer; при 0 и не все обслужены → FAIL → end_shift().
- Served counter увеличивается только по найденному desk event “client served/completed”.
- DnD (Step 4) без регрессий.
- Wardrobe по-прежнему запускается.

## MVP limitation (фиксируем заранее)
- Patience хранится локально в WorkdeskScene и сбрасывается при перезаходе в сцену.
  Это ок для MVP. TODO(MIGRATE): если появится глобальное время/персистентность — перенос в app/domain state.

## Allowlist (строго)
### New
- scripts/ui/workdesk_clients_ui_adapter.gd
- scenes/prefabs/DeskServicePoint_Workdesk.tscn

### Edit
- scenes/screens/WorkdeskScene.tscn
- scripts/ui/workdesk_scene.gd
- (опционально, add-only) scripts/ui/wardrobe_world_setup_adapter.gd

### Forbidden
- scripts/ui/wardrobe_dragdrop_adapter.gd
- scripts/app/**
- scripts/domain/** (вообще не трогать; patience хранить локально в WorkdeskScene)
- массовые рефакторы, “унификации”, переименования

---

## Task 0 — Discovery (обязательно, до кода)
1) Найти desk event “клиент обслужен”:
    - `rg -n "CLIENT_.*(COMPLETE|SERVED)|COMPLET|SERVED|CLIENT_DONE" scripts`
    - `rg -n "DeskEvent|desk_event|dispatch" scripts`
2) Записать точное имя события/enum/константы.
3) Понять, где WorkdeskScene сейчас получает batch desk_events (точка, где можно инкрементить served).

Stop condition:
- Если событие не найдено: перейти к Task 6 (fallback discovery).

---

## Task 1 — Создать DeskServicePoint_Workdesk.tscn (копия + UI клиента)
1) Скопировать `scenes/prefabs/DeskServicePoint.tscn` → `scenes/prefabs/DeskServicePoint_Workdesk.tscn`.
2) Добавить в prefab:
    - `ClientVisual` (Sprite2D или ColorRect)
    - `PatienceBarBg` + `PatienceBarFill` (ColorRect) ИЛИ `TextureProgressBar`
3) ВАЖНО:
    - всем новым Control: `mouse_filter = IGNORE`
    - визуал клиента/бар не перекрывают предметы:
        - визуально расположить портрет/бар выше зоны предмета (по Y), чтобы не пересекаться с зоной клика стола
        - и/или выставить меньший `z_index`, чем у DeskSlot/ItemAnchor
4) Tooltip footgun:
    - у всех Control-элементов ClientUI убедиться, что `tooltip_text == ""` (пусто).
      (Даже при IGNORE в некоторых версиях/настройках Godot всплывашки могут “просачиваться”.)
5) Добавить маленький script на root prefab (если проще), который кеширует NodePath в `_ready()` и даёт API:
    - `set_client_visible(v: bool)`
    - `set_client_color(c)`
    - `set_patience_ratio(r: float)` (0..1)

Mouse filter footgun (важно):
- `mouse_filter = IGNORE` должен быть выставлен не только на корневом ClientVisual/PatienceBar,
  но и рекурсивно на всех их дочерних Control-узлах (если есть контейнеры/вложенные элементы).
  Иначе DnD будет “спотыкаться” о невидимые рамки UI.

---

## Task 2 — Подменить столы в WorkdeskScene на Workdesk prefab
TSСN safety:
- Не править ExtResource руками, если не уверен.
- Допустимо удалить старые DeskServicePoint и добавить новые инстансы DeskServicePoint_Workdesk “через дерево сцены”.

Действия:
1) В `scenes/screens/WorkdeskScene.tscn` заменить инстансы desk на новый prefab.
2) Сохранить:
    - имена узлов: `Desk_A`, `Desk_B`
    - позиции и место в иерархии (чтобы текущий wiring не сломался)

---

## Task 3 — Создать WorkdeskClientsUIAdapter (без get_node)
New file: `scripts/ui/workdesk_clients_ui_adapter.gd` (RefCounted)

Требования:
- `configure(desks_by_id, desk_states_by_id, patience_by_client_id, patience_max_by_client_id, clients_by_id_opt)`
    - сохранить всё в поля, без поиска нод
- `refresh()`:
    - проход по desks_by_id
    - desk_state -> current_client_id
    - если нет клиента: hide
    - иначе:
        - show
        - set color (плейсхолдер: по client_id)
        - ratio = patience_left / patience_max (если max>0)
        - desk.set_patience_ratio(ratio)
- Никаких `get_node()`/`find_child()`/`get_tree()` в refresh.

---

## Task 4 — WorkdeskScene: локальные состояния волны и терпения (без домена)
Edit: `scripts/ui/workdesk_scene.gd`

Добавить поля:
- `_wave_time_left := 60.0`
- `_wave_finished := false` (один общий guard для WIN/FAIL)
- `_served_clients := 0`
- `_total_clients := 0`
- `patience_by_client_id := {}`
- `patience_max_by_client_id := {}`
- `_clients_ui := WorkdeskClientsUIAdapter.new()`

Setup:
1) Получить `clients_by_id` и `desk_states_by_id`:
    - сначала попробовать взять из существующего setup/wiring
    - если нет доступа → Task 5 (add-only getters)
2) Инициализировать patience для всех client_id:
    - max = 30.0 (или 45.0), left = max
3) `_total_clients = clients_by_id.size()`
4) Собрать `desks_by_id` (Desk_A/Desk_B) и вызвать `_clients_ui.configure(...)`
5) `_clients_ui.refresh()`

Process:
- если `_wave_finished`: return
- `_wave_time_left -= delta`
- если `_wave_time_left <= 0` и `_served_clients < _total_clients`:
    - `_finish_shift_step5()` (см. ниже)
    - return
- тикать терпение только у клиентов, которые сейчас на столах:
    - собрать set активных client_id из desk_states
    - для каждого client_id:
        - patience = max(patience - delta, 0)
        - если 0 → `_finish_shift_step5()` и return
- `_clients_ui.refresh()`

Finish shift helper (важно):
- `_finish_shift_step5()` должен:
    1) выставить `_wave_finished = true`
    2) принудительно отменить DnD, если активен (чтобы не словить null-instance при смене экрана)
        - например `if _dragdrop_adapter.has_active_drag(): _dragdrop_adapter.force_cancel_drag()`
    3) вызвать `_run_manager.end_shift()`

---

## Task 5 — Если нет доступа к clients/desk states: add-only getters
Edit (опц.): `scripts/ui/wardrobe_world_setup_adapter.gd`

Add-only:
- `get_clients_by_id()`
- `get_desk_states_by_id()`

Правила:
- возвращать уже собранные структуры
- не делать поиск нод/групп
- WorkdeskScene трактует как read-only

---

## Task 6 — Served counter wiring (использовать найденное событие)
1) В месте, где WorkdeskScene применяет desk_events:
    - если event.type == <FOUND_EVENT_TYPE>: `_served_clients += 1` (с дедупом по client_id, если он доступен)
2) WIN:
    - если `_served_clients >= _total_clients`:
        - `_finish_shift_step5()` и return

Fallback (если Task 0 не нашёл событие):
- найти событие, которое однозначно означает успешный accept (очистка desk / клиент исчез)
- инкрементить по нему
- НЕ добавлять событие в domain

Win/Fail flow note:
- Step 5 не меняет домен. После `_run_manager.end_shift()` Workdesk должен корректно:
    - либо закрыться (смена экрана),
    - либо перейти в финальный/summary экран,
    - либо показать финальное состояние.
      Если этого не происходит — это баг wiring RunManager/навигации. Чинить минимально, без рефакторов домена/Step 4 DnD.

---

## Checks (после каждого крупного таска)
- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`

Manual smoke:
- Workdesk: видно клиентов и бар.
- Ничего не делать 10–15 сек → bar убывает, возможен FAIL.
- Обслужить всех → WIN/end_shift.
- Во время end_shift, если держал предмет в руке — не должно быть ошибок/зависаний.
- DnD не сломан.
- Wardrobe запускается.
