# Step 6.1 — Physics-Based Storage (No-SU)

## Цель
Полностью убрать SU/interval‑логику и перейти на физическое размещение предметов:
- ItemNode = `RigidBody2D` (масса + CoG)
- Shelf/Floor = реальные поверхности (`StaticBody2D`)
- Drag безопасен: предметы не толкают друг друга во время перетаскивания
- Drop решается физикой + проверкой устойчивости через raycast от CoG
- Domino wake-up + auto-freeze после успокоения
- UX: Gravity Line (CoG → вниз), unstable warning (red + shake + icon)

## Ограничения
- Соблюдать `AGENTS.md` и архитектуру (domain/app не трогать без необходимости).
- `scripts/domain/**` — не менять.
- Держать слот‑DnD (hooks/desks) как сейчас: snap‑to‑center, без физики.
- Изменения делать маленькими шагами, после каждого шага проект должен быть запускаемым.

## Ключевые изменения (адаптировано под текущий код)

### 1) Удалить SU/units из wardrobe‑логики
Убираем из UI/app‑слоя все SU‑сущности:
- `capacity_units`, `UNIT_SCALE`, `size_su`, `x_su`, интервалы размещения.
- `DefaultPlacementBehavior` и `WardrobePlacementTypes` не используются для shelf/floor.
- `WardrobeItemConfig.get_size_units()` больше не нужен для shelf/floor.

Остается только place_flags для hook/desk логики (HANG/LAY).

### 2) Слои коллизий (фиксированные номера)
Заводим единые номера:
- Layer 1: Static geometry (shelves + floor)
- Layer 2: Items (`RigidBody2D`)
- Layer 3: Interaction (PickArea + DropAreas)

Правила:
- Items (normal): `collision_layer = 2`, `collision_mask = 1|2`
- Items during drag: `collision_layer = 0`, `collision_mask = 0`
- DropAreas: `collision_layer = 3`; mask по необходимости, но без физического контакта

### 3) ItemNode → физический объект
Обновить `scripts/wardrobe/item_node.gd` и `scenes/prefabs/item_node.tscn`:
- Базовый тип: `RigidBody2D`
- Default:
  - `freeze = true`
  - `freeze_mode = FREEZE_MODE_KINEMATIC`
  - `contact_monitor = true`, `max_contacts_reported >= 2`
- Экспортируемые параметры:
  - `@export var mass: float = 1.0`
  - `@export var cog_offset: Vector2 = Vector2.ZERO`
- Автоколлизия:
  - Если `CollisionShape2D.shape == null`, создать `RectangleShape2D` по размеру спрайта.
  - Padding: `collision_padding = 2.0` (уменьшаем прямоугольник).
- Настройка CoG:
  - `center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM`
  - `center_of_mass = (local_bounds_center) + cog_offset`
- PhysicsMaterial:
  - `friction = 0.8`
  - `bounce = 0.1`

Состояния:
- `enter_drag_mode()`:
  - `freeze = true`, `freeze_mode = FREEZE_MODE_KINEMATIC`
  - `collision_layer = 0`, `collision_mask = 0`
  - `linear_velocity = Vector2.ZERO`, `angular_velocity = 0.0`
- `exit_drag_mode()`:
  - `collision_layer = 2`, `collision_mask = 1|2`
  - `freeze` остается true до проверки устойчивости

### 4) Shelf/Floor как StaticBody2D
`ShelfSurfaceAdapter` и `FloorZoneAdapter` должны стать “physics‑first”:
- В prefab добавить `StaticBody2D` + `CollisionShape2D` (Layer 1).
- Drop не делает auto‑snap по X, предмет остается в месте отпускания.

### 5) Drop & Stability pipeline (thread-safe)
Все physics queries — только в `_physics_process` специального адаптера.

На drop:
- `WardrobeDragDropAdapter` кладет предмет в очередь `pending_stability_checks`.
- `WardrobePhysicsTickAdapter._physics_process` делает:
  - Raycast вниз от **глобального** CoG, `collision_mask = 1`.
  - Overlap gate: `intersect_shape` по Layer 2, `exclude = [item.get_rid()]`.

Решение:
- Stable (ray hit + нет overlap):
  - минимальный Y‑snap к поверхности,
  - `freeze = true`
- Unstable (нет hit или есть overlap):
  - `freeze = false`
  - `apply_torque_impulse(TORQUE_BASE * mass * sign(overhang))`

Overhang:
- `left_x/right_x` берём из коллизии полки в world space.
- `overhang = cog_x - clamp(cog_x, left_x, right_x)`
- `sign(overhang)` только если `cog_x` вне [left_x, right_x].

### 6) Floor scatter
При drop на пол:
- Добавить небольшой deterministic X offset (hash item_id).
- Clamp offset по границам FloorZone.

### 7) Hooks/Desks: 1 слот = 1 предмет
`WardrobeSlot` остаётся без физики:
- `can_put()` / `put_item()` как сейчас.
- Snap‑to‑center остаётся.
- В слотах предметы всегда `freeze = true`.

### 8) Domino wake‑up + auto‑freeze
Wake‑up (в `ItemNode._on_body_entered`):
- Если удар пришёл от активного тела:
  - `freeze = false`
  - небольшой случайный torque (`randf_range(-2, 2)`)

Auto‑freeze (в `ItemNode._physics_process`):
- Если `|linear|` и `|angular|` ниже порогов > 1s:
  - запросить settle‑check у `WardrobePhysicsTickAdapter`
  - по результату — freeze/torque

### 9) UX feedback during drag
- CoG marker на предмете
- Gravity line вниз от CoG
- Если raycast не видит shelf:
  - красная модуляция
  - лёгкая тряска
  - warning icon над курсором (процедурный `Polygon2D` как placeholder)

### 10) DoD
- SU/interval логика полностью удалена.
- Drag не будит соседей (no collision during drag).
- Drop на shelf/floor:
  - stable → фиксируется
  - unstable → падает, будит соседей
- Авто‑freeze работает (без вечного дрожания).
- Floor scatter остаётся в пределах зоны.
- Hook/Desk слоты работают как раньше.

## RigidBody safety
- Обновлять `global_position`/`global_transform` можно только когда `freeze = true`.
- `PickArea` не отключать и не менять layer во время drag.

## Ссылки (Godot 4.5)
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
- StaticBody2D: https://docs.godotengine.org/en/4.5/classes/class_staticbody2d.html
- PhysicsDirectSpaceState2D.ray query: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html#class-physicsdirectspacestate2d-method-intersect-ray
