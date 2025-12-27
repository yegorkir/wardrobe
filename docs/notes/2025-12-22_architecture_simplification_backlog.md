# Анализ сложности кода и приоритетный бэклог упрощений (2025-12-22)

## Контекст
- Задача: определить, что в коде слишком сложно и может быть упрощено.
- Фокус приоритета: чистота архитектуры (SimulationCore-first).
- Область: весь репозиторий, только код.

## Краткий вывод
Главный источник сложности — концентрация оркестрации, состояния и визуальной логики в `scripts/ui/wardrobe_scene.gd`. Это тянет за собой слишком широкие интерфейсы адаптеров, множественные словарные контракты и смешение ответственности между `scripts/app/**`, `scripts/domain/**` и UI-слоем.

## Наблюдения по сложности (точки риска)
- `scripts/ui/wardrobe_scene.gd`: один класс одновременно держит ввод, поиск сценовых нод, storage-состояние, обработку доменных событий, работу с desk-логикой, спавн/перемещение item-нод, диагностику целостности и т.п. Это нарушает разделение “Commands in / Events out”.
- `scripts/ui/wardrobe_step3_setup.gd`: адаптер с длинным списком зависимостей и `Callable`, что указывает на скрытый “God Object” в сцене.
- `scripts/ui/wardrobe_interaction_events.gd`: одновременно инициирует доменные события desk-системы и применяет их к UI (двойная ответственность).
- `scripts/domain/interaction/interaction_engine.gd` + `scripts/app/interaction/pick_put_swap_resolver.gd`: логика сборки/исполнения команд держится на разрозненных словарных ключах и строковых значениях действий.
- `scripts/app/desk/desk_service_point_system.gd`: доменная система напрямую мутирует `WardrobeStorageState`, при этом UI-адаптер тоже содержит логику спавна/удаления нод; граница между “события” и “визуализация” размыта.
- `scripts/app/shift/shift_service.gd`: `run_state` и многие протоколы основаны на `Dictionary`, что усложняет контракты и статический анализ.

## Архитектурные предложения (целевое состояние)

### 1) Четкое разделение SimulationCore и адаптеров
**Цель:** оставить в UI только сбор команд и применение событий. Логику взаимодействий и состояния переместить в `scripts/app/**` + `scripts/domain/**`.

**Предлагаемые модули:**
- `scripts/domain/interaction/interaction_command.gd` (уже есть) → расширить до типизированного объекта или строгого DTO.
- `scripts/domain/interaction/interaction_result.gd` (новый): `success`, `reason`, `action`, `events`, `hand_item`.
- `scripts/app/interaction/interaction_service.gd` (новый): оркестрация `WardrobeStorageState`, `PickPutSwapResolver`, `WardrobeInteractionDomainEngine`.
- `scripts/app/desk/desk_service_point_system.gd`: оставить только доменную логику; события наружу — список доменных событий.
- `scripts/wardrobe/` и `scripts/ui/`: единый адаптер, который переводит события в UI (Node/Visuals), без мутаций доменного состояния.

### 2) Сведение словарных контрактов к одному месту
**Цель:** минимизировать свободные словари и строковые ключи в UI.

**Варианты:**
- Ввести value-объекты (`RefCounted`) для команд/событий/результатов, и выдавать их наружу как типы, а не словари.
- Если остаются `Dictionary`, то сделать единый модуль “схема событий” (как `interaction_event_schema.gd`) и не дублировать ключи в системах.

### 3) Уменьшить количество зависимостей адаптеров
**Цель:** заменить длинные списки аргументов адаптеров на контекст-объекты и узкие интерфейсы.

**Предложение:**
- Создать `WardrobeSceneContext` (RefCounted), который содержит ссылки на ключевые состояния и сервисы.
- Адаптеры получают `context` и минимальный набор `Callable` для UI-специфики.

### 4) Явные состояния вместо `Dictionary`
**Цель:** устранить размытые контракты в `ShiftService`/`MagicSystem`/`InspectionSystem`.

**Предложение:**
- Ввести `RunState` (RefCounted) в `scripts/domain/run/run_state.gd` с явными полями.
- Обновить `MagicSystem`/`InspectionSystem` так, чтобы они работали с `RunState` вместо `Dictionary`.

### 5) Уточнение границ событий Desk-логики
**Цель:** desk-система должна выдавать доменные события, UI только применяет визуальные эффекты.

**Предложение:**
- Ввести `DeskEventSchema` или типизированные события.
- `WardrobeInteractionEventsAdapter` разделить на:
  - `DeskEventDispatcher` (вызывает доменную систему и возвращает события).
  - `DeskEventPresenter` (применяет события к Node-слою).

## Приоритетный бэклог упрощений (архитектурная чистота)

### P0 — Архитектурные границы
1) **Разделить WardrobeScene на “UI-адаптер” и “InteractionService”.**
   - Move: `_interaction_engine`, `_storage_state`, `_hand_item_instance`, `_interaction_tick` → `scripts/app/interaction/interaction_service.gd`.
   - В UI оставить: выбор ближайшего слота, построение команд, применение визуальных событий.

2) **Создать явный результат взаимодействия (`InteractionResult`).**
   - Убрать сырой `Dictionary` из `WardrobeInteractionDomainEngine` и связанного кода.

3) **Разделить desk-события на доменную обработку и UI-презентацию.**
   - `WardrobeInteractionEventsAdapter` → два класса (dispatcher/presenter).

### P1 — Упрощение контрактов
4) **Заменить `run_state` словарь на `RunState` объект.**
   - Обновить `ShiftService`, `MagicSystem`, `InspectionSystem`.

5) **Свести схемы событий к одному модулю.**
   - Не дублировать ключи в разных системах; единый schema-файл или value-объекты.

6) **Сократить количество параметров в `WardrobeStep3SetupAdapter` через context.**
   - Упрощает подключение и тестируемость.

### P2 — Улучшение читаемости
7) **Стандартизировать идентификаторы (StringName vs String).**
   - Минимизировать `str(...)`/`StringName(...)` в UI.

8) **Отделить debug-проверки целостности мира.**
   - `_validate_world()` перевести в отдельный debug-сервис или запускать только в debug-режиме.

## Модульный план (если реализовывать)
- `scripts/app/interaction/interaction_service.gd` — основной сценарий взаимодействий (сервис).
- `scripts/domain/interaction/interaction_result.gd` — типизированный результат.
- `scripts/domain/run/run_state.gd` — единый run state.
- `scripts/ui/wardrobe_scene.gd` — оставить input + визуальный слой.
- `scripts/ui/wardrobe_interaction_events.gd` — разделить на dispatcher/presenter.
- `scripts/ui/wardrobe_step3_setup.gd` — перевести на `context`.

## Тесты (для будущей реализации)
- В проекте есть `tests/unit/**` и `tests/functional/**` (GdUnit4). При реализации P0/P1 нужно будет обновить соответствующие unit-тесты, особенно `tests/unit/interaction_engine_test.gd` и `tests/unit/desk_service_point_system_test.gd`.
