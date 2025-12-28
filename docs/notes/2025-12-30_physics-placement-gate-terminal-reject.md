# 2025-12-30 — Analysis: Physics Placement Gate + Terminal Reject

## Цели и объём
Фокус: R1 → R5 → R2 → R2.5 (R3 отложен).
- R1: единый источник правды для layers/masks/groups.
- R5: Geometry API в ItemNode (AABB/bottom/snap).
- R2: SurfaceRegistry и выбор пола по surface_y (без group-scan в горячем пути).
- R2.5: PlacementGate/OverlapPolicy, терминальный REJECT через pass-through fall, Stable immunity.

## Наблюдения по текущему коду (факты)
- `ItemNode` уже имеет `enter_drag_mode()/exit_drag_mode()` и pass-through (`enable_pass_through_until_y`).
- В `ItemNode` уже есть `get_physics_shape_query()` и часть геометрических хелперов используется тик-адаптером: задача R5 — **свести в единый API и убрать дубли**, а не писать всё с нуля.
- Магические биты/строки раскиданы по:
  - `scripts/wardrobe/item_node.gd` (DEFAULT_COLLISION_LAYER/MASK, pick area mask).
  - `scripts/ui/wardrobe_physics_tick_adapter.gd` (SHELF_LAYER_MASK/ITEM_LAYER_MASK, группы).
  - `scripts/ui/wardrobe_dragdrop_adapter.gd` (pick query mask, группы).
  - `scenes/prefabs/item_node.tscn`, `scenes/prefabs/shelf_surface.tscn` (collision_layer/mask).
- Есть расхождение между .tscn и скриптом по `PickArea`: prefab задаёт layer/mask, но скрипт переопределяет в `_prepare_pick_area()`. Это дополнительный аргумент за SSOT + проверку префабов на соответствие.
- `WardrobePhysicsTickAdapter` делает overlap reject, но REJECT не терминален: после дропа предмет снова проходит через resolve/clamp/settle.
- Выбор пола по Y использует `zone.global_position.y` (в `WardrobeDragDropAdapter` и tick), что ломается при смещённых origin-ах.
- AABB/низ предмета вычисляется в нескольких местах (`ItemNode.get_global_bottom_y`, `_get_item_aabb` в tick, snap в `ShelfSurfaceAdapter`).

## Требования (включая инварианты)
- Small overlap допустим: микро-нудж только для активного предмета в пределах бюджета.
- Big overlap → REJECT → всегда на пол (pass-through fall). REJECT терминален до достижения пола.
- Stable immunity: STABLE предметы не двигаются руками (никаких импульсов/position+=).
- Обязательный контракт запуска тестов: `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`, затем `"$GODOT_BIN" --path .`.
- Требования `docs/code_guidelines.md` применяются к новому коду и тестам: статическая типизация, без предупреждений парсера, без неоднозначных ternary, preload коллабораторов.

## Риски и несоответствия, которые нужно заранее учесть
- **Тесты R1/R5 по условиям** предлагают создавать unit-тесты с `PackedScene.instantiate()` и `ItemNode`.
  - Это противоречит `tests/AGENTS.md`: unit-тесты не должны использовать `Node`/SceneTree.
  - Нужен явный выбор: (A) перенос в `tests/integration`/`tests/functional` с SceneRunner, либо (B) исключение из правил.

## Решение (дизайн, целевая архитектура)
### R1 — PhysicsLayersConfig (SSOT)
**Цель:** централизовать слои/маски/группы в одном файле.

Предлагаемая структура:
- SSOT размещаем в одном из вариантов:
  - A) `scripts/common/physics_layers.gd` (существует, не требует новых папок).
  - B) `scripts/wardrobe/config/physics_layers.gd` (создать папку при реализации, если хотим жёстче привязать к wardrobe runtime).
