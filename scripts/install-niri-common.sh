#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
trap 'bad "niri installation failed at line $LINENO"; exit 1' ERR

: "${INDEX_POLKIT_AGENT:?distro adapter must set INDEX_POLKIT_AGENT}"
: "${INDEX_CURSOR_ROOT:?distro adapter must set INDEX_CURSOR_ROOT}"
: "${INDEX_FILE_ROLLER_DESKTOP:?distro adapter must set INDEX_FILE_ROLLER_DESKTOP}"
: "${INDEX_COMPLETION_FIRST_LINE:?distro adapter must set INDEX_COMPLETION_FIRST_LINE}"
: "${INDEX_GDM_SERVICE:=gdm.service}"

say "backing up files managed by THE INDEX..."
bash "$SCRIPT_DIR/index-backup"
ok "pre-install backup created"

say "enabling PipeWire/WirePlumber user services..."
if systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
  ok "PipeWire/WirePlumber user services enabled"
else
  bad "could not enable PipeWire/WirePlumber user services for $USER"
  note "Run this from the target user's login session and rerun the installer."
  exit 1
fi

say "installing THE INDEX Niri session..."
sudo install -Dm644 "$INDEX_ROOT/niri/session/the-index-niri.desktop" /usr/share/wayland-sessions/the-index-niri.desktop
ok "THE INDEX (Niri) registered with GDM"

if command -v flatpak >/dev/null 2>&1; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
fi

