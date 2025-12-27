# Checklist — 2025-12-19 CI Godot Download Fix

- [x] Зафиксировать сообщение GitHub Actions про `wget` exit 4 на mirror `downloads.tuxfamily.org` и понять, что тесты не стартуют из-за сетевого сбоя на этапе установки Godot.
- [x] Обновить `.github/workflows/tests.yml`, переключив скачивание Godot 4.5 на GitHub releases и добавив ретраи в `curl`, сохранив распаковку и установку в `/usr/local/bin/godot`.
- [x] Зафиксировать новое падение `Run GdUnit4 tests` с сообщением "The specified Godot binary 'godot' does not exist" и выяснить, что `GODOT_BIN` должен быть абсолютным путём.
- [x] Прописать `GODOT_BIN=/usr/local/bin/godot` в шаге запуска тестов и обновить changelog.
- [x] Описать расследование и изменения в `docs/notes/2025-12-19_ci_godot_download_fix.changelog.md` и подготовить этот чеклист.
- [ ] Перезапустить workflow `Tests` в GitHub Actions (или локально запустить `./addons/gdUnit4/runtest.sh -a ./tests` при наличии Godot 4.5 в PATH), чтобы подтвердить успешное скачивание и запуск тестов.
