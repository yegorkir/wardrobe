# Interaction resolver migration

## Context
- `scripts/wardrobe/interaction_resolver.gd` напрямую работал с `WardrobePlayerController` и `WardrobeSlot`, что нарушало правило «core без Nodes». Решение pick/put/swap должно жить в SimulationCore и принимать только данные про состояние руки/слота.

## Changes
- Добавлен доменный `PickPutSwapResolver` (`scripts/app/interaction/pick_put_swap_resolver.gd`) — без зависимостей от Node, возвращает структуру результата и коды действий.
- Введён `WardrobeInteractionCommand` (`scripts/app/interaction/interaction_command.gd`), задающий единый формат команд (`type/tick/payload`) с безопасными ключами `StringName`.
- Добавлен `WardrobeInteractionEngine` + `WardrobeInteractionTarget`, которые принимают команды и взаимодействуют с `WardrobePlayerController`/`WardrobeSlot`. UI теперь строит команду и отдаёт её в engine, а Node-хелперы служат только адаптером.
- Старый `scripts/wardrobe/interaction_resolver.gd` удалён.

## References
- Godot 4.5 docs: [CharacterBody2D](https://docs.godotengine.org/en/4.5/classes/class_characterbody2d.html) — подтверждение API для `move_and_slide` и инвентаря игрока (для сверки параметров при переносе логики).
- Project AGENTS.md — раздел «Commands in / Events out» и «No SceneTree in core».

## Follow-up
- Next step: build WardrobeShiftLog events for each interaction command.
