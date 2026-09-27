#!/usr/bin/env bash

CYAN=$'\e[38;2;93;173;226m'; DIM=$'\e[2m'; RED=$'\e[38;2;255;107;107m'; GRN=$'\e[38;2;93;226;133m'; NC=$'\e[0m'
INDEX_ROOT="${INDEX_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
THEMES="$DATA/themes"

say(){ printf '%s::%s %s\n' "$CYAN" "$NC" "$1"; }
ok(){ printf '   %s✓%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ printf '   %s✗%s %s\n' "$RED" "$NC" "$1"; }
note(){ printf '   %s%s%s\n' "$DIM" "$1" "$NC"; }
require_command(){ command -v "$1" >/dev/null 2>&1 || { bad "required command missing after installation: $1"; return 1; }; }
require_file(){ [[ -f "$INDEX_ROOT/$1" ]] || { bad "repository file missing: $1"; return 1; }; }
