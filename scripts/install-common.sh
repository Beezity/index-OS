#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
trap 'bad "installation failed at line $LINENO"; exit 1' ERR

: "${INDEX_DEX_COMMAND:?distro adapter must set INDEX_DEX_COMMAND}"
: "${INDEX_POLKIT_AGENT:?distro adapter must set INDEX_POLKIT_AGENT}"
: "${INDEX_CURSOR_ROOT:?distro adapter must set INDEX_CURSOR_ROOT}"
: "${INDEX_FILE_ROLLER_DESKTOP:?distro adapter must set INDEX_FILE_ROLLER_DESKTOP}"
: "${INDEX_COMPLETION_FIRST_LINE:?distro adapter must set INDEX_COMPLETION_FIRST_LINE}"
: "${INDEX_COMPLETION_EXTRA:=}"
: "${INDEX_VALIDATE_TITLEBAR_BUTTONS:=0}"

say "backing up files managed by THE INDEX..."
bash "$SCRIPT_DIR/index-backup"
ok "pre-install backup created"

say "enabling PipeWire/WirePlumber user services..."
if systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
  ok "PipeWire/WirePlumber user services enabled"
else
  bad "could not enable PipeWire/WirePlumber user services for $USER"
  note "Run this from the target user's login session, then rerun the installer:"
  note "  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service"
  exit 1
fi

say "installing GDM session..."
sudo install -Dm644 "$INDEX_ROOT/labwc/session/the-index.desktop" /usr/share/wayland-sessions/the-index.desktop
ok "THE INDEX session registered with GDM"

if command -v flatpak >/dev/null 2>&1; then
  if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then note "Flathub configured for this user"; else note "Flathub setup failed; continuing because it is optional"; fi
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
ICON_THEME="Papirus-Dark"; CURSOR_THEME="capitaine-cursors"; CURSOR_SIZE=24
[[ -f "/usr/share/icons/$ICON_THEME/index.theme" ]] || { bad "icon theme missing after installation: $ICON_THEME"; exit 1; }
[[ -d "$INDEX_CURSOR_ROOT/cursors" ]] || { bad "cursor theme missing after installation: $INDEX_CURSOR_ROOT"; exit 1; }
if [[ "${INDEX_REQUIRE_CURSOR_INDEX:-0}" == 1 ]]; then [[ -f "$INDEX_CURSOR_ROOT/index.theme" ]] || { bad "Capitaine cursor theme missing after installation"; exit 1; }; fi
mkdir -p "$HOME/.local/share/icons/default"
printf '[Icon Theme]\nInherits=%s\n' "$CURSOR_THEME" > "$HOME/.local/share/icons/default/index.theme"

say "installing labwc configuration..."
rm -rf "$CFG/labwc"; mkdir -p "$CFG/labwc"
cp -f "$INDEX_ROOT/labwc/config/rc.xml" "$CFG/labwc/rc.xml"
cp -f "$INDEX_ROOT/labwc/config/menu.xml" "$CFG/labwc/menu.xml"
cp -f "$INDEX_ROOT/labwc/config/autostart" "$CFG/labwc/autostart"
cp -f "$INDEX_ROOT/labwc/config/environment" "$CFG/labwc/environment"
cp -f "$INDEX_ROOT/wallpaper/the-index.png" "$CFG/labwc/wall.png"
if [[ "$INDEX_DEX_COMMAND" != dex ]]; then sed -i -e "s/command -v dex /command -v $INDEX_DEX_COMMAND /" -e "s/dex -a -e labwc/$INDEX_DEX_COMMAND -a -e labwc/" "$CFG/labwc/autostart"; fi
if [[ "$INDEX_POLKIT_AGENT" != /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]]; then sed -i "s#/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1#$INDEX_POLKIT_AGENT#" "$CFG/labwc/autostart"; fi
[[ -f "$INDEX_ROOT/labwc/config/index.conf" ]] && cp -f "$INDEX_ROOT/labwc/config/index.conf" "$CFG/labwc/index.conf"
for script in index-lock index-logout index-display-save index-display-restore index-idle index-input index-clip; do [[ -f "$INDEX_ROOT/labwc/config/$script" ]] || continue; cp -f "$INDEX_ROOT/labwc/config/$script" "$CFG/labwc/$script"; chmod +x "$CFG/labwc/$script"; done
chmod +x "$CFG/labwc/autostart"

