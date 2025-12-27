# Анализ: отказ от legacy-взаимодействий на Node-уровне

## Контекст
Цель: первым этапом убрать legacy-подход взаимодействий на Node-уровне (новая доменная логика уже перенесена в `scripts/domain/interaction`). После этого провести новый анализ.

## Обнаруженные legacy-компоненты
- `scripts/wardrobe/interaction_engine_legacy.gd`
	- Node-ориентированный путь `process_command -> _process_with_target` через `WardrobeInteractionTarget`.
	- Не найдено ссылок/использований по проекту (поиск `interaction_engine_legacy`).
- `scripts/wardrobe/interaction_target.gd`
	- Предоставляет API для Node-слота/игрока (`get_slot`, `get_hand_item`, `perform_pick/put/swap`).
	- Не найдено ссылок/использований по проекту (поиск `WardrobeInteractionTarget`/`interaction_target`).

## Влияние на текущую функциональность
- `scripts/ui/wardrobe_scene.gd` использует доменный движок (`scripts/domain/interaction/interaction_engine.gd`) и доменную `WardrobeStorageState`.
- Legacy-слой сейчас не участвует в потоке `wardrobe_scene` и не влияет на геймплей в текущей сцене.

## Решение
Удалить legacy-слой на Node-уровне:
- удалить `scripts/wardrobe/interaction_engine_legacy.gd`;
- удалить `scripts/wardrobe/interaction_target.gd` (если нет скрытых зависимостей в сценах/скриптах).

## Архитектура после удаления
- Interaction pipeline остаётся доменным:
	- `WardrobeInteractionDomainEngine` (domain) получает команду + `WardrobeStorageState` + `ItemInstance`.
	- События идут через `interaction_event_schema.gd` и адаптеры UI (`interaction_event_adapter.gd`, `wardrobe_interaction_events.gd`).
- Node-уровень отвечает только за presentation/adapter и не содержит правил.

## Риски
- Возможны скрытые ссылки в `.tscn` или в будущих сценах/скриптах, которые не попали в текущий поиск.
- Если кто-то ожидал использовать `WardrobeInteractionTarget` как API, нужно будет заменить на доменный pipeline.

## Проверки
- Поиск ссылок в `scripts/` и `scenes/` по `interaction_engine_legacy`/`interaction_target`.
- Прогон unit-тестов (особенно `tests/unit/interaction_*` и интеграционные сцены при наличии).

## Verification
- Выполнен `./addons/gdUnit4/runtest.sh -a ./tests/unit` — 25 тестов, без ошибок.
- Предупреждения те же (повторяющиеся global class names и сообщение macOS про `get_system_ca_certificates`).

## Следующий анализ
После удаления и проверки: пересканировать код/сцены на любые оставшиеся legacy-зависимости и обновить архитектурную заметку.
