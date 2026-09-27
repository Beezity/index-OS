#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

command -v fish >/dev/null 2>&1 || { echo "Fish is required before running install-fish.sh" >&2; exit 1; }
command -v fastfetch >/dev/null 2>&1 || { echo "Fastfetch is required before running install-fish.sh" >&2; exit 1; }
[[ -f "$DIR/fish/config.fish" ]] || { echo "Missing fish/config.fish" >&2; exit 1; }

# Validate before replacing an existing configuration.
fish -n "$DIR/fish/config.fish"

mkdir -p "$CFG/fish"
cp -f "$DIR/fish/config.fish" "$CFG/fish/config.fish"

fish -n "$CFG/fish/config.fish"
echo "   Fish: Index prompt, palette, Git status and Fastfetch configured"
