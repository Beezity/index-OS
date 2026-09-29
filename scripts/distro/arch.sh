#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"; trap 'bad "installation failed at line $LINENO"; exit 1' ERR
say "WILL OF THE CITY :: THE INDEX — Arch/niri"
command -v pacman >/dev/null 2>&1 || { bad "Arch Linux/pacman is required."; exit 1; }
validate_repository_layout
say "backing up files managed by THE INDEX..."; bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1; ok "pre-install backup created"
say "installing dependencies..."
PACKAGES=(niri xwayland-satellite quickshell gdm swaybg swayidle wlr-randr wdisplays grim slurp wl-clipboard cliphist foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv zathura zathura-pdf-mupdf pavucontrol fastfetch libqalculate xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk libnotify playerctl polkit-gnome udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer networkmanager nm-connection-editor bluez bluez-utils blueman pipewire pipewire-pulse wireplumber ffmpeg gst-libav gst-plugins-good qt6-multimedia qt6-svg qt6-declarative qt6-wayland qt6ct qt5ct gnome-themes-extra brightnessctl upower gammastep gnome-power-manager power-profiles-daemon ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra papirus-icon-theme adwaita-cursors cups cups-pdf system-config-printer flatpak git pciutils libxml2 util-linux)
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"; ok "all dependencies installed"
for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle foot fish fastfetch wofi qalc grim slurp wl-copy wl-paste cliphist ffmpeg notify-send nmcli nm-connection-editor bluetoothctl playerctl wpctl wlr-randr wdisplays gnome-power-statistics powerprofilesctl flock fc-cache xmllint; do require_command "$cmd"; done
QS_VERSION="$(pacman -Q quickshell | awk '{print $2}' | cut -d- -f1)"; if command -v vercmp >/dev/null 2>&1 && (( $(vercmp "$QS_VERSION" 0.3.1) < 0 )); then bad "quickshell >= 0.3.1 is required; installed: $QS_VERSION"; exit 1; fi
NIRI_VERSION="$(niri --version | awk '{print $2}' | head -n1)"; [[ -n "$NIRI_VERSION" ]] || { bad "could not determine niri version"; exit 1; }; ok "niri $NIRI_VERSION"
sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service; sudo systemctl start power-profiles-daemon.service; sudo systemctl enable gdm.service
export INDEX_COMPOSITOR=niri INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita" INDEX_FILE_ROLLER_DESKTOP="file-roller.desktop"
export INDEX_VALIDATE_CURSOR_ROOT=1 INDEX_POWER_PROFILE_SERVICE="power-profiles-daemon.service" INDEX_GDM_SERVICE="gdm.service"
export INDEX_COMPLETION_FIRST_LINE="GDM is installed and enabled. Reboot or log out, then select THE INDEX from GDM's session menu."
export INDEX_COMPLETION_EXTRA=$'\n   Super+Return  terminal      Super+Space  app menu\n   Super+O       overview      Super+L      lock\n   Super+1..5    workspaces    Super+Shift+S screenshot\n'
exec bash "$SCRIPT_DIR/install-niri-common.sh"
