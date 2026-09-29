#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Fedora/niri"
command -v dnf >/dev/null 2>&1 || { bad "Fedora Linux with dnf is required."; exit 1; }
[[ -r /etc/fedora-release ]] || { bad "This installer is intended for Fedora Linux."; exit 1; }
FEDORA_VERSION="$(rpm -E %fedora)"
[[ "$FEDORA_VERSION" =~ ^[0-9]+$ ]] || { bad "could not determine Fedora release"; exit 1; }
(( FEDORA_VERSION >= 43 )) || { bad "Fedora 43 or newer is required; detected Fedora $FEDORA_VERSION"; exit 1; }
note "detected Fedora $FEDORA_VERSION"
validate_repository_layout

say "backing up files managed by THE INDEX..."
bash "$SCRIPT_DIR/index-backup"
export INDEX_BACKUP_DONE=1
ok "pre-install backup created"

say "installing Fedora dependencies..."
PACKAGES=(
  niri xwayland-satellite gdm
  swaybg swayidle wlr-randr wdisplays grim slurp wl-clipboard cliphist
  foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv
  zathura zathura-pdf-mupdf pavucontrol fastfetch qalculate
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
  libnotify playerctl polkit-kde udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer
  NetworkManager nm-connection-editor nm-connection-editor-desktop bluez bluez-tools blueman
  pipewire pipewire-pulseaudio wireplumber gstreamer1-plugins-good gstreamer1-plugin-libav
  qt6-qtmultimedia qt6-qtsvg qt6-qtdeclarative qt6-qtwayland qt6ct qt5ct
  brightnessctl upower gammastep gnome-power-manager
  dejavu-sans-fonts liberation-fonts-all google-noto-fonts-all papirus-icon-theme papirus-icon-theme-dark
  adwaita-cursor-theme cups cups-pdf system-config-printer flatpak git pciutils libxml2 util-linux
)

# Fedora's ffmpeg-free conflicts with RPM Fusion's full ffmpeg package. Keep an
# already-installed ffmpeg provider instead of asking DNF to replace it.
if command -v ffmpeg >/dev/null 2>&1; then
  note "existing ffmpeg provider detected; leaving it unchanged"
else
  PACKAGES+=(ffmpeg-free)
fi

# tuned-ppd and power-profiles-daemon intentionally provide the same D-Bus API
# and conflict at the RPM level. Respect whichever backend is already present.
if rpm -q power-profiles-daemon >/dev/null 2>&1 || command -v powerprofilesctl >/dev/null 2>&1; then
  POWER_BACKEND="power-profiles-daemon"
  note "existing power-profiles-daemon detected; leaving it in place"
elif rpm -q tuned-ppd >/dev/null 2>&1; then
  POWER_BACKEND="tuned-ppd"
  note "existing tuned-ppd detected"
else
  POWER_BACKEND="tuned-ppd"
  PACKAGES+=(tuned-ppd)
fi

sudo dnf -y install "${PACKAGES[@]}"
ok "official Fedora dependencies installed"

say "installing Quickshell..."
sudo dnf -y install dnf5-plugins || sudo dnf -y install dnf-plugins-core
dnf copr --help >/dev/null 2>&1 || { bad "DNF COPR support is unavailable; cannot install Quickshell."; exit 1; }
if ! sudo dnf -y copr enable nett00n/hyprland; then
  bad "could not enable nett00n/hyprland COPR for Fedora $FEDORA_VERSION; Quickshell is required"
  exit 1
fi
if ! sudo dnf -y install quickshell; then
  bad "Quickshell is unavailable from nett00n/hyprland for Fedora $FEDORA_VERSION"
  exit 1
fi
ok "Quickshell installed"

for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle foot fish fastfetch wofi qalc grim slurp wl-copy wl-paste cliphist ffmpeg notify-send nmcli nm-connection-editor bluetoothctl playerctl wpctl wlr-randr wdisplays gnome-power-statistics busctl flock fc-cache xmllint; do
  require_command "$cmd"
done

QS_VERSION="$(rpm -q --qf '%{VERSION}' quickshell)"
[[ "$(printf '%s\n%s\n' 0.3.0 "$QS_VERSION" | sort -V | head -n1)" == "0.3.0" ]] || { bad "quickshell >= 0.3.0 is required; installed: $QS_VERSION"; exit 1; }
ok "Quickshell $QS_VERSION"

NIRI_VERSION="$(niri --version | awk '{print $2}' | head -n1)"
[[ -n "$NIRI_VERSION" ]] || { bad "could not determine niri version"; exit 1; }
ok "niri $NIRI_VERSION"

sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service
if [[ "$POWER_BACKEND" == power-profiles-daemon ]]; then
  sudo systemctl start power-profiles-daemon.service
  INDEX_POWER_PROFILE_SERVICE="power-profiles-daemon.service"
else
  sudo systemctl enable --now tuned.service
  sudo systemctl start tuned-ppd.service
  INDEX_POWER_PROFILE_SERVICE="tuned-ppd.service"
fi
sudo systemctl enable gdm.service

export INDEX_COMPOSITOR=niri
export INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita"
export INDEX_FILE_ROLLER_DESKTOP="org.gnome.FileRoller.desktop"
export INDEX_VALIDATE_CURSOR_ROOT=1 INDEX_COMPLETION_EXTRA=$'\n   Super+Return  terminal      Super+Space  app menu\n   Super+O       overview      Super+L      lock\n   Super+1..5    workspaces    Super+Shift+S screenshot\n'
export INDEX_POWER_PROFILE_SERVICE
export INDEX_GDM_SERVICE="gdm.service"
export INDEX_COMPLETION_FIRST_LINE="Fedora $FEDORA_VERSION installation complete. GDM is installed and enabled. Reboot or log out, then select THE INDEX from GDM's session menu."
exec bash "$SCRIPT_DIR/install-niri-common.sh"
