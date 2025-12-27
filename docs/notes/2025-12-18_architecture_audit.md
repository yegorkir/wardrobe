# Архитектурный аудит (соответствие AGENTS.md)

## Цель и контекст
- Проверить, насколько текущая реализация следует принципам SimulationCore-first и слоям из `AGENTS.md` (доменные правила вне сцен, команды → ядро → доменные события, отсутствуют Node-зависимости в core).
- Итог: зафиксировать расхождения, предложить целевой дизайн и план миграции.

## Источники
- `AGENTS.md` (архитектурные правила, слои, запреты на Node/SceneTree в core).
- Код: `scripts/autoload/bases/run_manager_base.gd`, `scripts/ui/wardrobe_scene.gd`, `scripts/wardrobe/*.gd`, `scripts/app/**`, `scripts/domain/**`.
- Тесты: `tests/unit/*`, `tests/functional/*` (регрессии и опоры для будущих проверок).

## Наблюдения по текущей архитектуре
- **SimulationCore отсутствует**: все игровые операции (pick/put/swap, выдача заказов, метрики) выполняются прямо в `scripts/ui/wardrobe_scene.gd` и `scripts/wardrobe/*.gd` на уровне `Node2D`/`CharacterBody2D`. Состояние предметов хранится в `ItemNode`/`WardrobeSlot`, а не в доменных стейтах.
- **Автозагрузка содержит логику с состоянием**: `scripts/autoload/bases/run_manager_base.gd` держит `run_state` как `Dictionary`, обрабатывает магию/инспекцию и управляет HUD. По правилам автолоады — инфраструктура, без симуляционных правил; сейчас они смешаны.
- **Команды/события не являются источником истины**: `WardrobeInteractionCommand` генерируется, но дальше UI сразу модифицирует сцены, не формируя доменных событий и не обновляя ShiftLog как единственный источник объяснимости.
- **Данные и состояние смешаны с узлами**: предметы/тикеты — `Node2D` с полями (`durability`, `ticket_number`), слоты — `Node2D` с фактами размещения; нет `RefCounted` стейтов типа `WardrobeStorageState`, `ItemInstance`, `TicketLedgerState`. Это нарушает правило «Runtime state только в RefCounted, без SceneTree».
- **ContentDB грузит JSON на старте сцены** и отдаёт сырые словари. Текущие системы не превращают их в Resources/definition-объекты и не кэшируют в core-стейтах, поэтому UI зависит от структуры JSON.
- **Взаимодействия привязаны к SceneTree**: поиск слотов через группы (`get_nodes_in_group`), выбор лучшего слота по расстоянию/направлению выполняется в UI и возвращает Nodes. По правилам, UI должен собирать команду, а проверка допустимости/выбор цели должны жить в core (slot-first проверки, правила света/проксимити и т.д.).

### Подробные несоответствия (кодовые ссылки)
- `scripts/ui/wardrobe_scene.gd` — `_perform_interact` строит команду, но тут же вызывает `WardrobeInteractionEngine` с `WardrobeInteractionTarget`, который оперирует `WardrobeSlot`/`ItemNode` (`Node`). Результат сразу отражается на сценах, без доменных стейтов и без событий в общий ShiftLog (нарушает «Commands in / Events out», «core без SceneTree»).
- `scripts/wardrobe/slot.gd`, `scripts/wardrobe/item_node.gd` — runtime-состояние (занятость слота, `item_id`, `durability`) хранится в `Node2D`; стейт доступен извне без инвариантов. AGENTS требует RefCounted-стейты и защиту коллекций.
- `scripts/wardrobe/interaction_target.gd` — операции pick/put/swap обращаются к `player` (`CharacterBody2D`) и `WardrobeSlot`, то есть «core» зависит от SceneTree и конкретных узлов, нет доменной модели хранилища.
- `scripts/app/interaction/interaction_engine.gd` — принимает адаптер `WardrobeInteractionTarget`, резолвит действие через наличие `Node`-состояния и не формирует доменных событий; ShiftLog не используется.
- `scripts/autoload/bases/run_manager_base.gd` — автолоад хранит `run_state` как `Dictionary`, применяет магию/инспекцию и управляет HUD/экраном. Смешение инфраструктуры и симуляционных правил (AGENTS: автолоды тонкие, без core-логики).
- `scripts/autoload/bases/content_db_base.gd` — JSON парсится при старте узла, выдаются сырые словари; definitions не становятся Resources/definition-объектами и не кэшируются для core.
- Тесты: `tests/functional/wardrobe_scene_test.gd` проверяет HUD/seed через SceneTree; `tests/unit/interaction_engine_test.gd` тестирует взаимодействие на моках `Node`, отсутствуют unit-тесты на чистые доменные стейты и ShiftLog-first поведение.

