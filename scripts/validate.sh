#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/common.sh"
say "validating installed configuration..."
xmllint --noout "$CFG/labwc/rc.xml" "$CFG/labwc/menu.xml" "$CFG/fontconfig/fonts.conf"
FAIL=0; chk(){ if [[ -e "$1" ]]; then ok "$2"; else bad "$2 (missing: $1)"; FAIL=1; fi; }
chk "$CFG/labwc/rc.xml" "labwc rc.xml"; chk "$CFG/labwc/autostart" "labwc autostart"; chk "$CFG/labwc/index-lock" "lock launcher"; chk "$CFG/labwc/wall.png" "wallpaper"; chk "$THEMES/the-index/labwc/themerc" "titlebar theme"
if [[ "${INDEX_VALIDATE_TITLEBAR_BUTTONS:-0}" == 1 ]]; then chk "$THEMES/the-index/labwc/close.xbm" "close button"; chk "$THEMES/the-index/labwc/iconify.xbm" "minimize button"; chk "$THEMES/the-index/labwc/max.xbm" "maximize button"; fi
chk "$CFG/quickshell/shell.qml" "Quickshell shell"; chk "$CFG/quickshell/Bar.qml" "top bar"; chk "$CFG/quickshell/BluetoothMenu.qml" "Bluetooth panel"; chk "$CFG/quickshell/AppearancePanel.qml" "appearance panel"; chk "$CFG/quickshell/AudioPanel.qml" "audio panel"; chk "$CFG/quickshell/NetworkPanel.qml" "network panel"; chk "$CFG/quickshell/PowerPanel.qml" "power panel"; chk "$CFG/quickshell/lock/lock.qml" "INDEX lock"; chk "$CFG/foot/foot.ini" "Foot config"; chk "$CFG/fish/config.fish" "Fish config"; chk "/usr/share/icons/Papirus-Dark/index.theme" "Papirus-Dark icon theme"; chk "$HOME/.local/bin/index-appearance" "appearance helper"; chk "$HOME/.local/bin/index-audio" "audio helper"; chk "$HOME/.local/bin/index-network" "network helper"; chk "$HOME/.local/bin/index-bluetooth" "Bluetooth helper"; chk "$HOME/.local/bin/index-power" "power helper"
if [[ "${INDEX_VALIDATE_CURSOR_ROOT:-0}" == 1 ]]; then chk "$INDEX_CURSOR_ROOT/cursors" "Adwaita cursor theme"; fi
chk "$DATA/icons/default/index.theme" "default cursor theme"; chk "/usr/share/wayland-sessions/the-index.desktop" "GDM THE INDEX session"
GDM_SERVICE="${INDEX_GDM_SERVICE:-gdm.service}"
systemctl is-enabled --quiet "$GDM_SERVICE" && ok "GDM enabled" || { bad "GDM is not enabled ($GDM_SERVICE)"; FAIL=1; }
if [[ -x "$HOME/.local/bin/index-power" ]]; then
  POWER_STATE="$("$HOME/.local/bin/index-power" state 2>/dev/null || true)"
  POWER_PROFILE_OK="${POWER_STATE%%$'\t'*}"
  [[ "$POWER_PROFILE_OK" == 1 ]] && ok "power profile backend available" || { bad "power profile backend unavailable"; FAIL=1; }
fi
(( FAIL == 0 )) || { bad "installation verification failed"; exit 1; }