- Константы:
  - `LAYER_ITEM_IDX = N` (1-based, 1..32)
  - `LAYER_ITEM_BIT = 1 << (LAYER_ITEM_IDX - 1)`
  - `LAYER_SHELF_IDX = M` (1-based, 1..32)
  - `LAYER_SHELF_BIT = 1 << (LAYER_SHELF_IDX - 1)`
  - `LAYER_FLOOR_IDX = K` (1-based, 1..32)
  - `LAYER_FLOOR_BIT = 1 << (LAYER_FLOOR_IDX - 1)`
  - `LAYER_PICK_AREA_IDX = P` (1-based, 1..32)
  - `LAYER_PICK_AREA_BIT = 1 << (LAYER_PICK_AREA_IDX - 1)`
  - `MASK_ITEM_DEFAULT = ...`
  - `MASK_FLOOR_ONLY = LAYER_FLOOR_BIT`
  - `MASK_PICK_QUERY = LAYER_PICK_AREA_BIT` (или `|` ещё чего-то, если нужно)
  - группы: `GROUP_SHELVES`, `GROUP_FLOORS`, `GROUP_TICK`.
  - Пояснение: `collision_layer` = “кто я”, `collision_mask` = “с кем я сталкиваюсь”.
    - `MASK_ITEM_DEFAULT` включает полки + пол (+ предметы, если это задумано).
    - `MASK_PICK_QUERY` включает слой `PickArea`.
    - PickArea — это “что мы ищем” (query), а не “с чем сталкиваемся физикой”.
    - `MASK_PICK_QUERY` используется только в PhysicsPointQueryParameters2D / PhysicsShapeQueryParameters2D / `intersect_*`, а не как `item.collision_mask`.
    - `MASK_FLOOR_ONLY` должен включать слой физического пола (StaticBody2D/TileMap collider на `LAYER_FLOOR`).
      - FloorZone Area2D сама по себе не остановит RigidBody2D, поэтому она не может быть единственным “floor-only” слоем.
      - Если в логике падения/стабилизации используются сигналы Area2D (например FloorZone), их можно детектить отдельными query/overlap, но не через `collision_mask` предмета.
    - `LAYER_*_IDX` должны совпадать с “слой №” в ProjectSettings (желательно фиксировать имена слоёв там же).
    - В SSOT храним и имена слоёв; контрактный тест проверяет совпадение ProjectSettings layer names с ожидаемыми (если это принято трогать тестами).

**Архитектурный эффект:**
- Все адаптеры и `ItemNode` используют только эти константы.
- Слои/маски не должны импортироваться в `scripts/domain/**` или `scripts/app/**` (чтобы не тянуть Godot‑специфику в core).
- Prefab-значения (tscn) сверяются/обновляются на соответствие.
  - Выбор по умолчанию: предметы **сталкиваются с предметами** через `MASK_ITEM_DEFAULT` (фиксируем сейчас для一致ности).
  - Минимальный состав: `MASK_ITEM_DEFAULT = LAYER_SHELF_BIT | LAYER_FLOOR_BIT | LAYER_ITEM_BIT`.
  - Это осознанная цена: item-item коллизии повышают шанс микродвижений из-за депенетрации (допускается в пределах `pos_eps`).

### R5 — Geometry API в ItemNode
**Цель:** единый источник правды для геометрии, без дублирования вычислений.

Новые API:
- `get_collider_aabb_global() -> Rect2`
- `get_bottom_y_global() -> float`
- `snap_bottom_to_y(y: float) -> void`

**Инварианты:**
- `bottom_y == aabb.end.y` (с допуском).
- `snap_bottom_to_y` корректирует `global_position.y` без side-effects.

**Замены:**
- `WardrobePhysicsTickAdapter._get_item_aabb()` → `ItemNode.get_collider_aabb_global()`.
- `ShelfSurfaceAdapter.place_item()` → использовать `snap_bottom_to_y`.
- Drag/drop pass-through расчёт пола → `get_bottom_y_global` вместо визуальных half-height.

### R2 — SurfaceRegistry
**Цель:** убрать group-scan из горячего пути и привязать выбор пола к `surface_y`.

Новый модуль:
- `scripts/wardrobe/surface/surface_registry.gd` (autoload singleton).
- API:
  - `register_floor(surface: Node)` / `unregister_floor(surface: Node)`
  - `register_shelf(surface: Node)` / `unregister_shelf(surface: Node)`
  - `get_floor_below(x: float, item_bottom_y: float) -> Node` (surface)
  - `remove_item_from_all(item: ItemNode)`

