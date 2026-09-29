#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "Fedora Niri installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Fedora/Niri"
command -v dnf >/dev/null 2>&1 || { bad "Fedora Linux with dnf is required."; exit 1; }
[[ -r /etc/fedora-release ]] || { bad "This installer is intended for Fedora Linux."; exit 1; }
FEDORA_VERSION="$(rpm -E %fedora)"
[[ "$FEDORA_VERSION" =~ ^[0-9]+$ ]] || { bad "could not determine Fedora release"; exit 1; }
(( FEDORA_VERSION >= 43 )) || { bad "Fedora 43 or newer is required; detected Fedora $FEDORA_VERSION"; exit 1; }
note "detected Fedora $FEDORA_VERSION"

say "backing up before package changes..."
bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1

PACKAGES=(
  niri xwayland-satellite niri-settings xorg-x11-server-Xwayland gdm
  swaybg swayidle grim slurp wl-clipboard cliphist
  foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv
  zathura zathura-pdf-mupdf pavucontrol fastfetch qalculate
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk gnome-keyring
  libnotify playerctl polkit-kde udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer
  NetworkManager nm-connection-editor nm-connection-editor-desktop bluez bluez-tools blueman
  pipewire pipewire-pulseaudio wireplumber gstreamer1-plugins-good gstreamer1-plugin-libav
  qt6-qtmultimedia qt6-qtsvg qt6-qtdeclarative qt6-qtwayland qt6ct qt5ct
  brightnessctl upower gammastep gnome-power-manager
  dejavu-sans-fonts liberation-fonts-all google-noto-fonts-all papirus-icon-theme papirus-icon-theme-dark
  adwaita-cursor-theme cups cups-pdf system-config-printer flatpak git pciutils libxml2 util-linux python3
)

if command -v ffmpeg >/dev/null 2>&1; then note "existing ffmpeg provider detected; leaving it unchanged"; else PACKAGES+=(ffmpeg-free); fi
if rpm -q power-profiles-daemon >/dev/null 2>&1 || command -v powerprofilesctl >/dev/null 2>&1; then
  POWER_BACKEND="power-profiles-daemon"; note "existing power-profiles-daemon detected"
elif rpm -q tuned-ppd >/dev/null 2>&1; then
  POWER_BACKEND="tuned-ppd"
else
  POWER_BACKEND="tuned-ppd"; PACKAGES+=(tuned-ppd)
fi

say "installing Fedora Niri dependencies..."
sudo dnf -y install "${PACKAGES[@]}"

say "installing Quickshell..."
if ! command -v quickshell >/dev/null 2>&1; then
  sudo dnf -y install dnf5-plugins || sudo dnf -y install dnf-plugins-core
  dnf copr --help >/dev/null 2>&1 || { bad "DNF COPR support is unavailable"; exit 1; }
  sudo dnf -y copr enable nett00n/hyprland
  sudo dnf -y install quickshell
fi

for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle foot fish fastfetch wofi qalc wl-copy wl-paste cliphist ffmpeg notify-send nmcli bluetoothctl playerctl wpctl fc-cache xmllint python3; do require_command "$cmd"; done
NIRI_VERSION="$(rpm -q --qf '%{VERSION}' niri)"
[[ "$(printf '%s\n%s\n' 26.04 "$NIRI_VERSION" | sort -V | head -n1)" == 26.04 ]] || { bad "niri >= 26.04 is required for managed optional includes; installed: $NIRI_VERSION"; exit 1; }
ok "Niri $NIRI_VERSION"

sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service
if [[ "$POWER_BACKEND" == power-profiles-daemon ]]; then
  sudo systemctl start power-profiles-daemon.service
else
  sudo systemctl enable --now tuned.service
  sudo systemctl start tuned-ppd.service
fi
sudo systemctl enable gdm.service

export INDEX_POLKIT_AGENT="/usr/libexec/kf6/polkit-kde-authentication-agent-1"
export INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita"
export INDEX_FILE_ROLLER_DESKTOP="org.gnome.FileRoller.desktop"
export INDEX_GDM_SERVICE="gdm.service"
export INDEX_COMPLETION_FIRST_LINE="Fedora $FEDORA_VERSION Niri installation complete. Log out and select THE INDEX (Niri) in GDM."
exec bash "$SCRIPT_DIR/install-niri-common.sh"
