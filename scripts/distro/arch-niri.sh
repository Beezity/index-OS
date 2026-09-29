#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "Arch Niri installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Arch/Niri"
command -v pacman >/dev/null 2>&1 || { bad "Arch Linux/pacman is required."; exit 1; }
say "backing up before package changes..."
bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1

PACKAGES=(
  niri xwayland-satellite xorg-xwayland gdm
  quickshell swaybg swayidle grim slurp wl-clipboard cliphist
  foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv
  zathura zathura-pdf-mupdf pavucontrol fastfetch libqalculate
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk gnome-keyring
  libnotify playerctl polkit-gnome udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer
  networkmanager nm-connection-editor bluez bluez-utils blueman
  pipewire pipewire-pulse wireplumber ffmpeg gst-libav gst-plugins-good
  qt6-multimedia qt6-svg qt6-declarative qt6-wayland qt6ct qt5ct gnome-themes-extra
  brightnessctl upower gammastep gnome-power-manager power-profiles-daemon
  ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra
  papirus-icon-theme adwaita-cursors cups cups-pdf system-config-printer flatpak git pciutils libxml2 util-linux python
)

say "installing Arch Niri dependencies..."
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"
for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle foot fish fastfetch wofi qalc wl-copy wl-paste cliphist ffmpeg notify-send nmcli bluetoothctl playerctl wpctl powerprofilesctl flock fc-cache xmllint python3; do require_command "$cmd"; done
NIRI_VERSION="$(pacman -Q niri | awk '{print $2}' | cut -d- -f1)"
if command -v vercmp >/dev/null 2>&1 && (( $(vercmp "$NIRI_VERSION" 26.04) < 0 )); then bad "niri >= 26.04 is required; installed: $NIRI_VERSION"; exit 1; fi
ok "Niri $NIRI_VERSION"

sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service
sudo systemctl start power-profiles-daemon.service
sudo systemctl enable gdm.service

export INDEX_POLKIT_AGENT="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
export INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita"
export INDEX_FILE_ROLLER_DESKTOP="file-roller.desktop"
export INDEX_GDM_SERVICE="gdm.service"
export INDEX_COMPLETION_FIRST_LINE="Arch Niri installation complete. Log out and select THE INDEX (Niri) in GDM."
exec bash "$SCRIPT_DIR/install-niri-common.sh"
