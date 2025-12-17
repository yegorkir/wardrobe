# Step 1 — Project Skeleton

> Дополняет [Technical Design Document — раздел 11 «План реализации (итерации)»](../technical_design_document.md#11-план-реализации-итерации). После завершения этого шага проект соответствует первому пункту плана TDD.

## Цель шага

За 1–2 вечера получить **пустой, но рабочий каркас** проекта, который уже:

- запускается как игра;
- имеет навигацию по экранам;
- держит глобальное состояние (`RunManager`);
- грузит контент (`ContentDB`);
- умеет сохраняться (`SaveManager`);
- показывает базовый HUD;
- и **собирается в Web** (smoke test).

> На этом шаге **не реализуются** полноценные механики гардероба.

---

## A. Создать проект и базовые настройки

1. Создать новый Godot 4.x проект (2D).
2. В `Project Settings → Input Map` добавить действия:
	- `tap` (LMB / touch);
	- `cancel` (Esc / back);
	- `debug_toggle` (например, F1).
3. Подготовить структуру папок:
	- `scenes/`
		- `screens/`
		- `prefabs/`
	- `scripts/`
		- `autoload/`
		- `sim/`
		- `ui/`
	- `content/`
		- `archetypes/`
		- `waves/`
		- `modifiers/`
	- `assets/` (спрайты/звук позже)
	- `save/` (примеры схем)

---

## B. Сцены: минимальная навигация

Создать 4 сцены-экрана (пока простые, с заголовком на UI):

1. `scenes/Main.tscn`
	- Root: `Control`.
	- Ответственность: главный контейнер, переключение экранов.
2. `scenes/screens/MainMenu.tscn`
	- Кнопки `Start Run`, `Quit` (на Web кнопку можно отключить).
3. `scenes/screens/WardrobeScene.tscn`
	- Фон + HUD-панель + кнопка `End Shift (debug)`.
4. `scenes/screens/ShiftSummary.tscn`
	- Текст “Summary placeholder” + кнопка `Back to Menu`.
5. `scenes/screens/ModifierSelect.tscn`
	- Заглушка с текстом “Modifier select placeholder” + кнопка `Continue`, подключённая к `RunManager` (будет использоваться на шаге 7).

Минимальный сценарий навигации: `MainMenu → WardrobeScene → ShiftSummary → MainMenu`.

---

## C. Autoload singletons (глобальные сервисы)

В `Project Settings → Autoload` добавить 3–4 скрипта:

1. `RunManager.gd`
	- На старте инициализирует мета-прогресс через `SaveManager`, подготавливает действия ввода `tap/cancel/debug_toggle`.
	- Хранит демо-снимок HUD (`wave`, `time`, `money`, `magic`, `debt`) и шлёт его через сигнал `hud_updated`.
	- Методы: `start_run()`, `start_shift()`, `end_shift()`, `go_to_menu()`.
	- Сигналы: `screen_requested(screen_id, payload)`, `run_state_changed(state)`.
	- `end_shift()` создаёт резюме и обновляет `total_currency` в `user://save_meta.json`.
2. `ContentDB.gd`
	- На старте грузит конфиги (1–2 тестовых файла достаточно).
	- API: `get_archetype(id)`, `get_modifier(id)`, `get_wave(id)`.
	- На этом шаге достаточно загрузить JSON/Resource и залогировать успех.
3. `SaveManager.gd`
	- API: `save_meta(data)`, `load_meta() -> data`, `clear_save()`.
	- Заглушечный JSON содержит `save_version`, `total_currency`, `unlocks`.
	- Файл: `user://save_meta.json`; одновременно подготовить константу/методы под `user://save_run.json` (может быть пустым до mid-run сохранений).
4. (опционально) `Debug.gd`
	- Переключает debug overlay и шлёт логи в консоль.

> Дополнительно: в `scripts/domain/` (или `scripts/app/`) создать модули `magic_system.gd` и `inspection_system.gd`, которые принимают конфиги (`insurance_mode`, `emergency_cost_mode`, `inspection_mode`) и предоставляют методы-заглушки (`apply_insurance`, `request_emergency_locate`, `record_entropy`). Эти сервисы пока могут возвращать только структуру данных и печатать логи, но их наличие гарантирует, что переключение режимов произойдёт конфигом, а не переписыванием кода.
> Ограничение: эти модули не должны зависеть от `Node`/`SceneTree`, они работают с данными (`WardrobeRunState` + config), чтобы их можно было тестировать и переносить в SimulationCore без изменений.

---

## D. UI каркас (HUD)

В `WardrobeScene.tscn` добавить HUD-панель:

- Лейблы: `Wave: -`, `Time: -`, `Money: -`, `Magic: -`, `Debt: -`.
- Кнопка debug `End Shift`.
- Источник данных: `RunManager` отдаёт снимок через `get_hud_snapshot()` и сигнал `hud_updated`, поэтому сцена сразу показывает демо-цифры и слушает обновления без реальной симуляции.

---

## E. Заглушки данных

Создать минимальные файлы контента:

- `content/archetypes/human.json`
- `content/archetypes/zombie.json`
- `content/archetypes/vampire.json`
- `content/modifiers/example_1.json`
- `content/waves/wave_1.json`

Важно: у каждой записи есть `id` и 2–3 поля, которые можно вывести в лог.

---

## F. Web export smoke test

1. Настроить экспорт-пресет **Web**.
2. Собрать пустой билд и открыть локально/на статическом хостинге.
3. Проверить на телефоне:
	- запуск игры;
	- переходы экранов;
	- клики по кнопкам;
	- сохранение/загрузка (достаточно логов).

---

## G. Definition of Done

Шаг считается завершённым, если:

- Проект запускается без ошибок.
- Переход `Меню → WardrobeScene → Summary → Меню` работает.
- Все autoload-сервисы инициализируются и логируют состояние.
- Save/Load реально работает с JSON.
- HUD обновляется тестовыми значениями.
- Web export собирается и открывается (smoke test).

> После выполнения шага можно переходить к шагу 2 из [TDD](../technical_design_document.md#11-план-реализации-итерации).
