Step 6.1 — Floor transfer без one-way + единые логи + LandingBehavior/LandingOutcome
Role

Ты — deterministic repo agent. Работаешь в Godot 4.x GDScript репозитории. Строго следуй правилам из AGENTS.md и tests/AGENTS.md.

Hard constraints

GDScript форматирование как в репо (табуляции).

Держи границы слоёв: Godot-узлы/физика = UI/infra; правила = domain/app (Node-free где возможно).

Логи должны включаться/выключаться одним глобальным bool и не делать тяжёлое форматирование когда выключены.

Обязательно после изменений:

GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests

затем "$GODOT_BIN" --path .

Добавляй заметки в docs/notes/ с префиксом даты 2026-01-10_*.

Контекст файлов

wardrobe_actual.txt — весь проект

wardrobe_diff.txt — изменения текущего шага 6.1

logs_actual_1.txt, logs_actual_2.txt — кейсы “тикет улетает вниз” и “шляпа улетает вниз, но логов ‘как у тикета’ нет”

Цель (Definition of Done)

К концу:

Variant C: Пол/поверхности НЕ используют one_way_collision. “Вверх через пол” решается через временное переключение collision-профиля у предмета (phase RISE), а приземление на пол надёжное (после завершения transfer предмет не продолжает проваливаться).

Variant D: Единая наблюдаемость — и “drop/transfer”, и “предмет сбили/сам упал” дают одинаково понятные события логов. Включение логов — один bool.

Future-ready: При стабилизации предмета на поверхности эмитится доменно/апповое событие ItemLanded, которое обрабатывается через LandingBehavior (strategy) по item_kind, возвращает LandingOutcome, и UI применяет outcome (например BOUNCE/BREAK). Рейтингов/quality сейчас НЕ реализуем, но контракт outcome заранее допускает future поля (quality_delta, entropy_delta).

Non-goals:

Не делать UI-контроллер логов/фильтры/оверлеи (только toggle + структурированные записи).

Не строить полноценную систему рейтингов/штрафов сейчас.

Не делать глубокий ребаланс.

Step 0 — Прочитать доки/код и зафиксировать инварианты

Прочитать:

AGENTS.md

tests/AGENTS.md

docs/notes/2025-12-30_physics-placement-gate-terminal-reject.md

docs/notes/2026-01-02_plan_drag-drop-floor-fallback.md

docs/notes/2026-01-02_drag-release-logging.md

docs/notes/2026-01-02_plan_surface_collision_y.md

описание шага 6.1 в docs/ (найди по репо)

Осмотреть текущие реализации (имена могут чуть отличаться — следуй факту в репо):

FloorZoneAdapter / SurfaceAdapter (где выставляется one-way)

ItemNode (transfer FSM)

WardrobePhysicsTickAdapter (stable/snap pipeline)

WardrobeDragDropAdapter (floor pick + target y)

config слоёв/масок (SSOT)

Создать заметку:

docs/notes/2026-01-10_plan_step_6_1_no_one_way_landing_behavior.md
В ней: инварианты, схема фаз transfer, что считается “landing”, структура события, критерии приёма.

Step 1 — Variant D foundation: один toggle + структурированный debug logger

Требования:

Один глобальный bool включает/выключает все дебаг-логи.

Когда выключено — ранний return до сборки строк/словарей.

Сделать:

Добавить конфиг-флаг (1 bool), например:

scripts/wardrobe/config/debug_flags.gd (или аналогично по стилю репо)

Добавить утилиту логирования:

scripts/wardrobe/debug/debug_log.gd (или аналогично)
Функции:

enabled()

log(line: String)

event(event_type: StringName, payload: Dictionary) — одна строка, минимум шума.

Привести все существующие debug-печати в ключевых местах к этой утилите:

ItemNode transfer

Drag/drop решение

PhysicsTick stable

hit/wake (если есть)

Результат: лог “шляпа упала” должен быть виден так же, как “тикет упал”, пусть и с другим cause.

Step 2 — Variant C: убрать one-way у пола и сделать “вверх через пол” collision-профилями

Проблема: one-way + погрешности target_y/plane дают ситуации, когда после transfer_end предмет всё ещё падает (проваливается через пол).

Сделать:

Убрать one_way_collision у пола/поверхностей, которые являются “полом” (floor surface).

Ввести/использовать два (или три) collision-профиля у предмета на время transfer:

TRANSFER_RISE: НЕ коллайдится с FLOOR (и, как правило, не коллайдится с ITEM/SHELF), движение детерминированное.

TRANSFER_FALL: коллайдится с FLOOR (минимально, чтобы landing был терминальным), по желанию всё ещё игнорирует ITEM/SHELF.

NORMAL: нормальный режим после settle.

Контракт фаз transfer:

Если нужен подъём (“вверх через пол”), сначала RISE (floor collisions OFF).

Переключение RISE→FALL только когда предмет гарантированно выше плоскости пола:

