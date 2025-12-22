#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.5-stable}"
GODOT_INSTALL_DIR="${GODOT_INSTALL_DIR:-$HOME/.local/share/godot/$GODOT_VERSION}"
GODOT_CACHE_DIR="${GODOT_CACHE_DIR:-$HOME/.cache/godot}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEFAULT_TEST_HOME="$PROJECT_ROOT/.godot_test_home_persist"

log() {
	echo "[setup_godot] $*" >&2
}

quote() {
	local value="$1"
	value=${value//"'"/"'\\''"}
	printf "'%s'" "$value"
}

detect_platform() {
	local os
	local arch
	os="$(uname -s)"
	arch="$(uname -m)"

	case "$os" in
		Darwin)
			echo "macos.universal"
			return 0
			;;
		Linux)
			case "$arch" in
				x86_64)
					echo "linux.x86_64"
					return 0
					;;
				arm64|aarch64)
					echo "linux.arm64"
					return 0
					;;
			esac
			;;
	esac

	log "Unsupported platform: $os/$arch"
	return 1
}

ensure_unzip() {
	if command -v unzip >/dev/null 2>&1; then
		return 0
	fi

	log "unzip is required to extract the Godot archive"
	return 1
}

download_file() {
	local url="$1"
	local output="$2"

	if command -v curl >/dev/null 2>&1; then
		curl -fsSL "$url" -o "$output"
		return 0
	fi

	if command -v wget >/dev/null 2>&1; then
		wget -qO "$output" "$url"
		return 0
	fi

	log "curl or wget is required to download Godot"
	return 1
}

resolve_godot_bin() {
	local root_dir="$1"
	local app_path="$root_dir/Godot.app/Contents/MacOS/Godot"

	if [ -x "$app_path" ]; then
		echo "$app_path"
		return 0
	fi

	local bin_path
	bin_path="$(find "$root_dir" -maxdepth 1 -type f -name "Godot_v${GODOT_VERSION}_*" | head -n 1)"
	if [ -n "$bin_path" ]; then
		chmod +x "$bin_path"
		echo "$bin_path"
		return 0
	fi

	return 1
}

install_godot() {
	local platform
	platform="$(detect_platform)"

	local archive_name="Godot_v${GODOT_VERSION}_${platform}.zip"
	local base_url="${GODOT_DOWNLOAD_BASE_URL:-https://downloads.tuxfamily.org/godotengine/$GODOT_VERSION}"
	local download_url="${GODOT_DOWNLOAD_URL:-$base_url/$archive_name}"

	log "Downloading $download_url"
	mkdir -p "$GODOT_CACHE_DIR"
	ensure_unzip

	local archive_path="$GODOT_CACHE_DIR/$archive_name"
	download_file "$download_url" "$archive_path"

	local tmp_dir
	tmp_dir="$(mktemp -d)"
	unzip -q "$archive_path" -d "$tmp_dir"

	mkdir -p "$GODOT_INSTALL_DIR"

	if [ -d "$tmp_dir/Godot.app" ]; then
		rm -rf "$GODOT_INSTALL_DIR/Godot.app"
		mv "$tmp_dir/Godot.app" "$GODOT_INSTALL_DIR/"
	else
		local bin_path
		bin_path="$(resolve_godot_bin "$tmp_dir" || true)"
		if [ -z "$bin_path" ]; then
			log "Could not find extracted Godot binary"
			rm -rf "$tmp_dir"
			return 1
		fi
		mv "$bin_path" "$GODOT_INSTALL_DIR/"
	fi

	rm -rf "$tmp_dir"
}

ensure_godot() {
	if [ -n "${GODOT_BIN:-}" ] && [ -x "$GODOT_BIN" ]; then
		return 0
	fi

	if [ -d "$GODOT_INSTALL_DIR" ]; then
		local existing_bin
		existing_bin="$(resolve_godot_bin "$GODOT_INSTALL_DIR" || true)"
		if [ -n "$existing_bin" ]; then
			GODOT_BIN="$existing_bin"
			export GODOT_BIN
			return 0
		fi
	fi

	install_godot

	local installed_bin
	installed_bin="$(resolve_godot_bin "$GODOT_INSTALL_DIR")"
	GODOT_BIN="$installed_bin"
	export GODOT_BIN
}

emit_env() {
	local test_home
	test_home="${GODOT_TEST_HOME:-$DEFAULT_TEST_HOME}"

	printf "export GODOT_BIN=%s\n" "$(quote "$GODOT_BIN")"
	printf "export GODOT_TEST_HOME=%s\n" "$(quote "$test_home")"
}

main() {
	ensure_godot
	emit_env
}

main "$@"
