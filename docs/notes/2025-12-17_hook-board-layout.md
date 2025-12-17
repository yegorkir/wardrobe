# Hook board layout polish

## Summary
- Привёл все Hook_i к гриду из `docs/steps/02_step2_sandbox.md` (Δx = 160, Δy = 200; слоты ±40 px), чтобы сцена совпадала с описанием Step 2.
- Урезал `SlotSprite` до `scale = Vector2(0.25, 0.25)`, иначе визуальные зоны перекрывали друг друга после расширения новых текстур.
- Отключил неиспользуемый ColorRect-плейсхолдер и оставил только реальные спрайты (`doublehook.png`, `wardrobe.png`).
- HookItem вынесен в отдельный префаб (`scenes/prefabs/hook_item.tscn`) со скриптом `HookItem` — теперь любой крючок можно редактировать один раз и переиспользовать через `slot_prefix`.
- Добавлен `StaticBody2D` в префаб крючка, поэтому игрок (CharacterBody2D) упирается в шкаф и не может проходить сквозь фон.

## Follow-ups
- Как появится финальное артовое дерево (бекграунд стенда и слот-рамки), заменить `res://assets/sprites/placeholder/*.svg`.

## References
- `docs/steps/02_step2_sandbox.md` — таблица координат HookBoard.