**Выбор пола:**
- Идём по `surface_y` + bounds (`get_surface_bounds_global`).
- Побеждает ближайшая поверхность ниже по `surface_y` и с X в bounds.
- В 2D Godot Y растёт вниз, поэтому “пол ниже” = `surface_y >= item_bottom_y`.
- Registry используется только в адаптерах (`scripts/wardrobe/**` и `scripts/ui/**`), без импорта в `scripts/domain/**` или `scripts/app/**`.
- Жизненный цикл (autoload): shelf/floor adapters регистрируются в `_ready()` и снимаются в `_exit_tree()` через `SurfaceRegistry`.
- Требования к surface: `get_surface_y_global()`, `get_surface_bounds_global()`, опционально `drop_item_with_fall(item)`.
  - `get_surface_y_global()` обязана возвращать линию контакта (surface Y), не `global_position.y` контейнера.
  - Минимальный surface-contract для registry:
    - `get_surface_y_global() -> float`
    - `get_surface_bounds_global() -> Rect2` (bounds в global координатах)
      - сравнение по X делается с `aabb.center.x`
    - `remove_item(item)` (если используется `remove_item_from_all`)
    - `drop_item_with_fall(item)` (опционально)

### R2.5 — PlacementGate/OverlapPolicy
**Цель:** сделать REJECT терминальным и отделить решение от применения.

Кандидатные архитектуры:
1) **PlacementGate (RefCounted) + OverlapPolicy**
   - `PlacementGate.decide_drop(item, hits, surface, metrics) -> Decision`
   - `Decision`: `ALLOW`, `ALLOW_NUDGE`, `REJECT`
2) **Single OverlapPolicy**
   - чистый policy + методы применения в tick/drag.
3) **Встроить в `WardrobePhysicsTickAdapter`**
   - минимальные изменения, но хуже тестируемость.

**Рекомендация:** вариант 1 (разделение решения и применения). Это упрощает тесты и делает REJECT терминальным по контракту.  
**Важно по неймингу:** в репозитории уже есть `scripts/app/wardrobe/placement/*`, поэтому новый `PlacementGate` нужно назвать так, чтобы не конфликтовать с текущей placement-системой (например `PhysicsPlacementGate`/`OverlapGate`) и не вводить доменную путаницу.

**Терминальный REJECT (контракт):**
- `ItemNode` переводится в режим падения с pass-through, отключаются коллизии с items/shelves.
- Повторные overlap/resolve/clamp пропускаются до достижения пола.
- По достижению пола восстанавливаются дефолтные коллизии и включается стабилизация.
  - Для этого в `ItemNode` хранится явный флаг терминального reject (например `is_reject_falling` или `pass_through_until_y` + `reject_cooldown_frames`), и tick/clamp обязаны early-return пока флаг активен.
  - Пока `is_reject_falling` активно, предмет не должен регистрироваться на shelf surface (даже если пересекает DropArea).
    - Это должно проверяться и в `ShelfSurfaceAdapter`, и в `WardrobeDragDropAdapter` (если регистрирует он), чтобы не было гонки.
- Восстановление коллизий выполняется в `ItemNode` (в `_physics_process`, т.к. `ItemNode extends RigidBody2D`): если `is_reject_falling` и `bottom_y >= pass_through_until_y - eps`, то вернуть `collision_layer/mask`, сбросить флаг и передать в стабилизацию.
  - Везде используется один базис Y: `item_bottom_y` (нельзя сравнивать `global_position.y`, иначе возможен ранний restore внутри полки).

**Stable immunity:**
- Любые ручные импульсы/позиционные сдвиги применяются только к активному предмету (release/drop → `SETTLING`/`FALLING_REJECT`), и никогда к `State.STABLE`.
  - STABLE = `|linear_velocity| < v_eps` и `abs(angular_velocity) < w_eps` **N physics frames подряд** → `freeze=true` (чёткий критерий вместо “по времени”).
  - Stable immunity означает “наш код не двигает STABLE руками”; микродвижения движка допустимы в пределах `pos_eps`.

**Где принимается решение:**
- Решение (ALLOW/REJECT) принимается в момент RELEASE/DROP; tick дальше только стабилизирует и делает micro-nudge для активного предмета.
  - micro-nudge применяется **до** freeze, **только в SETTLING**, и **только если** overlap найден, но пороги не превышены.
  - `reject_cooldown_frames` блокирует повторную оценку gate, но **не** блокирует stability check (чтобы предмет стабилизировался на полу).
    - `reject_cooldown_frames >= 1`, чтобы избежать повторной оценки в том же physics tick при редких порядках вызовов.

## Модули и классы (предварительный дизайн)
- `scripts/common/physics_layers.gd` или `scripts/wardrobe/config/physics_layers.gd` (если выбран вариант B).
  - набор `const` слоёв/масок/групп.
