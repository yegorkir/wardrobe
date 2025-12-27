# Changelog — 2025-12-19 CI Godot Download Fix

## Investigation
- GitHub Actions job `Install Godot 4.5` падал на `wget -q https://downloads.tuxfamily.org/godotengine/4.5/Godot_v4.5-stable_linux.x86_64.zip` с кодом 4 (network failure), то есть mirror TuxFamily был недоступен/флапающий и пайплайн останавливался ещё до запуска тестов.
- В workflow не было запасного источника/ретраев, поэтому любой краткий обрыв сети ломал сборку, хотя сам проект и тесты оставались неизменными.
- После переключения на GitHub releases шаг `Run GdUnit4 tests` всё ещё падал раньше запуска, потому что `GODOT_BIN` был равен строке `godot`, а `addons/gdUnit4/runtest.sh` требует абсолютный путь и проверяет его через `-f`, из-за чего скрипт не видел установленный в `/usr/local/bin/godot` бинарь.

## Changed
- В `.github/workflows/tests.yml` скачивание Godot 4.5 переключено на GitHub releases через `curl` с ретраями и бэкофом (`--retry 5 --retry-delay 2 --retry-connrefused --fail`), после чего файл распаковывается и бинарь ставится в `/usr/local/bin/godot` как прежде.
- Тот же workflow теперь пробрасывает `GODOT_BIN=/usr/local/bin/godot`, чтобы CLI увидел установленный бинарь и перестал выходить с ошибкой "The specified Godot binary 'godot' does not exist".

## Tests
- Не запускались локально: изменение касается CI-setup; перезапустите GitHub Actions job `Tests` (или при наличии бинаря выполните `./addons/gdUnit4/runtest.sh -a ./tests`) чтобы убедиться, что скачивание теперь проходит и тесты стартуют.
