#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/common.sh"
say "validating installed configuration..."
FAIL=0
chk(){ if [[ -e "$1" ]]; then ok "$2"; else bad "$2 (missing: $1)"; FAIL=1; fi; }

COMPOSITOR="${INDEX_VALIDATE_COMPOSITOR:-${INDEX_COMPOSITOR:-}}"
if [[ -z "$COMPOSITOR" ]]; then
  if [[ -n "${NIRI_SOCKET:-}" || "${XDG_CURRENT_DESKTOP:-}" == *niri* || "${XDG_SESSION_DESKTOP:-}" == *niri* ]]; then COMPOSITOR=niri
  elif [[ -f "$CFG/niri/config.kdl" && ! -f "$CFG/labwc/rc.xml" ]]; then COMPOSITOR=niri
  else COMPOSITOR=labwc
  fi
fi
case "$COMPOSITOR" in niri|labwc) ;; *) bad "unknown compositor backend: $COMPOSITOR"; exit 1 ;; esac
note "validating $COMPOSITOR backend"

# Common application/theme surface.
chk "$THEMES/the-index/gtk-3.0/gtk.css" "GTK3 theme"
chk "$THEMES/the-index/gtk-4.0/gtk.css" "GTK4 theme"
chk "$CFG/gtk-3.0/settings.ini" "GTK3 settings"
chk "$CFG/gtk-3.0/gtk.css" "GTK3 user stylesheet"
chk "$CFG/gtk-4.0/settings.ini" "GTK4 settings"
chk "$CFG/gtk-4.0/gtk.css" "GTK4 user stylesheet"
if grep -q '^\.thunar menubar > menuitem' "$CFG/gtk-3.0/gtk.css" && grep -q '^\.thunar toolbar button' "$CFG/gtk-3.0/gtk.css"; then ok "Thunar GTK polish rules"; else bad "Thunar GTK polish rules missing"; FAIL=1; fi
xmllint --noout "$CFG/fontconfig/fonts.conf"

if [[ "$COMPOSITOR" == niri ]]; then
  chk "$CFG/niri/config.kdl" "niri configuration"
  chk "$CFG/niri/index-input.kdl" "managed niri input state"
  chk "$CFG/niri/index-cursor.kdl" "managed niri cursor state"
  chk "$CFG/niri/index-outputs.kdl" "managed niri output state"
  chk "$CFG/the-index/wall.png" "THE INDEX wallpaper"
  chk "$CFG/xdg-desktop-portal/niri-portals.conf" "niri portal routing"
  if command -v niri >/dev/null 2>&1 && NIRI_CONFIG="$CFG/niri/config.kdl" niri validate >/dev/null 2>&1; then ok "niri configuration parses"; else bad "niri configuration validation failed"; FAIL=1; fi
  command -v xwayland-satellite >/dev/null 2>&1 && ok "xwayland-satellite available" || { bad "xwayland-satellite unavailable"; FAIL=1; }
  if grep -q '^Exec=niri-session$' /usr/share/wayland-sessions/the-index.desktop 2>/dev/null; then ok "THE INDEX session launches niri-session"; else bad "THE INDEX niri session entry invalid"; FAIL=1; fi
  if grep -q 'Mod+P' "$CFG/niri/config.kdl" && grep -q 'prescript toggle' "$CFG/niri/config.kdl"; then ok "Prescript Super+P binding"; else bad "Prescript Super+P binding missing"; FAIL=1; fi
  if grep -q 'Mod+Space' "$CFG/niri/config.kdl" && grep -q 'startmenu toggle' "$CFG/niri/config.kdl"; then ok "launcher Super+Space binding"; else bad "launcher Super+Space binding missing"; FAIL=1; fi
else
  xmllint --noout "$CFG/labwc/rc.xml" "$CFG/labwc/menu.xml"
  chk "$CFG/labwc/rc.xml" "labwc rc.xml"; chk "$CFG/labwc/autostart" "labwc autostart"; chk "$CFG/labwc/index-lock" "lock launcher"; chk "$CFG/labwc/index-clip" "clipboard launcher"; chk "$CFG/labwc/index-display-save" "display layout saver"; chk "$CFG/labwc/index-display-restore" "display layout restorer"; chk "$CFG/labwc/wall.png" "wallpaper"; chk "$THEMES/the-index/labwc/themerc" "titlebar theme"
  if grep -q '<font place="ActiveWindow"><name>Perfect DOS VGA 437 Universal</name><size>10</size></font>' "$CFG/labwc/rc.xml" && grep -q '<font place="InactiveWindow"><name>Perfect DOS VGA 437 Universal</name><size>10</size></font>' "$CFG/labwc/rc.xml"; then ok "labwc Unicode-safe DOS title font"; else bad "labwc Unicode-safe DOS title font setting missing"; FAIL=1; fi
  if [[ "${INDEX_VALIDATE_TITLEBAR_BUTTONS:-0}" == 1 ]]; then chk "$THEMES/the-index/labwc/close.xbm" "close button"; chk "$THEMES/the-index/labwc/iconify.xbm" "minimize button"; chk "$THEMES/the-index/labwc/max.xbm" "maximize button"; fi
  if grep -q 'target: "prescript"' "$CFG/quickshell/PrescriptState.qml" && grep -q '<keybind key="W-p">' "$CFG/labwc/rc.xml"; then ok "Prescript IPC toggle and Super+P binding"; else bad "Prescript IPC toggle or Super+P binding missing"; FAIL=1; fi
  if grep -q 'target: "startmenu"' "$CFG/quickshell/StartMenuState.qml" && grep -q 'target: "startmenu-"' "$CFG/quickshell/Bar.qml" && grep -q '<keybind key="W-space">' "$CFG/labwc/rc.xml"; then ok "multimonitor launcher IPC and Super+Space binding"; else bad "launcher IPC router or Super+Space binding missing"; FAIL=1; fi
