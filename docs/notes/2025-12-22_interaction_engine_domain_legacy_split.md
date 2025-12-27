# Разделение interaction_engine.gd на domain и legacy

## Контекст и цель
Нужно разделить текущий `scripts/app/interaction/interaction_engine.gd` на доменную часть (работа с `WardrobeStorageState` и `ItemInstance`) и legacy-часть, которая опирается на Node-уровень (`WardrobeInteractionTarget`, `WardrobeSlot`, `WardrobePlayerController`, `ItemNode`). Это полезно архитектурно (SimulationCore-first), но затрагивает зависимости и потребует правок по проекту.

## Текущее состояние
- `scripts/app/interaction/interaction_engine.gd` содержит два пути:
	- доменный: `process_command(..., StorageState, hand_item)` → `_process_with_storage`, события и валидаторы.
	- legacy: `_process_with_target(...)` работает с `WardrobeInteractionTarget` и Node-логикой.
- На файл завязаны:
	- `scripts/ui/wardrobe_scene.gd` (использует доменный путь + константы события/результата).
	- `scripts/ui/wardrobe_interaction_events.gd` и `scripts/wardrobe/interaction_event_adapter.gd` (константы событий/пейлоадов).
	- `scripts/app/desk/desk_service_point_system.gd` (фильтрация событий через константы).
	- Тесты: `tests/unit/interaction_engine_test.gd`, `tests/unit/interaction_event_adapter_test.gd`, `tests/unit/desk_service_point_system_test.gd`.

## Требования и ограничения
- Доменные правила должны быть чистыми (без `Node`, `SceneTree`, `get_tree()` и т.п.).
- Legacy-путь должен оказаться в adapter-слое (`scripts/wardrobe/**` или `scripts/ui/**`).
- Минимизировать расхождения в контракте: существующие ключи/константы событий лучше оставить стабильными.
- Никаких новых фич в `scripts/sim/**`.

## Архитектурные варианты
1) **Вариант A (рекомендуемый):**
	- Доменный движок остаётся в `scripts/app/interaction/interaction_engine.gd` (или переносится в `scripts/domain/interaction/interaction_engine.gd`).
	- Legacy-движок переносится в `scripts/wardrobe/interaction_engine_legacy.gd` и использует адаптерный API (`WardrobeInteractionTarget`).
	- Общие константы событий и payload выносятся в отдельный файл (например, `scripts/domain/interaction/interaction_event_schema.gd`), чтобы `wardrobe_scene`, `interaction_event_adapter` и `desk_service_point_system` не зависели от legacy.

	Плюсы: чёткое разделение слоёв, меньше риска смешения Node-путей в core.
	Минусы: нужно заменить несколько импортов, обновить тесты/адаптеры.

2) **Вариант B (минимальный дифф):**
	- Оставить доменную часть в текущем файле, а legacy-часть вынести в отдельный `legacy`-класс, но оставить константы в `interaction_engine.gd`.

	Плюсы: меньше правок по константам.
	Минусы: остаётся зависимость адаптеров/систем от app-файла, смешанные слои в одном месте.

## Принятое решение
Выбран вариант A с архитектурной чистотой:
- доменный движок перенесён в `scripts/domain/interaction`;
- схемы событий/результатов выделены в отдельный `interaction_event_schema.gd`;
- legacy-движок вынесен в адаптерный слой `scripts/wardrobe` без `class_name`.

## Дизайн модулей/классов
- `scripts/domain/interaction/interaction_event_schema.gd`
	- `const EVENT_KEY_TYPE`, `EVENT_KEY_PAYLOAD`, `EVENT_ITEM_*`, `EVENT_ACTION_REJECTED`, `PAYLOAD_*`, `RESULT_KEY_*`.
	- Только константы, без логики.
- `scripts/domain/interaction/interaction_engine.gd`
	- `class_name WardrobeInteractionDomainEngine`.
	- Доменный процессинг: `_process_with_storage`, `_execute_pick/put/swap`, `_reject_with_event`.
	- Импортирует `interaction_event_schema.gd` вместо локальных констант.
	- Legacy-путь удалён.
- `scripts/wardrobe/interaction_engine_legacy.gd`
	- Логика `_process_with_target`, опирается на `WardrobeInteractionTarget`.
	- Возвращает результат в том же формате (ключи из schema).
	- Без `class_name`, используется через `preload` при необходимости.

## Зависимости для правок
- Обновить импорты/ссылки на константы в:
	- `scripts/ui/wardrobe_scene.gd`
	- `scripts/ui/wardrobe_interaction_events.gd`
	- `scripts/wardrobe/interaction_event_adapter.gd`
	- `scripts/app/desk/desk_service_point_system.gd`
	- тестах (3 файла)

## Тесты
- Текущие тесты (GdUnit4):
	- `tests/unit/interaction_engine_test.gd`
	- `tests/unit/interaction_event_adapter_test.gd`
	- `tests/unit/desk_service_point_system_test.gd`
- После рефакторинга нужно прогнать как минимум unit-наборы:
	- `./addons/gdUnit4/runtest.sh -a ./tests/unit/interaction_engine_test.gd`
	- `./addons/gdUnit4/runtest.sh -a ./tests/unit/interaction_event_adapter_test.gd`
	- `./addons/gdUnit4/runtest.sh -a ./tests/unit/desk_service_point_system_test.gd`

## Verification
- Прогнаны все три набора GdUnit4 выше; тесты прошли.
- Предупреждения остались прежними (повторяющиеся global class names и сообщение macOS про `get_system_ca_certificates`).
- Дополнительно прогнан полный набор `./addons/gdUnit4/runtest.sh -a ./tests/unit` — 25 тестов, без ошибок.

## Открытые вопросы
- Где хотите закрепить доменную часть: оставить в `scripts/app/interaction/` или перенести в `scripts/domain/interaction/`?
- Нужен ли отдельный файл для схемы событий или допускается оставить константы в доменном движке?
- Legacy-путь (`_process_with_target`) реально используется сейчас или допустимо временно оставить его рядом с UI-адаптером без публичного `class_name`?

## Ссылки
- GDScript: class_name (для устойчивой типизации и глобального имени класса):
	https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_basics.html#class-names
