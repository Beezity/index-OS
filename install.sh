#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
#  WILL OF THE CITY :: THE INDEX — labwc (Arch Linux)
#  Installs all required packages first, then lays down the
#  desktop configuration. No autologin or bootloader changes.
# ============================================================

CYAN=$'\e[38;2;93;173;226m'
DIM=$'\e[2m'
RED=$'\e[38;2;255;107;107m'
GRN=$'\e[38;2;93;226;133m'
NC=$'\e[0m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$HOME/.config"
THEMES="$HOME/.local/share/themes"

say(){ printf '%s::%s %s\n' "$CYAN" "$NC" "$1"; }
ok(){ printf '   %s✓%s %s\n' "$GRN" "$NC" "$1"; }
bad(){ printf '   %s✗%s %s\n' "$RED" "$NC" "$1"; }
note(){ printf '   %s%s%s\n' "$DIM" "$1" "$NC"; }

trap 'bad "installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — labwc"

[[ -d "$DIR/labwc" ]] || {
  bad "run this from inside the index-OS repository (labwc/ not found)"
  exit 1
}

command -v pacman >/dev/null 2>&1 || {
  bad "This installer requires Arch Linux or an Arch-based distribution with pacman."
  exit 1
}

# ---------- 1. install every dependency before configuration ----------
say "installing dependencies..."

PACKAGES=(
  # compositor / shell
  labwc
  quickshell
  xorg-xwayland

  # Wayland desktop utilities
  swaybg
  swayidle
  wlopm
  wlr-randr
  nwg-displays
  wtype
  grim
  slurp
  swappy
  wl-clipboard
  cliphist

  # applications
  foot
  wofi
  thunar
  thunar-archive-plugin
  thunar-volman
  xarchiver
  file-roller
  imv
  mpv
  zathura
  zathura-pdf-mupdf
  pavucontrol
  fastfetch

  # desktop integration
  xdg-utils
  xdg-user-dirs
  xdg-desktop-portal
  xdg-desktop-portal-wlr
  xdg-desktop-portal-gtk
  dex
  libnotify
  playerctl
  polkit-gnome
  udiskie
  udisks2
  gvfs
  gvfs-mtp
  tumbler
  ffmpegthumbnailer

  # networking / Bluetooth
  networkmanager
  bluez
  bluez-utils
  blueman

  # audio / multimedia
  pipewire
  pipewire-pulse
  wireplumber
  ffmpeg
  gst-libav
  gst-plugins-good

  # Qt / GTK integration
  qt6-multimedia
  qt6-svg
  qt6-declarative
  qt6-wayland
  qt6ct
  qt5ct
  gnome-themes-extra

  # input
  fcitx5
  fcitx5-configtool
  fcitx5-gtk
  fcitx5-qt

  # hardware controls
  brightnessctl
  upower
  gammastep

  # fonts
  ttf-dejavu
  ttf-liberation
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  noto-fonts-extra

  # printing
  cups
  cups-pdf
  system-config-printer

  # Flatpak / software center
  flatpak
  gnome-software

  # misc
  git
  pciutils
)

sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"
ok "all dependencies installed"

# Verify the key executables immediately. If any are missing, stop.
for cmd in labwc quickshell swaybg swayidle foot wofi wtype grim slurp wl-copy nmcli bluetoothctl playerctl; do
  command -v "$cmd" >/dev/null 2>&1 || {
    bad "required command is missing after package installation: $cmd"
    exit 1
  }
done

# ---------- 1b. Flatpak + Flathub ----------
say "configuring Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

if ! flatpak info io.github.kolunmi.Bazaar >/dev/null 2>&1; then
  say "installing Bazaar (Flathub app store)..."
  sudo flatpak install -y --noninteractive flathub io.github.kolunmi.Bazaar
else
  note "Bazaar already installed"
fi

# Printing service.
sudo systemctl enable --now cups.service

# Enable core system services used by the shell. NetworkManager and bluetooth
# may already be enabled; repeated enable calls are harmless.
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service

