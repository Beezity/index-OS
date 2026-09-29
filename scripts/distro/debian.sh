#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"; trap 'bad "installation failed at line $LINENO"; exit 1' ERR
say "WILL OF THE CITY :: THE INDEX — Debian/labwc"
command -v apt-get >/dev/null 2>&1 || { bad "Debian with apt is required."; exit 1; }
[[ -r /etc/os-release ]] || { bad "could not read /etc/os-release"; exit 1; }; . /etc/os-release
[[ "${ID:-}" == debian ]] || { bad "This installer is intended for Debian Linux."; exit 1; }
if [[ "${VERSION_CODENAME:-}" == trixie ]]; then DEBIAN_LABEL="Debian 13 (Trixie)"; DEBIAN_TRACK=trixie
elif [[ "${VERSION:-}" == *sid* || "${PRETTY_NAME:-}" == *"/sid"* || "${PRETTY_NAME:-}" == *" sid"* ]]; then DEBIAN_LABEL="Debian Sid"; DEBIAN_TRACK=sid
else bad "Debian 13 (trixie) or Sid is required; detected: ${PRETTY_NAME:-unknown}"; exit 1; fi
note "detected $DEBIAN_LABEL"; validate_repository_layout
say "backing up files managed by THE INDEX..."; bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1; ok "pre-install backup created"
say "updating APT metadata..."; sudo apt-get update
PACKAGES=(labwc xwayland gdm3 swaybg swayidle wlopm wlr-randr wdisplays grim slurp wl-clipboard cliphist foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv zathura zathura-pdf-poppler pavucontrol fastfetch qalc xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk dex libnotify-bin playerctl polkit-kde-agent-1 udiskie udisks2 gvfs gvfs-backends tumbler ffmpegthumbnailer network-manager nm-connection-editor bluez bluez-tools blueman pipewire pipewire-pulse wireplumber libspa-0.2-bluetooth ffmpeg gstreamer1.0-plugins-good gstreamer1.0-libav qt6-wayland qt6ct qt5ct qml6-module-qtcore qml6-module-qtmultimedia brightnessctl upower gammastep gnome-power-manager power-profiles-daemon fonts-dejavu fonts-liberation2 fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji fonts-noto-extra papirus-icon-theme adwaita-icon-theme cups printer-driver-cups-pdf system-config-printer flatpak git pciutils libxml2-utils util-linux python3)
MISSING=(); for pkg in "${PACKAGES[@]}"; do apt-cache show "$pkg" >/dev/null 2>&1 || MISSING+=("$pkg"); done
((${#MISSING[@]} == 0)) || { bad "required Debian packages are unavailable: ${MISSING[*]}"; exit 1; }
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"; ok "official Debian dependencies installed"
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
else sudo DEBIAN_FRONTEND=noninteractive apt-get install -y quickshell; fi
for cmd in labwc quickshell swaybg swayidle foot fish fastfetch wofi qalc grim slurp wl-copy wl-paste cliphist ffmpeg notify-send nmcli nm-connection-editor bluetoothctl playerctl wpctl wdisplays gnome-power-statistics powerprofilesctl flock fc-cache xmllint python3; do require_command "$cmd"; done
QS_VERSION="$(dpkg-query -W -f='${Version}' quickshell 2>/dev/null | sed 's/^[0-9]*://' | cut -d- -f1)"; dpkg --compare-versions "$QS_VERSION" ge 0.3.0 || { bad "quickshell >= 0.3.0 is required; installed: $QS_VERSION"; exit 1; }
POLKIT_AGENT="$(dpkg -L polkit-kde-agent-1 | grep '/polkit-kde-authentication-agent-1$' | head -n1 || true)"; [[ -x "$POLKIT_AGENT" ]] || { bad "could not locate polkit-kde-authentication-agent-1"; exit 1; }
sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service; sudo systemctl start power-profiles-daemon.service; sudo systemctl enable gdm3.service
mkdir -p "$HOME/.local/bin" "$HOME/.config/the-index"; install -m755 "$INDEX_ROOT/scripts/index-displays" "$HOME/.local/bin/index-displays"; printf 'labwc\n' > "$HOME/.config/the-index/compositor"
export INDEX_DEX_COMMAND="dex" INDEX_POLKIT_AGENT="$POLKIT_AGENT" INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita" INDEX_FILE_ROLLER_DESKTOP="org.gnome.FileRoller.desktop"
export INDEX_REQUIRE_CURSOR_INDEX=0 INDEX_VALIDATE_CURSOR_ROOT=1 INDEX_VALIDATE_TITLEBAR_BUTTONS=0 INDEX_POWER_PROFILE_SERVICE="power-profiles-daemon.service" INDEX_GDM_SERVICE="gdm3.service" INDEX_COMPLETION_EXTRA=""
export INDEX_COMPLETION_FIRST_LINE="$DEBIAN_LABEL installation complete. GDM is installed and enabled. Reboot to log in and select THE INDEX from GDM's session menu."
exec bash "$SCRIPT_DIR/install-common.sh"
