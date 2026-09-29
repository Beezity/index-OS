#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "Debian Niri installation failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Debian/Niri"
command -v apt-get >/dev/null 2>&1 || { bad "Debian with apt is required."; exit 1; }
[[ -r /etc/os-release ]] || { bad "could not read /etc/os-release"; exit 1; }
. /etc/os-release
[[ "${ID:-}" == debian ]] || { bad "This installer is intended for Debian Linux."; exit 1; }
if [[ "${VERSION_CODENAME:-}" == trixie ]]; then DEBIAN_LABEL="Debian 13 (Trixie)"; DEBIAN_TRACK=trixie
elif [[ "${VERSION:-}" == *sid* || "${PRETTY_NAME:-}" == *"/sid"* || "${PRETTY_NAME:-}" == *" sid"* ]]; then DEBIAN_LABEL="Debian Sid"; DEBIAN_TRACK=sid
else bad "Debian 13 (trixie) or Sid is required; detected: ${PRETTY_NAME:-unknown}"; exit 1; fi
note "detected $DEBIAN_LABEL"

say "backing up before package changes..."
bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1
sudo apt-get update

# Unlike Fedora/Arch, Niri is not guaranteed to exist in every supported Debian
# suite. Never silently build an untracked compositor from source: only enable
# this backend when the configured Debian repositories provide a new-enough package.
for pkg in niri xwayland-satellite; do
  apt-cache show "$pkg" >/dev/null 2>&1 || { bad "$pkg is unavailable from the configured Debian repositories"; note "The labwc installer remains supported; retry Niri when Debian packages niri >= 26.04."; exit 1; }
done
NIRI_CANDIDATE="$(apt-cache policy niri | awk '/Candidate:/ {print $2; exit}')"
[[ -n "$NIRI_CANDIDATE" && "$NIRI_CANDIDATE" != '(none)' ]] || { bad "no Niri package candidate"; exit 1; }
NIRI_PLAIN="$(printf '%s' "$NIRI_CANDIDATE" | sed 's/^[0-9]*://' | cut -d- -f1)"
dpkg --compare-versions "$NIRI_PLAIN" ge 26.04 || { bad "niri >= 26.04 is required; repository candidate: $NIRI_CANDIDATE"; exit 1; }

PACKAGES=(
  niri xwayland-satellite xwayland gdm3 swaybg swayidle grim slurp wl-clipboard cliphist
  foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv zathura zathura-pdf-poppler pavucontrol fastfetch qalc
  xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk libnotify-bin playerctl polkit-kde-agent-1 udiskie udisks2 gvfs gvfs-backends tumbler ffmpegthumbnailer
  network-manager nm-connection-editor bluez bluez-tools blueman pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth ffmpeg gstreamer1.0-plugins-good gstreamer1.0-libav
  qt6-wayland qt6ct qt5ct qml6-module-qtcore qml6-module-qtmultimedia brightnessctl upower gammastep gnome-power-manager power-profiles-daemon
  fonts-dejavu fonts-liberation2 fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra papirus-icon-theme adwaita-icon-theme
  cups printer-driver-cups-pdf system-config-printer flatpak git pciutils libxml2-utils util-linux python3
)
MISSING=(); for pkg in "${PACKAGES[@]}"; do apt-cache show "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg"); done
((${#MISSING[@]} == 0)) || { bad "required Debian packages are unavailable: ${MISSING[*]}"; exit 1; }
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"

if ! command -v quickshell >/dev/null 2>&1; then
  if [[ "$DEBIAN_TRACK" == trixie ]]; then
    if ! grep -RqsE '(^|[[:space:]])trixie-backports([[:space:]]|$)' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
      sudo tee /etc/apt/sources.list.d/index-os-trixie-backports.sources >/dev/null <<'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie-backports
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
      sudo apt-get update
    fi
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -t trixie-backports quickshell
  else
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y quickshell
  fi
fi

for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle foot fish fastfetch wofi qalc wl-copy wl-paste cliphist ffmpeg notify-send nmcli bluetoothctl playerctl wpctl powerprofilesctl flock fc-cache xmllint python3; do require_command "$cmd"; done
POLKIT_AGENT="$(dpkg -L polkit-kde-agent-1 | grep '/polkit-kde-authentication-agent-1$' | head -n1 || true)"
[[ -x "$POLKIT_AGENT" ]] || { bad "could not locate KDE polkit agent"; exit 1; }
sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service
sudo systemctl start power-profiles-daemon.service
sudo systemctl enable gdm3.service

export INDEX_POLKIT_AGENT="$POLKIT_AGENT"
export INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita"
export INDEX_FILE_ROLLER_DESKTOP="org.gnome.FileRoller.desktop"
export INDEX_GDM_SERVICE="gdm3.service"
export INDEX_COMPLETION_FIRST_LINE="$DEBIAN_LABEL Niri installation complete. Log out and select THE INDEX (Niri) in GDM."
exec bash "$SCRIPT_DIR/install-niri-common.sh"