say "installing labwc and GTK themes..."
rm -rf "$THEMES/the-index"; mkdir -p "$THEMES/the-index/labwc" "$THEMES/the-index/gtk-3.0" "$THEMES/the-index/gtk-4.0"
cp -f "$INDEX_ROOT"/labwc/theme/the-index/labwc/* "$THEMES/the-index/labwc/"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$THEMES/the-index/gtk-3.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$THEMES/the-index/gtk-4.0/gtk.css"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/index.theme" "$THEMES/the-index/index.theme"
mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0"
cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-3.0/settings.ini"; cp -f "$INDEX_ROOT/labwc/config/gtk/settings.ini" "$CFG/gtk-4.0/settings.ini"
cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$CFG/gtk-3.0/gtk.css"; cp -f "$INDEX_ROOT/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

say "installing Quickshell configuration..."
SAVED_VID=""; if [[ -f "$CFG/quickshell/lock/assets/intro.mp4" ]]; then SAVED_VID="$(mktemp --suffix=.index-intro.mp4)"; cp -f "$CFG/quickshell/lock/assets/intro.mp4" "$SAVED_VID"; fi
rm -rf "$CFG/quickshell"; mkdir -p "$CFG/quickshell"; cp -rf "$INDEX_ROOT/quickshell/." "$CFG/quickshell/"; mkdir -p "$CFG/quickshell/lock/assets/sounds" "$CFG/quickshell/assets/sounds/ui"
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
cp -f "$INDEX_ROOT/wofi/config" "$CFG/wofi/config"; cp -f "$INDEX_ROOT/wofi/style.css" "$CFG/wofi/style.css"; cp -rf "$INDEX_ROOT/fastfetch/." "$CFG/fastfetch/"; cp -f "$INDEX_ROOT/labwc/config/foot.ini" "$CFG/foot/foot.ini"
say "configuring Fish shell..."; bash "$INDEX_ROOT/install-fish.sh"
say "configuring desktop portals..."; mkdir -p "$CFG/xdg-desktop-portal/wlr"; cp -f "$INDEX_ROOT/labwc/config/portal/labwc-portals.conf" "$CFG/xdg-desktop-portal/labwc-portals.conf"; cp -f "$INDEX_ROOT/labwc/config/portal/wlr.conf" "$CFG/xdg-desktop-portal/wlr/config"

say "theming Qt applications..."
for V in qt6ct qt5ct; do mkdir -p "$CFG/$V/colors"; cp -f "$INDEX_ROOT/labwc/config/$V/colors/the-index.conf" "$CFG/$V/colors/the-index.conf"; cat > "$CFG/$V/$V.conf" <<QTCONF
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
mkdir -p "$HOME/.local/bin"; install -m755 "$INDEX_ROOT/labwc/app-fixes/index-default-apps" "$HOME/.local/bin/index-default-apps"; install -m755 "$INDEX_ROOT/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"; install -m755 "$INDEX_ROOT/scripts/index-doctor" "$HOME/.local/bin/index-doctor"; install -m755 "$INDEX_ROOT/scripts/index-backup" "$HOME/.local/bin/index-backup"; install -m755 "$INDEX_ROOT/scripts/index-restore" "$HOME/.local/bin/index-restore"; install -m755 "$INDEX_ROOT/scripts/index-uninstall" "$HOME/.local/bin/index-uninstall"; install -m755 "$INDEX_ROOT/scripts/index-update" "$HOME/.local/bin/index-update"; install -m755 "$INDEX_ROOT/scripts/index-appearance" "$HOME/.local/bin/index-appearance"; install -m755 "$INDEX_ROOT/scripts/index-audio" "$HOME/.local/bin/index-audio"; install -m755 "$INDEX_ROOT/scripts/index-network" "$HOME/.local/bin/index-network"; install -m755 "$INDEX_ROOT/scripts/index-bluetooth" "$HOME/.local/bin/index-bluetooth"; xdg-user-dirs-update; mkdir -p "$HOME/Pictures"
setdef(){ local bin="$1" desktop="$2"; shift 2; command -v "$bin" >/dev/null || return 0; local m; for m in "$@"; do xdg-mime default "$desktop" "$m"; done; }
setdef thunar thunar.desktop inode/directory; setdef foot foot.desktop text/plain text/x-shellscript application/x-shellscript; setdef imv imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff; setdef mpv mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/wav audio/x-wav; setdef zathura org.pwmt.zathura.desktop application/pdf application/epub+zip; setdef file-roller "$INDEX_FILE_ROLLER_DESKTOP" application/zip application/x-tar application/gzip application/x-7z-compressed application/vnd.rar; unset -f setdef

bash "$SCRIPT_DIR/validate.sh"
printf '\n%s:: done.%s\n%s   %s\n   Foot launches the Index-themed Fish shell; your account login shell is unchanged.\n   Run index-doctor from any terminal to check the installation.\n   Update THE INDEX later with index-update.\n   Pre-install files were backed up. Use index-restore latest to restore them.\n   Remove Index-managed configuration with index-uninstall.\n   No autologin, bootloader, kernel-command-line, or silent-boot changes were made.\n\n   You can still start THE INDEX from a TTY with:\n     dbus-run-session labwc\n%s%s\n' "$CYAN" "$NC" "$DIM" "$INDEX_COMPLETION_FIRST_LINE" "$INDEX_COMPLETION_EXTRA" "$NC"
