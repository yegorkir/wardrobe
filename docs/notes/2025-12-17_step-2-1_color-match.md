# Step 2.1 — Color Match challenge rollout

## Context
- Step 2 sandbox готов: сцена WardrobeScene, Slot/Item/InteractionResolver работают по базовой схеме.
- Геймдизайн Step 2.1 требует мини-челлендж «color match»: на крючках висят цветные плащи, на стойке появляется номерок/тикет цвета, игрок должен доставить правильный предмет, все метрики логируются.
- Нужно минимально-инвазивно нарастить WardrobeScene: автозапуск челленджа, пресеты, метрики, UI-оверлей/summary, reset и best-results.

## Decisions
- **Challenge пресеты**: JSON-файлы под `res://content/challenges/`. Добавлен `color_match_basic.json` с `seed_layout` (где лежат вещи), `target_layout` (порядок заказов) и `par_actions`. WardrobeScene при старте пытается загрузить `color_match_basic`; если файла нет/структура невалидна — откатывается к старому `content/seeds/step2_seed.json`.
- **Seed/Orders**: WardrobeScene хранит две таблицы (`_challenge_seed_entries`, `_challenge_orders`). При старте/рестарте вызывается `_apply_seed(...)`, затем `_advance_order` спаунит реальный тикет (ItemNode) прямо в `DeskSlot_0` — его можно подобрать и переложить. Когда игрок кладёт предмет в `DeskSlot_0`, `_handle_challenge_delivery` проверяет `item_id`/цвет, удаляет предмет (queue_free) и двигает сценарий вперёд. Тикеты старых заказов очищаются автоматически.
- **Метрики**: `_metric_actions_total` считает все нажатия `E`, а `picks/puts/swaps` фиксируются на успешных операциях. `_process` измеряет время и суммарную длину пути (по `Player.global_position`). `_restart_count` растёт при `R`. По завершении вычисляем summary-словарь, пишем `print()` и показываем панель.
- **UI**: добавлен `DeskTicketIndicator` (ticket sprite), `ChallengeOverlayLabel` (в углу: `mm:ss | Actions N` или `Solved ...`), `ChallengeSummary` (панель с Time/Actions/Picks/Puts/Swaps/Move px/Attempts и строкой «Best: …»). Панель скрывается до завершения, overlay — только если челлендж активен.
- **Best результаты**: WardrobeScene грузит/пишет `user://challenge_bests.json`. Сохраняем лучшую пару (минимальное время, минимальный `actions_total`) для каждого `challenge_id`. Summary показывает сохранённые значения.
- **Инпут**: `debug_reset` теперь рестартит челлендж (seed + метрики + attempts++). `interact` увеличивает `actions_total` даже если операция не сработала, чтобы статистика отражала количество попыток.
- **Fallback**: если challenge JSON не найден, WardrobeScene работает в прежнем sandbox-режиме (seed из `content/seeds/step2_seed.json`, overlay/summary скрыты).

## Follow-ups
- Добавить больше challenge пресетов + переключатель (клавиша или dev UI).
- Подумать, как отображать «target color» в текстовом виде (сейчас только цвет тикета).
- Привести автотесты к сценарию Step 2.1 (минимальный smoke есть, но можно добавить проверки доставок и best save).
- После финализации размеров спрайтов (wardrobe/doublehook/coat/tickets) обновить `.svg`/`.png` и пересчитать scale.
