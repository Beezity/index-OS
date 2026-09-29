#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "patch failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Fedora test patch"
command -v dnf >/dev/null 2>&1 || { bad "Fedora Linux with dnf is required."; exit 1; }
[[ -r /etc/fedora-release ]] || { bad "This patch helper is intended for Fedora Linux."; exit 1; }
FEDORA_VERSION="$(rpm -E %fedora)"
[[ "$FEDORA_VERSION" =~ ^[0-9]+$ ]] || { bad "could not determine Fedora release"; exit 1; }
(( FEDORA_VERSION >= 43 )) || { bad "Fedora 43 or newer is required; detected Fedora $FEDORA_VERSION"; exit 1; }
note "detected Fedora $FEDORA_VERSION"
validate_repository_layout

[[ -f "$CFG/labwc/rc.xml" && -f "$CFG/quickshell/shell.qml" ]] || {
  bad "THE INDEX does not appear to be installed for this user"
  note "Use install-fedora.sh for an initial installation. This helper only patches an existing install."
  exit 1
}

for cmd in labwc quickshell wlr-randr grim slurp wl-copy notify-send fc-cache xmllint; do
  require_command "$cmd"
done

say "backing up files managed by THE INDEX..."
bash "$SCRIPT_DIR/index-backup"
ok "pre-patch backup created"

say "patching labwc configuration..."
SAVED_LIBINPUT=""
if [[ -f "$CFG/labwc/rc.xml" ]]; then
  SAVED_LIBINPUT="$(mktemp --suffix=.index-libinput)"
  sed -n '/<libinput>/,/<\/libinput>/p' "$CFG/labwc/rc.xml" > "$SAVED_LIBINPUT"
  if ! grep -q '<libinput>' "$SAVED_LIBINPUT" || ! grep -q '</libinput>' "$SAVED_LIBINPUT"; then
    rm -f "$SAVED_LIBINPUT"
    SAVED_LIBINPUT=""
  fi
fi

cp -f "$INDEX_ROOT/labwc/config/rc.xml" "$CFG/labwc/rc.xml"
if [[ -n "$SAVED_LIBINPUT" && -s "$SAVED_LIBINPUT" ]]; then
  INPUT_TMP="$(mktemp "$CFG/labwc/.rc.xml.input.XXXXXX")"
  awk '
    NR==FNR { block=block $0 ORS; next }
    !skip && /<libinput>/ { printf "%s", block; skip=1; next }
    skip { if (/<\/libinput>/) skip=0; next }
    { print }
  ' "$SAVED_LIBINPUT" "$CFG/labwc/rc.xml" > "$INPUT_TMP"
  mv "$INPUT_TMP" "$CFG/labwc/rc.xml"
  rm -f "$SAVED_LIBINPUT"
fi

for script in index-display-save index-display-restore; do
  install -m755 "$INDEX_ROOT/labwc/config/$script" "$CFG/labwc/$script"
done
xmllint --noout "$CFG/labwc/rc.xml"

say "patching Quickshell multimonitor files..."
mkdir -p "$CFG/quickshell"
for file in \
  shell.qml Bar.qml DisplaysPanel.qml Prescript.qml PrescriptState.qml \
  SettingsPanel.qml StartMenuState.qml qmldir; do
  cp -f "$INDEX_ROOT/quickshell/$file" "$CFG/quickshell/$file"
done

say "patching screenshot helper..."
mkdir -p "$HOME/.local/bin"
install -m755 "$INDEX_ROOT/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"

say "refreshing titlebar font and diagnostics..."
mkdir -p "$HOME/.local/share/fonts"
cp -f "$INDEX_ROOT/assets/PerfectDOSVGA437-Universal.ttf" "$HOME/.local/share/fonts/"
fc-cache -f >/dev/null
install -m755 "$INDEX_ROOT/scripts/index-doctor" "$HOME/.local/bin/index-doctor"

ok "Fedora test patch applied"
note "No packages were installed or removed. Existing ffmpeg and power-profile packages were left untouched."
note "Log out of THE INDEX and log back in before testing the PR."
note "To restore the previous configuration, run: index-restore latest"
