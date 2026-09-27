#!/usr/bin/env bash
set -Eeuo pipefail

CYAN=$'\e[38;2;93;173;226m'; DIM=$'\e[2m'; RED=$'\e[38;2;255;107;107m'; GRN=$'\e[38;2;93;226;133m'; NC=$'\e[0m'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
THEMES="$HOME/.local/share/themes"

say(){ printf '%s::%s %s\n' "$CYAN" "$NC" "$1"; }
ok(){ printf '   %s✓%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ printf '   %s✗%s %s\n' "$RED" "$NC" "$1"; }
note(){ printf '   %s%s%s\n' "$DIM" "$1" "$NC"; }
trap 'bad "installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — labwc"
command -v pacman >/dev/null 2>&1 || { bad "Arch Linux/pacman is required."; exit 1; }

# Validate the checkout before changing the machine.
required_files=(
  wallpaper/the-index.png
  quickshell/shell.qml quickshell/Bar.qml quickshell/lock/lock.qml quickshell/prescript.json
  labwc/config/rc.xml labwc/config/menu.xml labwc/config/autostart labwc/config/environment
  labwc/config/index-lock labwc/config/index-idle labwc/config/index-input labwc/config/index-clip
  labwc/config/fontconfig/fonts.conf labwc/config/gtk/settings.ini
  labwc/config/portal/labwc-portals.conf labwc/config/portal/wlr.conf
  labwc/config/qt5ct/colors/the-index.conf labwc/config/qt6ct/colors/the-index.conf
  labwc/theme/the-index/labwc/themerc
  labwc/theme/the-index-gtk/gtk-3.0/gtk.css labwc/theme/the-index-gtk/gtk-4.0/gtk.css labwc/theme/the-index-gtk/index.theme
  labwc/app-fixes/index-snip labwc/app-fixes/index-default-apps
)
for rel in "${required_files[@]}"; do
  [[ -f "$DIR/$rel" ]] || { bad "repository file missing: $rel"; exit 1; }
done
ok "repository layout validated"

say "installing dependencies..."
PACKAGES=(
  labwc quickshell xorg-xwayland
  swaybg swayidle wlopm wlr-randr nwg-displays grim slurp swappy wl-clipboard cliphist
  foot wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv zathura zathura-pdf-mupdf pavucontrol fastfetch
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk dex libnotify playerctl polkit-gnome udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer
  networkmanager bluez bluez-utils blueman
  pipewire pipewire-pulse wireplumber ffmpeg gst-libav gst-plugins-good
  qt6-multimedia qt6-svg qt6-declarative qt6-wayland qt6ct qt5ct gnome-themes-extra
  fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt
  brightnessctl upower gammastep
  ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
  cups cups-pdf system-config-printer
  flatpak
  git pciutils libxml2
)
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"
ok "all dependencies installed"

for cmd in labwc quickshell swaybg swayidle foot wofi grim slurp swappy wl-copy nmcli bluetoothctl playerctl wpctl fc-cache xmllint; do
  command -v "$cmd" >/dev/null 2>&1 || { bad "required command missing after installation: $cmd"; exit 1; }
done

# Quickshell's generic WindowManager workspace API is required by this config.
QS_VERSION="$(pacman -Q quickshell | awk '{print $2}' | cut -d- -f1)"
if command -v vercmp >/dev/null 2>&1 && (( $(vercmp "$QS_VERSION" 0.3.0) < 0 )); then
  bad "quickshell >= 0.3.0 is required; installed: $QS_VERSION"
  exit 1
fi

sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service

# Flathub is useful but not required for the desktop itself.
if command -v flatpak >/dev/null 2>&1; then
  if flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    note "Flathub configured for this user"
  else
    note "Flathub setup failed; continuing because it is optional"
  fi
fi

say "installing fonts..."
mkdir -p "$HOME/.local/share/fonts" "$CFG/fontconfig"
shopt -s nullglob
fonts=("$DIR"/assets/*.ttf "$DIR"/assets/*.otf)
((${#fonts[@]})) || { bad "no bundled fonts found in assets/"; exit 1; }
cp -f "${fonts[@]}" "$HOME/.local/share/fonts/"
shopt -u nullglob
cp -f "$DIR/labwc/config/fontconfig/fonts.conf" "$CFG/fontconfig/fonts.conf"
fc-cache -f >/dev/null

say "installing labwc configuration..."
rm -rf "$CFG/labwc"
mkdir -p "$CFG/labwc"
cp -f "$DIR/labwc/config/rc.xml" "$CFG/labwc/rc.xml"
cp -f "$DIR/labwc/config/menu.xml" "$CFG/labwc/menu.xml"
cp -f "$DIR/labwc/config/autostart" "$CFG/labwc/autostart"
cp -f "$DIR/labwc/config/environment" "$CFG/labwc/environment"
cp -f "$DIR/wallpaper/the-index.png" "$CFG/labwc/wall.png"
[[ -f "$DIR/labwc/config/index.conf" ]] && cp -f "$DIR/labwc/config/index.conf" "$CFG/labwc/index.conf"
for script in index-lock index-logout index-display-save index-display-restore index-idle index-input index-clip; do
  [[ -f "$DIR/labwc/config/$script" ]] || continue
  cp -f "$DIR/labwc/config/$script" "$CFG/labwc/$script"
  chmod +x "$CFG/labwc/$script"
done
chmod +x "$CFG/labwc/autostart"

say "installing labwc and GTK themes..."
rm -rf "$THEMES/the-index"
mkdir -p "$THEMES/the-index/labwc" "$THEMES/the-index/gtk-3.0" "$THEMES/the-index/gtk-4.0"
cp -f "$DIR"/labwc/theme/the-index/labwc/* "$THEMES/the-index/labwc/"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$THEMES/the-index/gtk-3.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$THEMES/the-index/gtk-4.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/index.theme" "$THEMES/the-index/index.theme"

mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0"
cp -f "$DIR/labwc/config/gtk/settings.ini" "$CFG/gtk-3.0/settings.ini"
cp -f "$DIR/labwc/config/gtk/settings.ini" "$CFG/gtk-4.0/settings.ini"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$CFG/gtk-3.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

say "installing Quickshell configuration..."
SAVED_VID=""
if [[ -f "$CFG/quickshell/lock/assets/intro.mp4" ]]; then
  SAVED_VID="$(mktemp --suffix=.index-intro.mp4)"
  cp -f "$CFG/quickshell/lock/assets/intro.mp4" "$SAVED_VID"
fi
rm -rf "$CFG/quickshell"
mkdir -p "$CFG/quickshell"
cp -rf "$DIR/quickshell/." "$CFG/quickshell/"

mkdir -p "$CFG/quickshell/lock/assets/sounds" "$CFG/quickshell/assets/sounds/ui"
shopt -s nullglob
lock_assets=("$DIR"/assets/*.ttf "$DIR"/assets/*.png "$DIR"/assets/*.jpg)
((${#lock_assets[@]})) && cp -f "${lock_assets[@]}" "$CFG/quickshell/lock/assets/"
lock_sounds=("$DIR"/assets/sounds/*.wav "$DIR"/assets/sounds/*.mp3 "$DIR"/assets/sounds/*.ogg)
((${#lock_sounds[@]})) && cp -f "${lock_sounds[@]}" "$CFG/quickshell/lock/assets/sounds/"
ui_sounds=("$DIR"/assets/sounds/ui/*.wav "$DIR"/assets/sounds/ui/*.mp3 "$DIR"/assets/sounds/ui/*.ogg)
((${#ui_sounds[@]})) && cp -f "${ui_sounds[@]}" "$CFG/quickshell/assets/sounds/ui/"
shopt -u nullglob

DEST_VID="$CFG/quickshell/lock/assets/intro.mp4"
VID_SRC=""
for candidate in "$DIR/assets/intro.mp4" "$DIR/intro.mp4" "$DIR/quickshell/lock/assets/intro.mp4" "$HOME/Videos/intro.mp4"; do
  [[ -f "$candidate" ]] && { VID_SRC="$candidate"; break; }
done
if [[ -n "$VID_SRC" ]]; then
  cp -f "$VID_SRC" "$DEST_VID"
elif [[ -n "$SAVED_VID" && -f "$SAVED_VID" ]]; then
  cp -f "$SAVED_VID" "$DEST_VID"
fi
[[ -n "$SAVED_VID" ]] && rm -f "$SAVED_VID"

say "installing application configuration..."
mkdir -p "$CFG/wofi" "$CFG/fastfetch" "$CFG/foot"
cp -f "$DIR/wofi/config" "$CFG/wofi/config"
cp -f "$DIR/wofi/style.css" "$CFG/wofi/style.css"
cp -rf "$DIR/fastfetch/." "$CFG/fastfetch/"
cp -f "$DIR/labwc/config/foot.ini" "$CFG/foot/foot.ini"

say "configuring desktop portals..."
mkdir -p "$CFG/xdg-desktop-portal/wlr"
cp -f "$DIR/labwc/config/portal/labwc-portals.conf" "$CFG/xdg-desktop-portal/labwc-portals.conf"
cp -f "$DIR/labwc/config/portal/wlr.conf" "$CFG/xdg-desktop-portal/wlr/config"

say "theming Qt applications..."
for V in qt6ct qt5ct; do
  mkdir -p "$CFG/$V/colors"
  cp -f "$DIR/labwc/config/$V/colors/the-index.conf" "$CFG/$V/colors/the-index.conf"
  cat > "$CFG/$V/$V.conf" <<QTCONF
[Appearance]
color_scheme_path=$HOME/.config/$V/colors/the-index.conf
custom_palette=true
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

[[ -x "$DIR/labwc/app-fixes/apply-browser-fixes.sh" ]] && "$DIR/labwc/app-fixes/apply-browser-fixes.sh"
mkdir -p "$HOME/.local/bin"
install -m755 "$DIR/labwc/app-fixes/index-default-apps" "$HOME/.local/bin/index-default-apps"
install -m755 "$DIR/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"

xdg-user-dirs-update
mkdir -p "$HOME/Pictures"
setdef(){ local bin="$1" desktop="$2"; shift 2; command -v "$bin" >/dev/null; local m; for m in "$@"; do xdg-mime default "$desktop" "$m"; done; }
setdef thunar thunar.desktop inode/directory
setdef foot foot.desktop text/plain text/x-shellscript application/x-shellscript
setdef imv imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
setdef mpv mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/wav audio/x-wav
setdef zathura org.pwmt.zathura.desktop application/pdf application/epub+zip
setdef file-roller file-roller.desktop application/zip application/x-tar application/gzip application/x-7z-compressed application/vnd.rar
unset -f setdef

say "validating installed configuration..."
xmllint --noout "$CFG/labwc/rc.xml" "$CFG/labwc/menu.xml" "$CFG/fontconfig/fonts.conf"

FAIL=0
chk(){ if [[ -s "$1" ]]; then ok "$2"; else bad "$2 (missing: $1)"; FAIL=1; fi; }
chk "$CFG/labwc/rc.xml" "labwc rc.xml"
chk "$CFG/labwc/autostart" "labwc autostart"
chk "$CFG/labwc/index-lock" "lock launcher"
chk "$CFG/labwc/wall.png" "wallpaper"
chk "$THEMES/the-index/labwc/themerc" "titlebar theme"
chk "$THEMES/the-index/labwc/close.xbm" "close button"
chk "$THEMES/the-index/labwc/iconify.xbm" "minimize button"
chk "$THEMES/the-index/labwc/max.xbm" "maximize button"
chk "$CFG/quickshell/shell.qml" "Quickshell shell"
chk "$CFG/quickshell/Bar.qml" "top bar"
chk "$CFG/quickshell/lock/lock.qml" "INDEX lock"
chk "$CFG/foot/foot.ini" "Foot config"
(( FAIL == 0 )) || { bad "installation verification failed"; exit 1; }

cat <<DONE

${CYAN}:: done.${NC}
${DIM}   No autologin, bootloader, kernel-command-line, or silent-boot changes were made.

   Start THE INDEX from a TTY with:
     dbus-run-session labwc

   Super+Return  terminal      Super+D  launcher
   Super+Q       close         Super+L  lock
   Super+1..5    desktops      Super+Shift+S  screenshot
${NC}
DONE
