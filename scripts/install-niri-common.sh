#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
trap 'bad "installation failed at line $LINENO"; exit 1' ERR

: "${INDEX_CURSOR_ROOT:?distro adapter must set INDEX_CURSOR_ROOT}"
: "${INDEX_FILE_ROLLER_DESKTOP:?distro adapter must set INDEX_FILE_ROLLER_DESKTOP}"
: "${INDEX_COMPLETION_FIRST_LINE:?distro adapter must set INDEX_COMPLETION_FIRST_LINE}"
: "${INDEX_COMPLETION_EXTRA:=}"
: "${INDEX_GDM_SERVICE:=gdm.service}"

# Capture the old labwc-managed common input state before replacing helpers.
# This lets an existing THE INDEX installation keep pointer/touchpad behavior on
# its first niri login without copying labwc XML into niri.
OLD_INPUT_STATE=""
if [[ -x "$HOME/.local/bin/index-input" ]]; then
  OLD_INPUT_STATE="$(INDEX_INPUT_BACKEND=labwc "$HOME/.local/bin/index-input" state 2>/dev/null || true)"
fi

if [[ "${INDEX_BACKUP_DONE:-0}" != 1 ]]; then
  say "backing up files managed by THE INDEX..."
  bash "$SCRIPT_DIR/index-backup"
  export INDEX_BACKUP_DONE=1
  ok "pre-install backup created"
fi

say "enabling PipeWire/WirePlumber user services..."
if systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
  ok "PipeWire/WirePlumber user services enabled"
else
  bad "could not enable PipeWire/WirePlumber user services for $USER"
  note "Run this from the target user's login session, then rerun the installer:"
  note "  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service"
  exit 1
fi

say "installing THE INDEX niri session..."
sudo install -Dm644 "$INDEX_ROOT/niri/session/the-index.desktop" /usr/share/wayland-sessions/the-index.desktop
ok "THE INDEX niri session registered with GDM"

if command -v flatpak >/dev/null 2>&1; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || note "Flathub setup failed; continuing because it is optional"
fi