условие через item_bottom_y и floor_collision_top_y + epsilon (1–3px)

перед включением FLOOR коллизии — снэпнуть в безопасную позицию (не внутри коллайдера)

FALL: включить FLOOR коллизию, вернуть гравитацию/скорости, довести до посадки.

LAND/SETTLE: нулевая скорость + freeze/snap через стабильный пайплайн (желательно через PhysicsTick), чтобы после завершения предмет не продолжал падать.

Target Y должен быть collision-истинным:

для пола брать “верх collision shape”, а не визуальный y/маркеры.

Добавить аварийную сетку (минимальную):

если после включения FLOOR коллизии предмет продолжает уходить ниже плоскости > N кадров → срабатывает failsafe (snap/freeze + debug event).

Step 3 — Единая точка “landing”: одинаково для transfer и для пассивного падения

Требование:

“drop на пол” и “сбили предмет с полки” должны проходить через одинаковую концепцию “стал stable на поверхности” и порождать:

debug event ITEM_LANDED

app event EVENT_ITEM_LANDED (payload)

Сделать:

Найти единую точку, где предмет признаётся stable (обычно PhysicsTick после raycast/snap).

В этой точке:

логировать ITEM_LANDED (если toggle включен)

вызывать обработчик в app слое (см. Step 4), получать outcome и применять его.

Важно:

обеспечить, что “пассивно упавшие” (ударом/домино) предметы гарантированно попадают в stable-check очередь, иначе они не эмитят landing.

Step 4 — LandingBehavior (strategy) + LandingOutcome (без рейтингов сейчас, но ready)

Заменяет весь прежний “штрафы/quality” шаг.

4.1 Event schema

Добавить/расширить EVENT_ITEM_LANDED:
Payload минимум:

item_id

item_kind

surface_kind (FLOOR, SHELF, …)

cause (минимум: REJECT, DROP, ACCIDENT, COLLISION)

impact (численный прокси: например |vy| при стабилизации; или импульс/скорость)

tick (если есть)

4.2 LandingOutcome

В домене/аппе завести структуру LandingOutcome (класс или Dictionary — по стилю репо):

effects (один или массив)
Эффекты минимум:

NONE

BOUNCE(multiplier)

BREAK
Зарезервировать future:

quality_delta (optional)

entropy_delta (optional)

4.3 LandingBehavior strategies

Интерфейс/база:

compute_outcome(payload) -> LandingOutcome

Реализации минимум:

DefaultLandingBehavior: всегда NONE (пока нет рейтингов)

BouncyBehavior: при landing на FLOOR и impact > threshold → BOUNCE(k)

BreakableBehavior: при landing на FLOOR и impact > threshold → BREAK

4.4 Registry

LandingBehaviorRegistry:

map item_kind -> behavior

дефолт — DefaultLandingBehavior

4.5 App wiring

В app слое (ShiftService/RunManager путь по репо):

record_item_landed(payload) -> LandingOutcome

выбирает behavior по item_kind

возвращает outcome

(позже сюда добавятся рейтинги, не меняя интерфейс)

4.6 UI application

В “landing emission point” (из Step 3):

сформировать payload

вызвать RunManager.record_item_landed(payload)

применить outcome:

BOUNCE: изменить скорость/импульс (обратная инерция)

BREAK: визуал/удаление/disable (как у вас принято)

NONE: ничего

Step 5 — Тесты

Unit (Node-free):

тесты для behaviors:

Default → NONE

Bouncy → BOUNCE при impact > threshold

Breakable → BREAK при impact > threshold

Functional (scene):

кейс “transfer на floor” (включая RISE_THEN_FALL) → предмет стабилен и не проваливается.

кейс “предмет сбили с полки” → эмитится ITEM_LANDED/EVENT_ITEM_LANDED и применяется outcome (хотя бы NONE по умолчанию).

если возможно: отдельный предмет-kind, который bounce, и который break, чтобы проверить registry+application.

Запуск:

GODOT_TEST_HOME="$PWD/.godot_test_home_persist" task tests

Step 6 — Документация

Обновить техдок/заметки:

что ItemLanded = факт, формируется на UI/physics границе

что LandingBehavior = доменная политика по item_kind

что LandingOutcome = декларативный результат, исполняется UI

что рейтинги/штрафы появятся позже как расширение outcome + обработка в app слое

Добавить:

docs/notes/2026-01-10_changelog_step_6_1_no_one_way_landing_behavior.md

docs/notes/2026-01-10_checklist_step_6_1_invariants.md

Acceptance criteria (коротко)

Пол не one-way; предметы после landing не проваливаются.

“Вверх через пол” работает через collision-профили и безопасное переключение фаз.

Один bool управляет всеми debug-логами.

И “drop/transfer”, и “сбили с полки” дают единый landing event + видимые логи.

ItemLanded вызывает record_item_landed → outcome применяется (есть хотя бы 1 bouncy и 1 breakable kind).

Все тесты проходят, проект запускается.