## Вывод о соответствии
- Ключевые принципы SimulationCore-first нарушены: правила и состояние живут в сценах/автозагрузках, нет доменных стейтов и событий, отсутствует слой app/domain, управляющий геймплеем независимо от Godot-узлов. Текущий код ближе к «UI как логика».

## Целевой дизайн (solution / system design)
- **Слои**:
	- `domain/` — чистые типы/стейты (`RunState`, `WardrobeStorageState`, `TicketLedgerState`, `ItemInstance`, `ClientState`), правила магии/инспекции/спец-правил (RefCounted, без Node/SceneTree).
	- `app/` — сценарии и оркестраторы (`InteractionEngine`, `PlacementSystem`, `ShiftService`), работающие только с доменными стейтами и контент-определениями, исполняющие команды и отдающие доменные события в `ShiftLog`.
	- `wardrobe/ui/` — адаптеры: читают ввод/сцены, строят команды, подписываются на события, отображают стейты и визуализируют последствия (VFX/SFX).
	- `autoload/` — инфраструктура: загрузка контента, сохранения, маршрутизация экранов. Никаких геймплейных правил; только вызовы к app/core.
- **Командная шина**: все действия пользователя (`pick/put/swap`, завершающий выдачу тикета, магия) → `InteractionCommand` → `InteractionEngine` в `app/` → обновление доменных стейтов → события в `ShiftLog`. UI подписывается на события через адаптер-переводчик (единственный узел, который превращает доменные события в Godot-сигналы/анимации).
- **Состояние хранения**: `WardrobeStorageState` владеет слотами/предметами (ID/refs на definition), операции `place`, `take`, `swap` применяют инварианты (проверки занятости, правила света/близости). Никаких прямых `Node` в стейте.
- **Контент**: `ContentDB` парсит JSON один раз, строит definition-объекты (Resources), отдаёт их core; UI получает только снимки/DTO из app. Источник истины — definitions + стейт, не SceneTree.
- **ShiftLog как единственный источник объяснимости**: каждый эффект (штраф, decay, отказ действия) логируется как событие с контекстом. Экран Summary строится из событий/снимков стейта, а не из свойств UI.
- **Автозагрузки как инфраструктура**: `RunManager` должен стать тонким маршрутизатором (экраны, старт/стоп смены, связь с SaveManager/ContentDB), держащим ссылку на `SimulationCore`/`ShiftService`, но не изменяющим стейт напрямую.

## Дизайн модулей/классов (предложение)
- `scripts/domain/storage/wardrobe_storage_state.gd`: RefCounted, хранит слоты (id→SlotState), предметы (id→ItemInstance), методы `pick/put/swap`, проверки блокировок (свет, занятость).
- `scripts/domain/run/run_state.gd`: RefCounted агрегат смены (деньги, магия, долг, волны, энтропия, ссылки на стейты хранилища/клиентов).
- `scripts/app/interaction/interaction_engine.gd`: принимает `InteractionCommand`, `WardrobeStorageState`, `TicketLedgerState`, возвращает `InteractionResult` + доменные события (`ItemMoved`, `ActionRejected{reason}`).
- `scripts/app/shift/shift_service.gd`: управляет сменой/волнами, дергает `MagicSystem`/`InspectionSystem`, пишет в `ShiftLog`.
- `scripts/ui/wardrobe_scene.gd` (адаптер): на ввод строит `InteractionCommand`, отправляет в `InteractionEngine`, применяет визуальные эффекты по событиям, читает только snapshot стейтов/логов (не модифицирует core).
- `autoload/RunManager`: держит `ShiftService` и `ShiftLog`, маршрутизирует экраны, запрашивает сохранения/загрузки.

## Риски и тесты
- **Регрессия интеракций**: функциональные тесты `tests/functional/wardrobe_scene_test.gd` завязаны на SceneTree. Потребуются unit-тесты для нового core (`WardrobeStorageState`, `InteractionEngine`) + адаптерные тесты для UI.
- **Сохранения**: при переносе стейта в RefCounted потребуется сериализация/десериализация стейтов (связка с SaveManager).
- **Контент**: переход на definition-Resources потребует миграции загрузки JSON и кэширования.