say "installing fonts..."
mkdir -p "$HOME/.local/share/fonts" "$CFG/fontconfig"
shopt -s nullglob
fonts=("$INDEX_ROOT"/assets/*.ttf "$INDEX_ROOT"/assets/*.otf)
((${#fonts[@]})) || { bad "no bundled fonts found in assets/"; exit 1; }
cp -f "${fonts[@]}" "$HOME/.local/share/fonts/"
shopt -u nullglob
cp -f "$INDEX_ROOT/labwc/config/fontconfig/fonts.conf" "$CFG/fontconfig/fonts.conf"
fc-cache -f >/dev/null

say "configuring icon and cursor themes..."
ICON_THEME="Papirus-Dark"; CURSOR_THEME="Adwaita"; CURSOR_SIZE=24
[[ -f "/usr/share/icons/$ICON_THEME/index.theme" ]] || { bad "icon theme missing: $ICON_THEME"; exit 1; }
[[ -d "$INDEX_CURSOR_ROOT/cursors" ]] || { bad "cursor theme missing: $INDEX_CURSOR_ROOT"; exit 1; }
mkdir -p "$HOME/.local/share/icons/default"
printf '[Icon Theme]\nInherits=%s\n' "$CURSOR_THEME" > "$HOME/.local/share/icons/default/index.theme"

say "installing Niri configuration..."
mkdir -p "$CFG/niri" "$CFG/the-index"
# Static policy is refreshed on updates. Settings-managed state and custom.kdl
# remain user/session state and are not replaced by normal updates.
cp -f "$INDEX_ROOT/niri/config/config.kdl" "$CFG/niri/config.kdl"
cp -f "$INDEX_ROOT/niri/config/index-autostart" "$CFG/niri/index-autostart"
chmod +x "$CFG/niri/index-autostart"
for managed in input.kdl outputs.kdl cursor.kdl; do
  if [[ ! -f "$CFG/niri/$managed" ]]; then cp -f "$INDEX_ROOT/niri/config/$managed" "$CFG/niri/$managed"; fi
done
cp -f "$INDEX_ROOT/wallpaper/the-index.png" "$CFG/the-index/wall.png"
printf 'niri\n' > "$CFG/the-index/compositor"

NIRI_CONFIG="$CFG/niri/config.kdl" niri validate
ok "Niri configuration validated"

say "installing GTK theme..."
rm -rf "$THEMES/the-index"
mkdir -p "$THEMES/the-index/gtk-3.0" "$THEMES/the-index/gtk-4.0"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$THEMES/the-index/gtk-3.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$THEMES/the-index/gtk-4.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/index.theme" "$THEMES/the-index/index.theme"
mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0"
cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-3.0/settings.ini"
cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-4.0/settings.ini"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$CFG/gtk-3.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

say "configuring Niri desktop portals..."
mkdir -p "$CFG/xdg-desktop-portal"
cp -f "$INDEX_ROOT/niri/config/portal/niri-portals.conf" "$CFG/xdg-desktop-portal/niri-portals.conf"
# Niri/xdg-desktop-portal-gnome provides screencasting; THE INDEX deliberately
# uses the GTK FileChooser so Thunar users do not require Nautilus.
ok "Niri portal preference installed"

say "installing Quickshell configuration..."
SAVED_VID=""
if [[ -f "$CFG/quickshell/lock/assets/intro.mp4" ]]; then SAVED_VID="$(mktemp --suffix=.index-intro.mp4)"; cp -f "$CFG/quickshell/lock/assets/intro.mp4" "$SAVED_VID"; fi
rm -rf "$CFG/quickshell"; mkdir -p "$CFG/quickshell"
cp -rf "$INDEX_ROOT/quickshell/." "$CFG/quickshell/"
mkdir -p "$CFG/quickshell/lock/assets/sounds" "$CFG/quickshell/assets/sounds/ui"
shopt -s nullglob
lock_assets=("$INDEX_ROOT"/assets/*.ttf "$INDEX_ROOT"/assets/*.png "$INDEX_ROOT"/assets/*.jpg); ((${#lock_assets[@]})) && cp -f "${lock_assets[@]}" "$CFG/quickshell/lock/assets/"
lock_sounds=("$INDEX_ROOT"/assets/sounds/*.wav "$INDEX_ROOT"/assets/sounds/*.mp3 "$INDEX_ROOT"/assets/sounds/*.ogg); ((${#lock_sounds[@]})) && cp -f "${lock_sounds[@]}" "$CFG/quickshell/lock/assets/sounds/"
ui_sounds=("$INDEX_ROOT"/assets/sounds/ui/*.wav "$INDEX_ROOT"/assets/sounds/ui/*.mp3 "$INDEX_ROOT"/assets/sounds/ui/*.ogg); ((${#ui_sounds[@]})) && cp -f "${ui_sounds[@]}" "$CFG/quickshell/assets/sounds/ui/"
shopt -u nullglob
DEST_VID="$CFG/quickshell/lock/assets/intro.mp4"; VID_SRC=""
for candidate in "$INDEX_ROOT/assets/intro.mp4" "$INDEX_ROOT/intro.mp4" "$INDEX_ROOT/quickshell/lock/assets/intro.mp4" "$HOME/Videos/intro.mp4"; do [[ -f "$candidate" ]] && { VID_SRC="$candidate"; break; }; done
if [[ -n "$VID_SRC" ]]; then cp -f "$VID_SRC" "$DEST_VID"; elif [[ -n "$SAVED_VID" && -f "$SAVED_VID" ]]; then cp -f "$SAVED_VID" "$DEST_VID"; fi
[[ -n "$SAVED_VID" ]] && rm -f "$SAVED_VID"

say "installing application configuration..."
mkdir -p "$CFG/wofi" "$CFG/fastfetch" "$CFG/foot"
cp -f "$INDEX_ROOT/wofi/config" "$CFG/wofi/config"
cp -f "$INDEX_ROOT/wofi/style.css" "$CFG/wofi/style.css"
cp -rf "$INDEX_ROOT/fastfetch/." "$CFG/fastfetch/"
cp -f "$INDEX_ROOT/labwc/config/foot.ini" "$CFG/foot/foot.ini"
say "configuring Fish shell..."; bash "$INDEX_ROOT/install-fish.sh"

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
for helper in index-doctor index-backup index-restore index-uninstall index-update index-appearance index-audio index-network index-bluetooth index-power index-input index-clipboard index-notifications index-settings index-lock index-idle index-displays index-logout; do
  install -m755 "$INDEX_ROOT/scripts/$helper" "$HOME/.local/bin/$helper"
done
install -m755 "$INDEX_ROOT/labwc/app-fixes/index-default-apps" "$HOME/.local/bin/index-default-apps"
install -m755 "$INDEX_ROOT/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"

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

sudo systemctl enable "$INDEX_GDM_SERVICE"

say "validating Niri installation..."
NIRI_CONFIG="$CFG/niri/config.kdl" niri validate
[[ -x "$HOME/.local/bin/index-displays" && -x "$HOME/.local/bin/index-lock" && -x "$HOME/.local/bin/index-idle" && -x "$HOME/.local/bin/index-logout" ]] || { bad "Niri helpers missing"; exit 1; }
[[ -f "$CFG/quickshell/shell.qml" && -f "$CFG/quickshell/DisplaysPanel.qml" ]] || { bad "Quickshell installation incomplete"; exit 1; }
[[ -f "$CFG/xdg-desktop-portal/niri-portals.conf" ]] || { bad "Niri portal preference missing"; exit 1; }

ok "THE INDEX Niri backend installed"
printf '\n%s\n' "$INDEX_COMPLETION_FIRST_LINE"
printf '%s\n' "The existing labwc configuration was not removed. Select THE INDEX (Niri) in GDM to test the scrolling backend."
printf '%s\n' "Advanced Niri overrides can be placed in ~/.config/niri/custom.kdl."
