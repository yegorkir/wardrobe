# Удаление Step 2.1 (Color Match) и всего связанного

## Что сделано
- Удалён код челленджа и провайдеров: `WardrobeChallengeController`, `WardrobeChallengeProvider`, `WardrobeChallengeConfig`, `WardrobeDataService`.
- Удалены UI‑элементы челленджа из `WardrobeScene.tscn` (overlay/summary).
- Удалён загрузчик `challenges` из `ContentDBBase` и файл `content/challenges/color_match_basic.json`.
- Обновлена документация Step 2 (удалён раздел про Color Match).

## Последствия
- `WardrobeScene` теперь всегда стартует в Step 3 режиме и не ищет challenge JSON.
- ContentDB больше не хранит категорию `challenges`.
