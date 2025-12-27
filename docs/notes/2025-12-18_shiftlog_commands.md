# Wardrobe Shift Log (interaction commands)

## Context
- После введения `WardrobeInteractionCommand` взаимодействия стали оформляться как команды, но по инструкции «Commands in / Events out» каждое последствие должно записываться в ShiftLog. До этого изменения события отсутствовали — логика `WardrobeScene` лишь печатала текст в консоль.

## Changes
- Добавлен `scripts/app/logging/shift_log.gd` (RefCounted) с API `record(event_type, payload)`, `get_events()`, `clear()`. Он хранит события в массиве и выдаёт копии, чтобы UI не мог мутировать лог.
- `WardrobeScene` теперь создаёт `WardrobeShiftLog`, сбрасывает его при новом seed и логирует `interaction_performed`/`interaction_rejected` для каждой команды.
- Добавлен unit-тест `tests/unit/shift_log_test.gd`, проверяющий запись/очистку событий.

## References
- Godot 4.5 docs: [RefCounted](https://docs.godotengine.org/en/4.5/classes/class_refcounted.html) — подтверждение семантики владения для логов без Node.
- AGENTS.md — раздел «Events and ShiftLog».
