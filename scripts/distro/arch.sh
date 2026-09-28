#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"; trap 'bad "installation failed at line $LINENO"; exit 1' ERR
say "WILL OF THE CITY :: THE INDEX — labwc"
command -v pacman >/dev/null 2>&1 || { bad "Arch Linux/pacman is required."; exit 1; }; validate_repository_layout
say "backing up files managed by THE INDEX..."; bash "$SCRIPT_DIR/index-backup"; export INDEX_BACKUP_DONE=1; ok "pre-install backup created"
say "installing dependencies..."
PACKAGES=(labwc quickshell xorg-xwayland gdm swaybg swayidle wlopm wlr-randr wdisplays grim slurp swappy wl-clipboard cliphist foot fish wofi thunar thunar-archive-plugin thunar-volman xarchiver file-roller imv mpv zathura zathura-pdf-mupdf pavucontrol fastfetch xdg-utils xdg-user-dirs xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk dex libnotify playerctl polkit-gnome udiskie udisks2 gvfs gvfs-mtp tumbler ffmpegthumbnailer networkmanager nm-connection-editor bluez bluez-utils blueman pipewire pipewire-pulse wireplumber ffmpeg gst-libav gst-plugins-good qt6-multimedia qt6-svg qt6-declarative qt6-wayland qt6ct qt5ct gnome-themes-extra brightnessctl upower gammastep gnome-power-manager power-profiles-daemon ttf-dejavu ttf-liberation noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra papirus-icon-theme adwaita-cursors cups cups-pdf system-config-printer flatpak git pciutils libxml2 util-linux)
sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"; ok "all dependencies installed"
for cmd in labwc quickshell swaybg swayidle foot fish fastfetch wofi grim slurp swappy wl-copy wl-paste cliphist ffmpeg notify-send nmcli nm-connection-editor bluetoothctl playerctl wpctl wdisplays gnome-power-statistics powerprofilesctl flock fc-cache xmllint; do require_command "$cmd"; done
QS_VERSION="$(pacman -Q quickshell | awk '{print $2}' | cut -d- -f1)"; if command -v vercmp >/dev/null 2>&1 && (( $(vercmp "$QS_VERSION" 0.3.0) < 0 )); then bad "quickshell >= 0.3.0 is required; installed: $QS_VERSION"; exit 1; fi
sudo systemctl enable --now NetworkManager.service bluetooth.service cups.service; sudo systemctl start power-profiles-daemon.service; sudo systemctl enable gdm.service
export INDEX_DEX_COMMAND="dex" INDEX_POLKIT_AGENT="/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita" INDEX_FILE_ROLLER_DESKTOP="file-roller.desktop"
export INDEX_REQUIRE_CURSOR_INDEX=0 INDEX_VALIDATE_CURSOR_ROOT=1 INDEX_VALIDATE_TITLEBAR_BUTTONS=1
export INDEX_POWER_PROFILE_SERVICE="power-profiles-daemon.service"
export INDEX_COMPLETION_FIRST_LINE="GDM is installed and enabled. Reboot to log in and select THE INDEX from GDM's session menu."
export INDEX_COMPLETION_EXTRA=$'\n   Super+Return  terminal      Super+D  launcher\n   Super+Q       close         Super+L  lock\n   Super+1..5    desktops      Super+Shift+S  screenshot\n'
exec bash "$SCRIPT_DIR/install-common.sh"
