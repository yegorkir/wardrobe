# Project Skeleton: "Магический гардероб"

Документ описывает базовый каркас проекта на Godot 4.x, который реализован на шаге «Project skeleton». Цель каркаса — дать рабочее приложение (desktop + web) с навигацией по экранам, глобальными синглтонами и тестовыми данными, но без игровой логики гардероба.

---

## 1. Структура каталогов

```
res://
├─ scenes/
│  ├─ Main.tscn             # корневой Control с менеджером экранов
│  └─ screens/              # отдельные экраны (меню, смена, сводка)
├─ scripts/
│  ├─ autoload/             # глобальные сервисы (RunManager и др.)
│  ├─ ui/                   # логика экранов/интерфейса
│  └─ sim/                  # (зарезервировано) логика симуляции
├─ content/                 # data-driven конфиги (JSON)
├─ assets/                  # визуал/звук (пусто на этапе скелета)
├─ save/                    # примеры схем/сохранений
└─ docs/                    # документация проекта
```

---

## 2. Сцены и навигация

### 2.1 `scenes/Main.tscn`
Root `Control` (скрипт `scripts/ui/main.gd`), содержащий `ScreenRoot`. При получении сигнала `screen_requested` от `RunManager` загружает соответствующую сцену и вставляет в `ScreenRoot`. Поддерживаются идентификаторы:

* `main_menu` → `scenes/screens/MainMenu.tscn`
* `wardrobe` → `scenes/screens/WardrobeScene.tscn`
* `shift_summary` → `scenes/screens/ShiftSummary.tscn`

### 2.2 Экраны

1. **MainMenu** — кнопки `Start Run` и `Quit` (в Web кнопка «Quit» отключена). При старте дергает `RunManager.start_run()`.
2. **WardrobeScene** — фон, базовый HUD (Wave/Time/Money/Magic/Debt) и debug-кнопка `End Shift`. Подписан на сигнал `RunManager.hud_updated` и отображает демо-данные.
3. **ShiftSummary** — текстовый плейсхолдер итогов + кнопка `Back to Menu`, возвращающая в главное меню по сигналу `RunManager.go_to_menu()`.

Последовательность переходов: `MainMenu → WardrobeScene → ShiftSummary → MainMenu`.

---

## 3. Autoload (Project Settings → Autoload)

| Singleton | Скрипт | Ответственность |
|-----------|--------|-----------------|
| `RunManager` | `scripts/autoload/run_manager.gd` | Глобальное состояние забега: хранит демо-HUD, управляет переходами между экранами, конфигурирует `InputMap` (действия `tap`, `cancel`, `debug_toggle`). Эмитит сигналы `screen_requested`, `run_state_changed`, `hud_updated`. При завершении смены записывает очки в `SaveManager`. |
| `ContentDB` | `scripts/autoload/content_db.gd` | Загружает JSON из `content/archetypes`, `content/modifiers`, `content/waves`. Предоставляет методы `get_archetype`, `get_modifier`, `get_wave`. |
| `SaveManager` | `scripts/autoload/save_manager.gd` | Загружает/сохраняет мета-прогресс (`user://save_meta.json`). API: `load_meta`, `save_meta`, `clear_save`. |
| `Debug` | `scripts/autoload/debug.gd` | Обрабатывает `debug_toggle` (F1) и шлет сигнал `debug_toggled(enabled)`. |

---

## 4. HUD (WardrobeScene)

Панель `PanelContainer` с пятью `Label` и кнопкой `End Shift (debug)`. Методы:

* `_on_hud_updated(snapshot)` — обновляет текст на основе словаря демо-состояния.
* `_on_end_shift_pressed()` — принудительно вызывает `RunManager.end_shift()`.

На этом шаге данные HUD берутся из заглушек (`_reset_demo_hud()` внутри RunManager).

---

## 5. Заглушки данных (`content/`)

* `content/archetypes/` — `human.json`, `zombie.json`, `vampire.json` с простыми полями (`id`, `display_name`, `patience`, `effect`).
* `content/modifiers/` — `example_1.json` (`Lucky Day`).
* `content/waves/` — `wave_1.json` (длительность, список клиентов, сложность).

Конфиги подхватываются `ContentDB` автоматически и логируются при старте.

---

## 6. Сохранения

* Путь: `user://save_meta.json`.
* Формат: JSON со схемой `save_version`, `total_currency`, `unlocks`.
* Пример: `save/example_meta.json`.
* `RunManager` при завершении смены добавляет `money` в `total_currency` и вызывает `SaveManager.save_meta()`.

---

## 7. Web Export

* `export_presets.cfg` содержит пресет **Web** с выходом `build/web/index.html`.
* Алгоритм smoke-теста:
  1. `Project → Export… → Web → Export Project`.
  2. Открыть `build/web/index.html` локально или на статиках.
  3. Проверить: загрузка, клики по кнопкам, переходы экранов, вывод логов сохранения.

---

## 8. Определение готовности (DoD)

* Игра запускается без ошибок, экранное дерево: `MainMenu → WardrobeScene → ShiftSummary → MainMenu`.
* Все autoload-сервисы инициализируются и логируют статус (ContentDB, SaveManager, Debug).
* `SaveManager` реально читает/пишет JSON (можно удалить файл и убедиться, что создается заново).
* HUD в WardrobeScene показывает значения из RunManager.
* Web preset собирается и прогоняется как smoke-тест.

---

## 9. Следующие шаги

1. Реализация SimulationCore (очередь клиентов + базовые команды).
2. PlacementSystem с двумя слотами и swap.
3. Добавление архетипов Zombie/Vampire и эффектов порчи.
4. Инструменты (якоря), магия и модификаторы между волнами.
5. Расширение UI: индикаторы очереди, лог событий, сводка смены.

Документ дополняется по мере развития проекта и служит точкой входа для новых участников.

---

## 10. Контроль качества и статический анализ

* UI-скрипты получают ссылки на автолоады через `get_node("/root/...")`, поэтому `godot-tools` и GDScript-анализатор корректно резолвят типы и не выдают ошибки про неизвестные идентификаторы.
* В местах, где API возвращает `Variant`, используются явные типы (`var parsed: Variant = JSON.parse_string(...)`, `var scene: Control = ...`). Это убирает предупреждения и делает код понятнее.
* Константы ввода приведены к актуальному API Godot 4 (`KEY_ESCAPE`, `KEY_F1`, `MouseButton.MOUSE_BUTTON_LEFT`), чтобы каркас собирался без депрекейтед-ошибок.
* Отступы внутри файлов унифицированы (табы в автолоадах, пробелы в UI/контенте), что устраняет подсветку о смешанной индентации и облегчает ревью.

Рекомендуется придерживаться этих практик при добавлении новых файлов, чтобы поддерживать чистоту кода и минимизировать время на правки lint-предупреждений.
