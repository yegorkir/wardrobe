default: all

set shell := ["zsh", "-c"]

all: web-itch web-local mac-debug

web-itch:
	rm -rf builds/current/web_itch
	mkdir -p builds/current/web_itch
	Godot --headless --export-release "Web (itch.io)" builds/current/web_itch/index.html
	cd builds/current/web_itch && zip -r ../web_itch.zip .

web-local:
	rm -rf builds/current/web_local
	mkdir -p builds/current/web_local
	Godot --headless --export-debug "Web (local)" builds/current/web_local/index.html

mac-debug:
	rm -rf builds/current/macos
	mkdir -p builds/current/macos
	Godot --headless --export-debug "macOS" builds/current/macos/Wardrobe.app

save-and-clear:
	mkdir -p builds/archive
	cd builds/current && zip -r "../archive/build_`date +%y%m%d_%H%M%S`.zip" .
	rm -rf builds/current/*
