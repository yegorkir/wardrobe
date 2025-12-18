default: all

set shell := ["zsh", "-c"]
godot_bin := env_var_or_default('GODOT_BIN', '')

_require_godot_bin:
	@if [ -z "{{godot_bin}}" ]; then echo "GODOT_BIN is required (export GODOT_BIN=/path/to/Godot)"; exit 1; fi

all: web web-local mac-debug

web: _require_godot_bin
	rm -rf builds/current/web_itch
	mkdir -p builds/current/web_itch
	"{{godot_bin}}" --headless --export-release "Web" builds/current/web_itch/index.html
# 	cd builds/current/web_itch && zip -r ../web_itch.zip .

web-local: _require_godot_bin
	rm -rf builds/current/web_local
	mkdir -p builds/current/web_local
	"{{godot_bin}}" --headless --export-debug "Web (local)" builds/current/web_local/index.html

mac-debug: _require_godot_bin
	rm -rf builds/current/macos
	mkdir -p builds/current/macos
	"{{godot_bin}}" --headless --export-debug "macOS" builds/current/macos/Wardrobe.app

tests: _require_godot_bin
	GODOT_BIN="{{godot_bin}}" ./addons/gdUnit4/runtest.sh -a ./tests

save:
	mkdir -p builds/archive
	cd builds/current && zip -r "../archive/build_`date +%y%m%d_%H%M%S`.zip" .
	rm -rf builds/current/*