fi

# Shared Quickshell implementation and helper APIs.
chk "$CFG/quickshell/shell.qml" "Quickshell shell"; chk "$CFG/quickshell/Bar.qml" "top bar"; chk "$CFG/quickshell/StartMenuState.qml" "launcher IPC router"; chk "$CFG/quickshell/ClipboardPopup.qml" "clipboard popup"; chk "$CFG/quickshell/Notifications.qml" "notification server"; chk "$CFG/quickshell/NotifHistory.qml" "notification history"; chk "$CFG/quickshell/NotificationPrefs.qml" "notification preferences"; chk "$CFG/quickshell/NotificationPanel.qml" "notification settings panel"; chk "$CFG/quickshell/BluetoothMenu.qml" "Bluetooth panel"; chk "$CFG/quickshell/AppearancePanel.qml" "appearance panel"; chk "$CFG/quickshell/AudioPanel.qml" "audio panel"; chk "$CFG/quickshell/NetworkPanel.qml" "network panel"; chk "$CFG/quickshell/PowerPanel.qml" "power panel"; chk "$CFG/quickshell/DisplaysPanel.qml" "display panel"; chk "$CFG/quickshell/InputPanel.qml" "input panel"; chk "$CFG/quickshell/Prescript.qml" "Prescript widget"; chk "$CFG/quickshell/PrescriptState.qml" "shared Prescript state"; chk "$CFG/quickshell/lock/lock.qml" "INDEX lock"
chk "$CFG/foot/foot.ini" "Foot config"; chk "$CFG/fish/config.fish" "Fish config"; chk "/usr/share/icons/Papirus-Dark/index.theme" "Papirus-Dark icon theme"
for helper in index-session-start index-lock index-logout index-idle index-display-save index-display-restore index-appearance index-audio index-network index-bluetooth index-power index-input index-clipboard index-notifications index-settings; do chk "$HOME/.local/bin/$helper" "$helper helper"; done
if grep -q 'model: Quickshell.screens' "$CFG/quickshell/shell.qml" && grep -q 'screen: modelData' "$CFG/quickshell/shell.qml"; then ok "per-monitor shell surfaces enabled"; else bad "per-monitor shell surfaces missing"; FAIL=1; fi
command -v wlr-randr >/dev/null 2>&1 && ok "wlr-randr display backend available" || { bad "wlr-randr display backend unavailable"; FAIL=1; }
if [[ "${INDEX_VALIDATE_CURSOR_ROOT:-0}" == 1 ]]; then chk "$INDEX_CURSOR_ROOT/cursors" "Adwaita cursor theme"; fi
chk "$DATA/icons/default/index.theme" "default cursor theme"; chk "/usr/share/wayland-sessions/the-index.desktop" "GDM THE INDEX session"
GDM_SERVICE="${INDEX_GDM_SERVICE:-gdm.service}"
systemctl is-enabled --quiet "$GDM_SERVICE" && ok "GDM enabled" || { bad "GDM is not enabled ($GDM_SERVICE)"; FAIL=1; }

if [[ -x "$HOME/.local/bin/index-power" ]]; then
  POWER_STATE="$("$HOME/.local/bin/index-power" state 2>/dev/null || true)"
  POWER_PROFILE_OK="${POWER_STATE%%$'\t'*}"
  [[ "$POWER_PROFILE_OK" == 1 ]] && ok "power profile backend available" || { bad "power profile backend unavailable"; FAIL=1; }
fi
if [[ -x "$HOME/.local/bin/index-input" ]]; then
  INPUT_STATE="$(INDEX_INPUT_BACKEND="$COMPOSITOR" "$HOME/.local/bin/index-input" state 2>/dev/null || true)"
  INPUT_BACKEND_OK="${INPUT_STATE%%$'\t'*}"
  [[ "$INPUT_BACKEND_OK" == 1 ]] && ok "$COMPOSITOR input backend available" || { bad "$COMPOSITOR input backend unavailable"; FAIL=1; }
fi
if [[ -x "$HOME/.local/bin/index-clipboard" ]]; then
  CLIP_STATE="$("$HOME/.local/bin/index-clipboard" dump 2>/dev/null | head -n1 || true)"
  [[ "$CLIP_STATE" == $'@status\t1\t'* ]] && ok "clipboard backend available" || { bad "clipboard backend unavailable"; FAIL=1; }
fi
if [[ -x "$HOME/.local/bin/index-notifications" ]]; then
  NOTIFY_STATE="$("$HOME/.local/bin/index-notifications" state 2>/dev/null || true)"
  [[ "$NOTIFY_STATE" == $'1\t'* ]] && ok "notification preferences backend available" || { bad "notification preferences unavailable"; FAIL=1; }
fi
(( FAIL == 0 )) || { bad "installation verification failed"; exit 1; }
