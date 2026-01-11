# Полный анализ кодовой базы: рефакторинг по чистой архитектуре

## Цель и контекст
- Цель: провести аудит репозитория на предмет рефакторинга с приоритетом чистой архитектуры (SimulationCore-first из `AGENTS.md`).
- Требование: выделить задачи на рефакторинг, ранжировать по важности для архитектурной чистоты.

## Источники
- `AGENTS.md` (слои, запреты, SSOT, команды/события).
- `docs/code_guidelines.md` (typing/preload правила).
- Код: `scripts/domain/**`, `scripts/app/**`, `scripts/wardrobe/**`, `scripts/ui/**`, `scripts/autoload/**`.
- Тесты: `tests/unit/**` (покрытие магии/логов/interaction/desk/queue/shift).

## Ключевые наблюдения (текущие риски архитектуры)
1) **Слабая типизация контрактов через Dictionary** в core и app:
	- `scripts/domain/magic/magic_system.gd`, `scripts/domain/inspection/inspection_system.gd`, `scripts/app/shift/shift_service.gd`, `scripts/app/shift/shift_win_policy.gd`, `scripts/app/interaction/pick_put_swap_resolver.gd`, `scripts/app/logging/shift_log.gd`, `scripts/autoload/bases/content_db_base.gd`.
	- Проблема: ключи строковые без `const StringName`, отсутствует единая схема и валидация payload. Это нарушает правило “Commands payload typing” и ухудшает статический анализ.

2) **Отсутствуют preload для некоторых классов-коллабораторов** (риск headless/check-only):
	- `scripts/domain/magic/magic_system.gd` использует `RunState`.
	- `scripts/domain/inspection/inspection_system.gd` использует `RunState`.
	- `scripts/domain/storage/wardrobe_storage_state.gd` использует `ItemInstance`.
	- `scripts/domain/interaction/interaction_engine.gd` использует `WardrobeStorageState`, `ItemInstance`, `InteractionResult`.
	- `scripts/autoload/bases/content_db_base.gd` использует `ContentDefinition`.
	- Это противоржит правилам `docs/code_guidelines.md` (preload коллабораторов).

3) **ContentDefinition находится в domain и `extends Resource`**:
	- `scripts/domain/content/content_definition.gd` — Resource в domain-слое.
	- По правилам: `domain/**` допускает `RefCounted`, а Resources обычно принадлежат контенту/инфраструктуре. Это спорная зона: definition-объекты логически относятся к инфраструктуре/контенту, не к runtime state.

4) **Строковые константы вместо известной схемы**:
	- `ShiftService` строит HUD/summary через строки (`"money"`, `"notes"`, `"progress"` и т.д.).
	- `MagicSystem` и `InspectionSystem` используют строковые ключи для config и событий (`"insurance_mode"`, `"inspection_mode"`).
	- `PickPutSwapResolver` возвращает строковые статусы и причины, которые далее маппятся на StringName.
	- Это увеличивает количество неявных контрактов между слоями и мешает расширяемости.

5) **Частично нестротая типизация публичных API**:
	- Примеры: `RunState.set_magic_links(item_ids: Array)`, `ShiftService.configure_patience_clients(client_ids: Array)`, `MagicSystem.apply_insurance(..., item_ids: Array)`.
	- В публичных API и state-объектах требуется статическая типизация (`Array[StringName]`, `Array[Dictionary]` и т.п.).

## Приоритетные задачи рефакторинга (архитектурная чистота)

### P0 — Критично для чистой архитектуры (устранить сейчас)
1) **Ввести строгие схемы ключей и типизированные DTO для core/app**.
	- Заменить свободные ключи в `MagicSystem`, `InspectionSystem`, `ShiftService`, `ShiftWinPolicy`, `PickPutSwapResolver`, `ShiftLog`.
	- Варианты:
		- Value-объекты `RefCounted` для результатов (например, `MagicEvent`, `InspectionReport`, `ShiftHudSnapshot`).
		- Либо `const StringName` ключи в отдельном schema файле + валидаторы.
2) **Добавить preload для всех коллабораторов в core/app** (по `docs/code_guidelines.md`).
3) **Уточнить слой для ContentDefinition**:
	- Вариант А: перенести в `scripts/autoload/content/` или `scripts/content/`.
	- Вариант Б: заменить `Resource` на `RefCounted`, если definition используется в runtime (но тогда убрать @export).

### P1 — Важно для надежности контрактов
4) **Стандартизировать типы идентификаторов** (StringName vs String).
	- Идентификаторы сущностей — только `StringName` (особенно в домене и app).
5) **Стабилизировать конфиги систем** (`MagicSystem`, `InspectionSystem`, `ShiftService`) через явные config-объекты.
	- Исключить `"key"` строки в config словарях; применить строгую типизацию.

### P2 — Улучшения поддерживаемости
6) **Уточнить типизацию коллекций в публичных методах**.
7) **Локализовать “неявные строки” для HUD/summary** — либо schema, либо DTO, чтобы UI не зависел от магии ключей.

## Тесты и покрытие (что затронется)
- Затронутые тесты:
	- `tests/unit/magic_system_test.gd`
	- `tests/unit/shift_log_test.gd`
	- `tests/unit/shift_service_win_test.gd`
	- `tests/unit/pick_put_swap_resolver_test.gd`
	- `tests/unit/shift_win_policy_test.gd`
	- `tests/unit/desk_reject_outcome_system_test.gd`
	- `tests/unit/interaction_engine_test.gd`
- Потребуются новые/обновленные тесты при введении DTO/schemas.

## Варианты целевого дизайна (архитектура)
1) **DTO-first**: в `domain/app` вводятся `RefCounted` value-объекты:
	- `MagicEvent`, `InspectionReport`, `ShiftHudSnapshot`, `ShiftSummary`, `ResolverResult`.
	- UI получает типы, не словари.
2) **Schema-first**: отдельные `*Schema.gd` файлы с `const StringName` ключами + валидаторы.
	- Быстрее внедрить, меньше каскадных изменений.
	- Более высокий риск “словари на границах”.
3) **Гибрид**: DTO для крупных контрактов (Shift/HUD, Magic/Inspection), schema для мелких (локальные события).

## Открытые вопросы (нужны уточнения)
- Где предпочтительно размещать content definitions: `scripts/domain/content` или `scripts/autoload/content`?
- Предпочтителен ли подход DTO-first или schema-first для ближайшего рефакторинга?
- Какие подсистемы критичнее для ближайшей итерации (magic/inspection/shift/hud vs interaction)?

## Ссылки на оф. документацию (Godot 4.5)
- `StringName`: https://docs.godotengine.org/en/4.5/classes/class_stringname.html
- `RefCounted`: https://docs.godotengine.org/en/4.5/classes/class_refcounted.html
- `Resource`: https://docs.godotengine.org/en/4.5/classes/class_resource.html
- `Dictionary`: https://docs.godotengine.org/en/4.5/classes/class_dictionary.html
- `JSON`: https://docs.godotengine.org/en/4.5/classes/class_json.html