say "installing fonts..."
mkdir -p "$HOME/.local/share/fonts" "$CFG/fontconfig"
shopt -s nullglob
fonts=("$INDEX_ROOT"/assets/*.ttf "$INDEX_ROOT"/assets/*.otf)
((${#fonts[@]})) || { bad "no bundled fonts found in assets/"; exit 1; }
cp -f "${fonts[@]}" "$HOME/.local/share/fonts/"
shopt -u nullglob
# The fontconfig/GTK/Qt assets are compositor-neutral even though their source
# path predates the niri migration. Keep one canonical copy until Debian moves.
cp -f "$INDEX_ROOT/labwc/config/fontconfig/fonts.conf" "$CFG/fontconfig/fonts.conf"
fc-cache -f >/dev/null

say "configuring icon and cursor themes..."
ICON_THEME="Papirus-Dark"; CURSOR_THEME="Adwaita"; CURSOR_SIZE=24
[[ -f "/usr/share/icons/$ICON_THEME/index.theme" ]] || { bad "icon theme missing after installation: $ICON_THEME"; exit 1; }
[[ -d "$INDEX_CURSOR_ROOT/cursors" ]] || { bad "cursor theme missing after installation: $INDEX_CURSOR_ROOT"; exit 1; }
mkdir -p "$HOME/.local/share/icons/default"
printf '[Icon Theme]\nInherits=%s\n' "$CURSOR_THEME" > "$HOME/.local/share/icons/default/index.theme"

say "installing niri configuration..."
mkdir -p "$CFG/niri" "$CFG/the-index"
STATE_TMP="$(mktemp -d)"
cleanup_state(){ rm -rf "$STATE_TMP"; }
trap 'cleanup_state; bad "installation failed at line $LINENO"; exit 1' ERR
for f in index-input.kdl index-cursor.kdl index-outputs.kdl; do
  [[ -f "$CFG/niri/$f" ]] && cp -f "$CFG/niri/$f" "$STATE_TMP/$f"
done
cp -f "$INDEX_ROOT/niri/config/config.kdl" "$CFG/niri/config.kdl"
for f in index-input.kdl index-cursor.kdl index-outputs.kdl; do
  if [[ -f "$STATE_TMP/$f" ]]; then cp -f "$STATE_TMP/$f" "$CFG/niri/$f"; else cp -f "$INDEX_ROOT/niri/config/$f" "$CFG/niri/$f"; fi
done
cleanup_state
trap 'bad "installation failed at line $LINENO"; exit 1' ERR
cp -f "$INDEX_ROOT/wallpaper/the-index.png" "$CFG/the-index/wall.png"
chmod 600 "$CFG/niri"/index-*.kdl 2>/dev/null || true

say "installing GTK theme..."
rm -rf "$THEMES/the-index"
mkdir -p "$THEMES/the-index/gtk-3.0" "$THEMES/the-index/gtk-4.0" "$CFG/gtk-3.0" "$CFG/gtk-4.0"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$THEMES/the-index/gtk-3.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$THEMES/the-index/gtk-4.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/index.theme" "$THEMES/the-index/index.theme"
cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-3.0/settings.ini"
cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-4.0/settings.ini"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$CFG/gtk-3.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

say "installing Quickshell configuration..."
SAVED_VID=""
if [[ -f "$CFG/quickshell/lock/assets/intro.mp4" ]]; then
  SAVED_VID="$(mktemp --suffix=.index-intro.mp4)"
  cp -f "$CFG/quickshell/lock/assets/intro.mp4" "$SAVED_VID"
fi
rm -rf "$CFG/quickshell"; mkdir -p "$CFG/quickshell"
cp -rf "$INDEX_ROOT/quickshell/." "$CFG/quickshell/"
mkdir -p "$CFG/quickshell/lock/assets/sounds" "$CFG/quickshell/assets/sounds/ui"
shopt -s nullglob
lock_assets=("$INDEX_ROOT"/assets/*.ttf "$INDEX_ROOT"/assets/*.png "$INDEX_ROOT"/assets/*.jpg); ((${#lock_assets[@]})) && cp -f "${lock_assets[@]}" "$CFG/quickshell/lock/assets/"
lock_sounds=("$INDEX_ROOT"/assets/sounds/*.wav "$INDEX_ROOT"/assets/sounds/*.mp3 "$INDEX_ROOT"/assets/sounds/*.ogg); ((${#lock_sounds[@]})) && cp -f "${lock_sounds[@]}" "$CFG/quickshell/lock/assets/sounds/"
ui_sounds=("$INDEX_ROOT"/assets/sounds/ui/*.wav "$INDEX_ROOT"/assets/sounds/ui/*.mp3 "$INDEX_ROOT"/assets/sounds/ui/*.ogg); ((${#ui_sounds[@]})) && cp -f "${ui_sounds[@]}" "$CFG/quickshell/assets/sounds/ui/"
shopt -u nullglob
DEST_VID="$CFG/quickshell/lock/assets/intro.mp4"; VID_SRC=""
for candidate in "$INDEX_ROOT/assets/intro.mp4" "$INDEX_ROOT/intro.mp4" "$INDEX_ROOT/quickshell/lock/assets/intro.mp4" "$HOME/Videos/intro.mp4"; do
  [[ -f "$candidate" ]] && { VID_SRC="$candidate"; break; }
done
if [[ -n "$VID_SRC" ]]; then cp -f "$VID_SRC" "$DEST_VID"; elif [[ -n "$SAVED_VID" && -f "$SAVED_VID" ]]; then cp -f "$SAVED_VID" "$DEST_VID"; fi
[[ -n "$SAVED_VID" ]] && rm -f "$SAVED_VID"

say "installing application configuration..."
mkdir -p "$CFG/wofi" "$CFG/fastfetch" "$CFG/foot"
cp -f "$INDEX_ROOT/wofi/config" "$CFG/wofi/config"
cp -f "$INDEX_ROOT/wofi/style.css" "$CFG/wofi/style.css"
cp -rf "$INDEX_ROOT/fastfetch/." "$CFG/fastfetch/"
cp -f "$INDEX_ROOT/labwc/config/foot.ini" "$CFG/foot/foot.ini"
say "configuring Fish shell..."
bash "$INDEX_ROOT/install-fish.sh"

say "configuring desktop portals..."
mkdir -p "$CFG/xdg-desktop-portal"
cp -f "$INDEX_ROOT/niri/config/portal/niri-portals.conf" "$CFG/xdg-desktop-portal/niri-portals.conf"

say "theming Qt applications..."
for V in qt6ct qt5ct; do
  mkdir -p "$CFG/$V/colors"
  cp -f "$INDEX_ROOT/labwc/config/$V/colors/the-index.conf" "$CFG/$V/colors/the-index.conf"
  cat > "$CFG/$V/$V.conf" <<QTCONF
[Appearance]
color_scheme_path=$HOME/.config/$V/colors/the-index.conf
custom_palette=true
icon_theme=$ICON_THEME
standard_dialogs=default
style=Fusion
[Fonts]
fixed="Perfect DOS VGA 437 Universal,11,-1,5,50,0,0,0,0,0"
general="Perfect DOS VGA 437 Universal,11,-1,5,50,0,0,0,0,0"
[Interface]
menus_have_icons=true
toolbutton_style=4
QTCONF
done

[[ -x "$INDEX_ROOT/labwc/app-fixes/apply-browser-fixes.sh" ]] && "$INDEX_ROOT/labwc/app-fixes/apply-browser-fixes.sh"

say "installing THE INDEX helpers..."
mkdir -p "$HOME/.local/bin"
for helper in \
  index-session-start index-lock index-logout index-idle index-display-save index-display-restore \
  index-doctor index-backup index-restore index-uninstall index-update index-appearance index-audio \
  index-network index-bluetooth index-power index-input index-clipboard index-notifications index-settings; do
  install -m755 "$INDEX_ROOT/scripts/$helper" "$HOME/.local/bin/$helper"
done
install -m755 "$INDEX_ROOT/labwc/app-fixes/index-default-apps" "$HOME/.local/bin/index-default-apps"
install -m755 "$INDEX_ROOT/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"

# Preserve the common input values from an existing labwc installation only on
# the first niri migration; later installs keep the managed niri files above.
if [[ -n "$OLD_INPUT_STATE" && ! -s "$STATE_TMP/index-input.kdl" ]]; then
  IFS=$'\t' read -r old_ok old_speed old_natural _old_touchpad old_tap <<< "$OLD_INPUT_STATE"
  if [[ "$old_ok" == 1 ]]; then
    INDEX_INPUT_BACKEND=niri "$HOME/.local/bin/index-input" set-speed "$old_speed" || true
    INDEX_INPUT_BACKEND=niri "$HOME/.local/bin/index-input" set-natural-scroll "$old_natural" || true
    INDEX_INPUT_BACKEND=niri "$HOME/.local/bin/index-input" set-tap "$old_tap" || true
  fi
fi

# Apply the shared appearance state to the niri cursor include. Wallpaper is
# started by index-session-start after login.
if [[ -x "$HOME/.local/bin/index-appearance" ]]; then
  "$HOME/.local/bin/index-appearance" apply >/dev/null 2>&1 || true
fi

# When migrating from a running wlroots session, snapshot its current monitor
# arrangement into niri's persistent output include. If no output-management
# session is available now, niri will safely auto-configure on first login.
if command -v wlr-randr >/dev/null 2>&1 && wlr-randr >/dev/null 2>&1; then
  INDEX_COMPOSITOR=niri "$HOME/.local/bin/index-display-save" >/dev/null 2>&1 || true
fi

xdg-user-dirs-update
mkdir -p "$HOME/Pictures/Screenshots"
setdef(){ local bin="$1" desktop="$2"; shift 2; command -v "$bin" >/dev/null || return 0; local m; for m in "$@"; do xdg-mime default "$desktop" "$m"; done; }
setdef thunar thunar.desktop inode/directory
setdef foot foot.desktop text/plain text/x-shellscript application/x-shellscript
setdef imv imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
setdef mpv mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/wav audio/x-wav
setdef zathura org.pwmt.zathura.desktop application/pdf application/epub+zip
setdef file-roller "$INDEX_FILE_ROLLER_DESKTOP" application/zip application/x-tar application/gzip application/x-7z-compressed application/vnd.rar
unset -f setdef

say "validating niri configuration..."
NIRI_CONFIG="$CFG/niri/config.kdl" niri validate
ok "niri configuration accepted"

INDEX_VALIDATE_COMPOSITOR=niri bash "$SCRIPT_DIR/validate.sh"
printf '\n%s:: done.%s\n%s   %s\n   Foot launches the Index-themed Fish shell; your account login shell is unchanged.\n   Run index-doctor from any terminal to check the installation.\n   Update THE INDEX later with index-update.\n   Pre-install files were backed up. Use index-restore latest to restore them.\n   Remove Index-managed configuration with index-uninstall.\n   No autologin, bootloader, kernel-command-line, or silent-boot changes were made.\n\n   You can start THE INDEX from a TTY with:\n     niri-session\n%s%s\n' "$CYAN" "$NC" "$DIM" "$INDEX_COMPLETION_FIRST_LINE" "$INDEX_COMPLETION_EXTRA" "$NC"