## План дальнейшей реализации
1) **Ввести доменные стейты и инварианты**: создать `scripts/domain/storage/wardrobe_storage_state.gd`, `scripts/domain/run/run_state.gd`, `scripts/domain/tickets/ticket_ledger_state.gd` (или аналог) и перенести туда операции pick/put/swap + ограничения. Покрыть unit-тестами (`tests/unit/domain/wardrobe_storage_state_test.gd` и др.).
2) **Пересобрать interaction flow**: обновить `scripts/app/interaction/interaction_engine.gd` под доменные стейты и DTO-команды, возвращать доменные события (`ItemMoved`, `ActionRejected{reason}`) в `scripts/app/logging/shift_log.gd`. Добавить адаптер-конвертер доменных событий → Godot-сигналы и тесты (`tests/unit/interaction_engine_test.gd`).
3) **Адаптер UI**: переписать `scripts/ui/wardrobe_scene.gd` и `scripts/wardrobe/*.gd` в роль презентации: сбор команд из ввода, подписка на события, отображение снапшотов стейта. Убрать хранение предметов/слотов в Nodes, держать только визуальные инстансы.
4) **Автолоады = инфраструктура**: облегчить `scripts/autoload/bases/run_manager_base.gd` до маршрутизатора экранов и владельца SimulationCore/`ShiftService` (новый `scripts/app/shift/shift_service.gd`), без прямых правок стейта. Добавить unit-тесты на сервисный слой.
5) **Контент как definitions**: расширить `scripts/autoload/content_db.gd`/`content_db_base.gd` для построения Resources (`ItemDefinition`, `ArchetypeDefinition`, т.п.) один раз; кешировать и отдавать core. Добавить тест на парсинг/кеш.
6) **ShiftLog-first summary**: обновить `scripts/ui/shift_summary.gd` (и связанные DTO) для сборки итогов из ShiftLog/стейтов core, не из HUD-меток. Добавить unit-тест на сбор summary.
7) **Функциональные проверки**: переписать `tests/functional/wardrobe_scene_test.gd` под новый флоу (команды/события), добавить smoke-тесты адаптеров и e2e на выдачу заказа, опираясь на доменный стейт вместо SceneTree.

### Ближайшая итерация рефакторинга (детальнее)
1) Интеграция `InteractionEngine` с `WardrobeStorageState`: принять доменные команды, оперировать `ItemInstance`, возвращать доменные события (`ItemPlaced`, `ItemPicked`, `ActionRejected{reason}`) без Node. Добавить снапшот API для UI адаптеров.
2) Адаптер событий → сигналы: создать единственный переводчик доменных событий в Godot-сигналы/анимации; обновить `scripts/ui/wardrobe_scene.gd` на работу со снапшотами стейта и событиями, убрать доступ к `WardrobeSlot`/`ItemNode` как источнику истины.
3) Тесты: обновить/дополнить `tests/unit/interaction_engine_test.gd` под доменный стейт, добавить unit-тесты на event-поток, подготовить черновик функционального теста нового флоу (сценарий pick/put/swap через команды).

### Прогресс итерации 1 (domain InteractionEngine)
- `WardrobeInteractionEngine.process_command` теперь принимает `WardrobeStorageState` + `ItemInstance` руки и возвращает доменные события `item_picked`/`item_placed`/`item_swapped` или `action_rejected` с `tick` команды и снапшотами предметов/слотов.
- Валидация payload по ожидаемым `hand_item_id`/`slot_item_id` останавливает действие без мутации стейта, записывая отказ в событии (`reason` + `slot_id`).
- Legacy-путь через `WardrobeInteractionTarget` сохранён как временный адаптер для UI и помечен к миграции.
- Unit-тесты `tests/unit/interaction_engine_test.gd` переписаны на доменный API и покрывают события, смену руки/слота и отсутствие мутаций при ошибках.

### Прогресс итерации 2 (event→signal + UI адаптер)
- Добавлен `WardrobeInteractionEventAdapter` (RefCounted) — преобразует доменные события взаимодействий (`item_picked`/`item_placed`/`item_swapped`/`action_rejected`) в сигналы адаптера; покрыт unit-тестом `tests/unit/interaction_event_adapter_test.gd`.
- `scripts/ui/wardrobe_scene.gd` переведён на доменный стейт: создаёт/очищает `WardrobeStorageState`, регистрирует слоты, строит `ItemInstance` для seed/тикетов, отправляет команды через `InteractionEngine` с хранением `hand_item_instance`.
- Визуальное состояние теперь обновляется по сигналам адаптера: события pick/put/swap перемещают `ItemNode` между слотом и рукой игрока синхронно с доменной мутацией (с сохранением словаря `item_id → ItemNode`).
- Seed/тикеты и доставка заказов синхронизированы с доменным стейтом (`put`/`pick`), чтобы SceneTree больше не был источником истины.

### Прогресс итерации 3 (ShiftService/ContentDB → definitions)
- `RunManagerBase` стал тонким маршрутизатором: вся логика смены вынесена в `scripts/app/shift/shift_service.gd` (RefCounted), автолоад только создаёт сервис, роутит экраны и транслирует HUD/summary сигналы.
- `ShiftService` владеет состоянием смены (`_run_state`, HUD snapshot), конфигурирует Magic/Inspection systems, сохраняет мета через SaveManager и возвращает summary без Node-зависимостей.
- `ContentDBBase` теперь грузит JSON в `ContentDefinition` (Resource с `id + payload`), возвращает снапшоты и семена из definition payload вместо сырых Variant.
- Глобальные классы пересозданы через headless editor-run для корректной регистрации class_name после выделения сервиса/definitions.