- `scripts/wardrobe/item_node.gd`
  - Geometry API + pass-through state + единый слой/маска.
- `scripts/wardrobe/surface/surface_registry.gd`
  - хранение поверхностей (shelf/floor), lookup по `surface_y` и bounds, `remove_item_from_all`.
- `scripts/ui/wardrobe_physics_tick_adapter.gd`
  - использует `SurfaceRegistry` и `PlacementGate`.
- `scripts/ui/wardrobe_dragdrop_adapter.gd`
  - выбор пола через registry, pass-through при drop.
- `scripts/ui/shelf_surface_adapter.gd`, `scripts/ui/floor_zone_adapter.gd`
  - регистрируются в registry, предоставляют `surface_y` и bounds.

## План тестирования (до рефакторов)
**Решение:** `tests/unit` остаются без `Node`/SceneTree, `tests/integration`/`tests/functional` используют GdUnit4 SceneRunner. Запуск тестов — только через Taskfile.
Если `tests/integration`/`tests/functional` отсутствуют, создать каталоги как часть реализации или использовать существующую структуру и обновить пути в плане.

Предлагаемые уровни:
- Unit (decision logic):
  - `tests/unit/test_overlap_policy_decision.gd`
  - Только `RefCounted`/структуры данных. Граничные значения порогов. `STABLE` → без `ALLOW_NUDGE`.
  - Если decision не отделим от physics hits, переносить этот блок в functional.
- R1 (contract): `tests/integration/test_physics_layers_contract.gd`
  - инстанс `ItemNode` prefab, проверки `enter_drag_mode/exit_drag_mode`.
  - Проверять runtime truth: после `_ready()` у ItemNode и PickArea layer/mask = SSOT.
- R5 (geometry): `tests/integration/test_itemnode_geometry.gd`
  - проверка `bottom_y`, `aabb`, `snap` с epsilon.
- R2 (registry): `tests/integration/test_surface_registry.gd`
  - мини-сцена с floor zone(s), выбор по `surface_y`.
- R2.5 (placement gate): `tests/functional/test_placement_gate_contract.gd`
  - SceneRunner, shelf+floor+items, сценарии reject/allow/stable.
  - Отдельный тест: `test_reject_is_terminal_pass_through` — после REJECT до достижения пола предмет не может снова считаться “на полке” и не проходит через clamp/place на shelf.
    - Проверять, что предмет не зарегистрирован на shelf (нет в списке/реестре), и pass-through флаг активен до restore.
  - Стабильность фиксировать по состоянию/флагу (например `state==STABLE` или `freeze==true` после N кадров), а не по таймеру.
  - Шагать фиксированное число physics frames (например 30–90), без ожидания реального времени.
  - Все тесты должны быть без предупреждений парсера (дисциплина `docs/code_guidelines.md`).

Если требуется строго `tests/unit/**`, понадобится отдельное разрешение на использование Node/SceneTree в unit-тестах.

## Нефункциональные требования
- Детерминизм и предсказуемость placement-решений.
- Минимальные диффы, без затрагивания доменного слоя.

## Официальные ссылки (Godot 4.5)
- Collision layers/masks: https://docs.godotengine.org/en/4.5/tutorials/physics/physics_introduction.html#collision-layers-and-masks
- PhysicsDirectSpaceState2D: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
- PhysicsRayQueryParameters2D: https://docs.godotengine.org/en/4.5/classes/class_physicsrayqueryparameters2d.html
- PhysicsShapeQueryParameters2D: https://docs.godotengine.org/en/4.5/classes/class_physicsshapequeryparameters2d.html
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- Node groups: https://docs.godotengine.org/en/4.5/tutorials/scripting/groups.html

## Принятые решения
1) R1/R5 тесты — в `tests/integration`/`tests/functional` (unit-тесты остаются без `Node`/SceneTree).
2) SSOT-конфиг: вариант A `scripts/common/physics_layers.gd` или вариант B `scripts/wardrobe/config/physics_layers.gd` (единый источник, без дублирования).
3) Reject-fall: использовать floor-only mask (не `collision_layer=0`, `collision_mask=0`).
4) Пороги: экспортируемые (Resource) + дефолты константами для контрактов.
5) SurfaceRegistry — autoload singleton; shelf/floor adapters регистрируют себя в `_ready()` и снимаются в `_exit_tree()`.
