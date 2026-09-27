#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

say "validating installed configuration..."
xmllint --noout "$CFG/labwc/rc.xml" "$CFG/labwc/menu.xml" "$CFG/fontconfig/fonts.conf"
fish -n "$CFG/fish/config.fish"
FAIL=0
chk(){ if [[ -e "$1" ]]; then ok "$2"; else bad "$2 (missing: $1)"; FAIL=1; fi; }
chk "$CFG/labwc/rc.xml" "labwc rc.xml"
chk "$CFG/labwc/autostart" "labwc autostart"
chk "$CFG/labwc/index-lock" "lock launcher"
chk "$CFG/labwc/wall.png" "wallpaper"
chk "$THEMES/the-index/labwc/themerc" "titlebar theme"
if [[ "${INDEX_VALIDATE_TITLEBAR_BUTTONS:-0}" == 1 ]]; then
  chk "$THEMES/the-index/labwc/close.xbm" "close button"
  chk "$THEMES/the-index/labwc/iconify.xbm" "minimize button"
  chk "$THEMES/the-index/labwc/max.xbm" "maximize button"
fi
chk "$CFG/quickshell/shell.qml" "Quickshell shell"
chk "$CFG/quickshell/Bar.qml" "top bar"
chk "$CFG/quickshell/lock/lock.qml" "INDEX lock"
chk "$CFG/foot/foot.ini" "Foot config"
chk "$CFG/fish/config.fish" "Fish config"
chk "/usr/share/icons/Papirus-Dark/index.theme" "Papirus-Dark icon theme"
chk "$INDEX_CURSOR_ROOT/cursors" "Capitaine cursor theme"
chk "$DATA/icons/default/index.theme" "default cursor theme"
chk "/usr/share/wayland-sessions/the-index.desktop" "GDM THE INDEX session"
systemctl is-enabled --quiet gdm.service && ok "GDM enabled" || { bad "GDM is not enabled"; FAIL=1; }
(( FAIL == 0 )) || { bad "installation verification failed"; exit 1; }
