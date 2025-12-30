# 2025-12-30 — Physics placement gate + terminal reject (рефакторинг)

## Контекст
- Опирался на `docs/notes/2025-12-30_physics-placement-gate-terminal-reject.md` и реализовал ключевые пункты R1/R5/R2/R2.5 в виде небольших, но согласованных правок.

## Что изменено
- Введён SSOT для слоёв/масок/групп (`WardrobePhysicsLayers`) и выровнены runtime-настройки слоёв у item/shelf/floor.
- В `ItemNode` собран единый Geometry API (AABB, bottom Y, snap), а pass-through переведён на floor-only mask.
- Добавлен `SurfaceRegistry` (autoload) для выбора пола по `surface_y` без group-scan в горячих путях.
- Выделен `PhysicsPlacementGate` для принятия решения по overlap (ALLOW/ALLOW_NUDGE/REJECT).
- Терминальный REJECT реализован как pass-through fall до пола, с блокировкой повторных overlap-решений до восстановления коллизий.

## Ключевые решения
- Оставили текущие индексы слоёв (shelf=1, item=2, pick=3), добавив отдельный floor=4.
- Small overlap → нудж только активного предмета; соседей больше не двигаем импульсами (stable immunity).
- Floor drop/pass-through использует bottom_y для согласованного восстановления коллизий.

## Тесты
- Добавлены интеграционные тесты для проверки контрактов слоёв и Geometry API.

## Ссылки (Godot 4.5)
- Collision layers/masks: https://docs.godotengine.org/en/4.5/tutorials/physics/physics_introduction.html#collision-layers-and-masks
- PhysicsDirectSpaceState2D: https://docs.godotengine.org/en/4.5/classes/class_physicsdirectspacestate2d.html
- PhysicsShapeQueryParameters2D: https://docs.godotengine.org/en/4.5/classes/class_physicsshapequeryparameters2d.html
- RigidBody2D: https://docs.godotengine.org/en/4.5/classes/class_rigidbody2d.html
