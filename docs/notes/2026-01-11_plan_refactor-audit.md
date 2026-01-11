# План рефакторинга (приоритет по чистой архитектуре)

## Цель
Укрепить SimulationCore-first: убрать неявные словарные контракты, усилить типизацию и границы слоев, обеспечить пригодность к headless/CI проверкам.

## Приоритетный план (P0 → P2)

### P0 — Архитектурные блокеры
1) **Схемы ключей и типизация результата в core/app**.
	- Ввести schema/DTO для:
		- `MagicSystem` (event/result).
		- `InspectionSystem` (report).
		- `ShiftService` (HUD snapshot, summary).
		- `PickPutSwapResolver` (result).
		- `ShiftLog` (event entry).
	- Обновить вызовы и тесты.
2) **Preload коллабораторов в core/app** (согласно `docs/code_guidelines.md`).
	- Добавить preload для классов в:
		- `scripts/domain/magic/magic_system.gd`
		- `scripts/domain/inspection/inspection_system.gd`
		- `scripts/domain/storage/wardrobe_storage_state.gd`
		- `scripts/domain/interaction/interaction_engine.gd`
		- `scripts/autoload/bases/content_db_base.gd`
3) **Решить судьбу ContentDefinition (layering)**.
	- Вариант A: переместить в `scripts/autoload/content/` или `scripts/content/`.
	- Вариант B: перевести на `RefCounted` и убрать `@export`, если definition — runtime DTO.

### P1 — Укрепление контрактов
4) **Унифицировать идентификаторы**.
	- В app/domain/API использовать `StringName` для id/типов.
5) **Типизировать конфиги** `MagicSystem`/`InspectionSystem`/`ShiftService`.
	- Ввести config-объекты или schema с `const StringName`.

### P2 — Поддерживаемость
6) **Типизация коллекций в публичных API** (Array[StringName], Array[Dictionary] и т.д.).
7) **Централизовать ключи HUD/summary** (schema или DTO).

## Детализация реализации (предложение порядка)
1) **Schema-first быстрый проход**:
	- Создать `scripts/domain/*_schema.gd` для Magic/Inspection/Shift/HUD.
	- Заменить строковые ключи на `const StringName`.
	- Обновить тесты.
2) **DTO для крупных контрактов**:
	- `ShiftHudSnapshot`, `ShiftSummary`, `MagicEvent`, `InspectionReport`.
	- Убрать Dictionary из публичных API.
3) **Точечная миграция ContentDefinition**:
	- Определить целевой слой и мигрировать `ContentDBBase` на него.
4) **Полировка типизации публичных API**:
	- Пройтись по `scripts/domain/**` и `scripts/app/**` на предмет `Array`/`Dictionary` без типов.

## Тесты (после внедрения изменений)
- Канонический запуск:
	- `GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests`
	- `"$GODOT_BIN" --path .`
- Потребуется обновить unit-тесты:
	- `tests/unit/magic_system_test.gd`
	- `tests/unit/shift_log_test.gd`
	- `tests/unit/shift_service_win_test.gd`
	- `tests/unit/pick_put_swap_resolver_test.gd`
	- `tests/unit/shift_win_policy_test.gd`
	- `tests/unit/interaction_engine_test.gd`

## Риски
- Изменение словарных контрактов затронет большое число тестов и адаптеров.
- Перемещение `ContentDefinition` может затронуть автозагрузки и сериализацию контента.

## Запросы на уточнение
- Подтвердите целевой подход: schema-first или DTO-first?
- В какой папке должны жить content definitions?
- Начать с P0 пунктов 1-2 (схемы + preload), или включить ContentDefinition сразу?
