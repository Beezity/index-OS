#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v fish >/dev/null 2>&1; then
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm fish
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf -y install fish
  else
    echo "THE INDEX: cannot install Fish on this distribution" >&2
    exit 1
  fi
fi

command -v fish >/dev/null 2>&1 || { echo "THE INDEX: Fish installation failed" >&2; exit 1; }
mkdir -p "$HOME/.config/fish"
install -m644 "$DIR/config.fish" "$HOME/.config/fish/config.fish"
fish -n "$HOME/.config/fish/config.fish"
