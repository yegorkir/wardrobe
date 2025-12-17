# Step 2 sandbox spec sync

## Context
- Синхронизировал два геймдизайнерских документа о Step 2 (WASD + Pick/Put/Swap) и перенёс их в основной TDD (`docs/technical_design_document.md`).
- Фокус: единая сцена WardrobeScene.tscn, система слотов/предметов/рук, таргетинг и InteractionResolver.

## Decisions
- Выделен отдельный раздел TDD (“Step 2 — Movement + Pick/Put/Swap Sandbox”) с общими целями, layout-структурой, системами S0–S9 и Definition of Done.
- Все численные уточнения и процедурные детали перенесены из TDD в `docs/steps/02_step2_sandbox.md`, чтобы их было проще менять (HookBoard координаты, InteractArea, скорость игрока, таргетинг, ItemData/seed, debug-reset/validate-world и web smoke процесс).

## Follow-ups
- Нет блокеров: спецификация разделена на “what” (TDD) и “how (numbers)” в step-документе; можно переходить к имплементации и будущему Step 2.1.