# ---------- 2. font ----------
say "installing bundled fonts..."
mkdir -p "$HOME/.local/share/fonts"
shopt -s nullglob
font_files=("$DIR"/assets/*.ttf "$DIR"/assets/*.otf)
if ((${#font_files[@]})); then
  cp -f "${font_files[@]}" "$HOME/.local/share/fonts/"
fi
shopt -u nullglob

# Optional local font. No AUR helper is required by this installer.
if [[ -f "$DIR/assets/LanaPixel.ttf" ]]; then
  cp -f "$DIR/assets/LanaPixel.ttf" "$HOME/.local/share/fonts/"
fi

fc-cache -f
mkdir -p "$CFG/fontconfig"
cp -f "$DIR/labwc/config/fontconfig/fonts.conf" "$CFG/fontconfig/fonts.conf"
fc-cache -f

# ---------- 3. titlebar theme ----------
say "installing THE INDEX titlebar theme..."
rm -rf "$THEMES/the-index"
mkdir -p "$THEMES/the-index/labwc"
cp -f "$DIR"/labwc/theme/the-index/labwc/* "$THEMES/the-index/labwc/"

# ---------- 4. labwc config ----------
say "writing labwc config..."
rm -rf "$CFG/labwc"
mkdir -p "$CFG/labwc"

cp -f "$DIR/labwc/config/rc.xml" "$CFG/labwc/rc.xml"
cp -f "$DIR/labwc/config/menu.xml" "$CFG/labwc/menu.xml"
cp -f "$DIR/wallpaper/the-index.png" "$CFG/labwc/wall.png"

[[ -f "$DIR/labwc/config/index.conf" ]] && cp -f "$DIR/labwc/config/index.conf" "$CFG/labwc/index.conf"

for script in \
  index-lock \
  index-logout \
  index-display-save \
  index-display-restore \
  index-idle \
  index-input \
  index-clip; do
  if [[ -f "$DIR/labwc/config/$script" ]]; then
    cp -f "$DIR/labwc/config/$script" "$CFG/labwc/$script"
    chmod +x "$CFG/labwc/$script"
  fi
done

# Preserve the repo's current EN/TH input setup.
mkdir -p "$CFG/fcitx5/conf"
[[ -f "$CFG/fcitx5/profile" ]] || cp -f "$DIR/labwc/config/fcitx5-profile" "$CFG/fcitx5/profile"
[[ -f "$CFG/fcitx5/config" ]] || cp -f "$DIR/labwc/config/fcitx5-config" "$CFG/fcitx5/config"

cp -f "$DIR/labwc/config/autostart" "$CFG/labwc/autostart"
chmod +x "$CFG/labwc/autostart"
cp -f "$DIR/labwc/config/environment" "$CFG/labwc/environment"

# ---------- 5. quickshell shell ----------
say "installing quickshell shell..."
SAVED_VID=""
if [[ -f "$CFG/quickshell/lock/assets/intro.mp4" ]]; then
  SAVED_VID="/tmp/.index-intro-saved.mp4"
  cp -f "$CFG/quickshell/lock/assets/intro.mp4" "$SAVED_VID"
fi

rm -rf "$CFG/quickshell"
mkdir -p "$CFG/quickshell"
cp -rf "$DIR/quickshell/." "$CFG/quickshell/"

[[ -f "$CFG/quickshell/prescript.json" ]] || {
  bad "Prescript JSON missing after copy"
  exit 1
}

say "installing lock assets..."
mkdir -p "$CFG/quickshell/lock/assets/sounds" "$CFG/quickshell/assets/sounds/ui"

shopt -s nullglob
lock_assets=("$DIR"/assets/*.ttf "$DIR"/assets/*.png "$DIR"/assets/*.jpg)
((${#lock_assets[@]})) && cp -f "${lock_assets[@]}" "$CFG/quickshell/lock/assets/"
lock_sounds=("$DIR"/assets/sounds/*)
((${#lock_sounds[@]})) && cp -f "${lock_sounds[@]}" "$CFG/quickshell/lock/assets/sounds/"
ui_sounds=("$DIR"/assets/sounds/ui/*.wav "$DIR"/assets/sounds/ui/*.mp3)
((${#ui_sounds[@]})) && cp -f "${ui_sounds[@]}" "$CFG/quickshell/assets/sounds/ui/"
shopt -u nullglob

DEST_VID="$CFG/quickshell/lock/assets/intro.mp4"
VID_SRC=""
for candidate in \
  "$DIR/assets/intro.mp4" \
  "$DIR/intro.mp4" \
  "$DIR/quickshell/lock/assets/intro.mp4" \
  "$HOME/index-OS/assets/intro.mp4" \
  "$HOME/intro.mp4" \
  "$HOME/Videos/intro.mp4" \
  "$HOME/Downloads/intro.mp4"; do
  if [[ -f "$candidate" ]]; then
    VID_SRC="$candidate"
    break
  fi
done

if [[ -n "$VID_SRC" ]]; then
  cp -f "$VID_SRC" "$DEST_VID"
  note "intro video installed from: $VID_SRC"
elif [[ -n "$SAVED_VID" && -f "$SAVED_VID" ]]; then
  cp -f "$SAVED_VID" "$DEST_VID"
  note "kept existing intro video"
else
  note "no intro.mp4 found; lock starts without an intro video"
fi
rm -f "$SAVED_VID"

# Downscale intro video on software/VM graphics only.
if [[ -f "$DEST_VID" ]]; then
  SOFTGPU=0
  if lspci | grep -qiE 'virtio|qxl|vga.*(cirrus|bochs|vmware)'; then
    SOFTGPU=1
  fi
  if grep -qiE 'virtio|llvmpipe|software' /sys/class/drm/*/device/uevent 2>/dev/null; then
    SOFTGPU=1
  fi
  [[ -e /dev/dri/renderD128 ]] || SOFTGPU=1

  if [[ "$SOFTGPU" == "1" ]]; then
    say "software/VM GPU detected; transcoding intro video to 720p30..."
    ffmpeg -y -i "$DEST_VID" -vf 'scale=-2:720' -r 30 -c:v libx264 -preset veryfast -crf 24 -c:a aac "$DEST_VID.vm.mp4"
    mv -f "$DEST_VID.vm.mp4" "$DEST_VID"
  fi
fi

# ---------- 6. launcher + terminal + app theming ----------
say "installing application configuration..."
mkdir -p "$CFG/wofi" "$CFG/fastfetch" "$CFG/foot"
cp -f "$DIR/wofi/config" "$CFG/wofi/config"
cp -f "$DIR/wofi/style.css" "$CFG/wofi/style.css"
cp -rf "$DIR/fastfetch/." "$CFG/fastfetch/"
cp -f "$DIR/labwc/config/foot.ini" "$CFG/foot/foot.ini"

# GTK theme
mkdir -p "$THEMES/the-index/gtk-3.0" "$THEMES/the-index/gtk-4.0"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$THEMES/the-index/gtk-3.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$THEMES/the-index/gtk-4.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/index.theme" "$THEMES/the-index/index.theme"

mkdir -p "$CFG/gtk-3.0" "$CFG/gtk-4.0"
cp -f "$DIR/labwc/config/gtk/settings.ini" "$CFG/gtk-3.0/settings.ini"
cp -f "$DIR/labwc/config/gtk/settings.ini" "$CFG/gtk-4.0/settings.ini"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-3.0/gtk.css" "$CFG/gtk-3.0/gtk.css"
cp -f "$DIR/labwc/theme/the-index-gtk/gtk-4.0/gtk.css" "$CFG/gtk-4.0/gtk.css"

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'the-index' || true
  gsettings set org.gnome.desktop.wm.preferences button-layout ':' || true
fi

# Screen sharing portal
say "configuring screen sharing portal..."
mkdir -p "$CFG/xdg-desktop-portal/wlr"
cp -f "$DIR/labwc/config/portal/labwc-portals.conf" "$CFG/xdg-desktop-portal/labwc-portals.conf"
cp -f "$DIR/labwc/config/portal/wlr.conf" "$CFG/xdg-desktop-portal/wlr/config"

# Qt palette
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

# Browser fixes are optional because browsers may not yet be installed.
if [[ -x "$DIR/labwc/app-fixes/apply-browser-fixes.sh" ]]; then
  "$DIR/labwc/app-fixes/apply-browser-fixes.sh" || true
fi

mkdir -p "$HOME/.local/bin"
cp -f "$DIR/labwc/app-fixes/index-default-apps" "$HOME/.local/bin/index-default-apps"
cp -f "$DIR/labwc/app-fixes/index-snip" "$HOME/.local/bin/index-snip"
chmod +x "$HOME/.local/bin/index-default-apps" "$HOME/.local/bin/index-snip"

# Add ~/.local/bin to shells, but do not auto-start labwc and do not enable autologin.
touch "$HOME/.bash_profile"
if ! grep -qF '$HOME/.local/bin' "$HOME/.bash_profile"; then
  printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bash_profile"
fi

mkdir -p "$HOME/.config/fish"
touch "$HOME/.config/fish/config.fish"
if ! grep -qF 'fish_add_path "$HOME/.local/bin"' "$HOME/.config/fish/config.fish"; then
  printf '\nfish_add_path "$HOME/.local/bin"\n' >> "$HOME/.config/fish/config.fish"
fi

# ---------- 7. standard folders + MIME defaults ----------
xdg-user-dirs-update
mkdir -p "$HOME/Pictures"

setdef() {
  local binary="$1"
  local desktop="$2"
  shift 2
  command -v "$binary" >/dev/null 2>&1 || return 1
  local mime
  for mime in "$@"; do
    xdg-mime default "$desktop" "$mime"
  done
}

setdef thunar thunar.desktop inode/directory
setdef foot foot.desktop text/plain text/x-shellscript application/x-shellscript
setdef imv imv.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff
setdef mpv mpv.desktop video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/wav audio/x-wav
setdef zathura org.pwmt.zathura.desktop application/pdf application/epub+zip
setdef file-roller file-roller.desktop application/zip application/x-tar application/gzip application/x-7z-compressed application/vnd.rar
unset -f setdef

# ---------- 8. verification ----------
echo
say "verifying install..."

FAIL=0
chk() {
  if [[ -s "$1" ]]; then
    ok "$2"
  else
    bad "$2 (MISSING: $1)"
    FAIL=1
  fi
}

chk "$CFG/labwc/rc.xml" "labwc rc.xml"
chk "$CFG/labwc/autostart" "labwc autostart"
chk "$CFG/labwc/index-lock" "lock launcher"
chk "$CFG/labwc/wall.png" "wallpaper"
chk "$THEMES/the-index/labwc/themerc" "titlebar themerc"
chk "$THEMES/the-index/labwc/close-active.png" "bracket button [X]"
chk "$THEMES/the-index/labwc/iconify-active.png" "bracket button [_]"
chk "$THEMES/the-index/labwc/max-active.png" "bracket button [#]"
chk "$CFG/quickshell/shell.qml" "quickshell shell"
chk "$CFG/quickshell/Bar.qml" "bar"
chk "$CFG/quickshell/Atmosphere.qml" "atmosphere"
chk "$CFG/quickshell/Notifications.qml" "notifications"
chk "$CFG/quickshell/Settings.qml" "settings panel"
chk "$CFG/quickshell/Calendar.qml" "calendar + media"
chk "$CFG/quickshell/lock/lock.qml" "INDEX lock"
chk "$CFG/foot/foot.ini" "Foot terminal config"

for cmd in labwc quickshell swaybg foot wofi; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd installed"
  else
    bad "$cmd NOT installed"
    FAIL=1
  fi
done

if [[ "$FAIL" != "0" ]]; then
  bad "installation verification failed"
  exit 1
fi

cat <<DONE

${CYAN}:: done.${NC}
${DIM}   No autologin or bootloader modifications were made.

   Start THE INDEX from a TTY with:

     dbus-run-session labwc

   Inside labwc:
     Super+Return  terminal      Super+D  launcher
     Super+Q       close         Super+L  INDEX lock
     Super+1..5    desktops      right-click  menu
${NC}
DONE
