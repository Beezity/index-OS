#!/usr/bin/env bash

CYAN=$'\e[38;2;93;173;226m'; DIM=$'\e[2m'; RED=$'\e[38;2;255;107;107m'; GRN=$'\e[38;2;93;226;133m'; NC=$'\e[0m'
INDEX_ROOT="${INDEX_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# Preserve the paths used by the original installers. XDG path support can be a separate change.
CFG="$HOME/.config"
DATA="$HOME/.local/share"
THEMES="$DATA/themes"

say(){ printf '%s::%s %s\n' "$CYAN" "$NC" "$1"; }
ok(){ printf '   %s✓%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ printf '   %s✗%s %s\n' "$RED" "$NC" "$1"; }
note(){ printf '   %s%s%s\n' "$DIM" "$1" "$NC"; }
require_command(){ command -v "$1" >/dev/null 2>&1 || { bad "required command missing after installation: $1"; return 1; }; }
require_file(){ [[ -f "$INDEX_ROOT/$1" ]] || { bad "repository file missing: $1"; return 1; }; }

INDEX_REQUIRED_FILES=(
  wallpaper/the-index.png quickshell/shell.qml quickshell/Bar.qml quickshell/SettingsPanel.qml quickshell/AppearancePanel.qml quickshell/AudioPanel.qml quickshell/NetworkPanel.qml quickshell/BluetoothMenu.qml quickshell/PowerPanel.qml quickshell/InputPanel.qml quickshell/ClipboardPopup.qml quickshell/Notifications.qml quickshell/NotifHistory.qml quickshell/NotificationPrefs.qml quickshell/NotificationPanel.qml quickshell/lock/lock.qml quickshell/prescript.json
  labwc/config/rc.xml labwc/config/menu.xml labwc/config/autostart labwc/config/environment
  labwc/config/index-lock labwc/config/index-idle labwc/config/index-clip
  labwc/config/fontconfig/fonts.conf labwc/config/gtk/settings.ini
  labwc/config/portal/labwc-portals.conf labwc/config/portal/wlr.conf
  labwc/config/qt5ct/colors/the-index.conf labwc/config/qt6ct/colors/the-index.conf
  labwc/theme/the-index/labwc/themerc
  labwc/theme/the-index-gtk/gtk-3.0/gtk.css labwc/theme/the-index-gtk/gtk-4.0/gtk.css labwc/theme/the-index-gtk/index.theme
  labwc/app-fixes/index-snip labwc/app-fixes/index-default-apps labwc/session/the-index.desktop
  fish/config.fish install-fish.sh scripts/index-doctor scripts/index-backup scripts/index-restore scripts/index-update scripts/index-appearance scripts/index-audio scripts/index-network scripts/index-bluetooth scripts/index-power scripts/index-input scripts/index-clipboard scripts/index-notifications
)
validate_repository_layout(){
  local rel
  for rel in "${INDEX_REQUIRED_FILES[@]}"; do require_file "$rel"; done
  ok "repository layout validated"
}
