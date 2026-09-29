#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export INDEX_ROOT
source "$SCRIPT_DIR/common.sh"
trap 'bad "niri migration patch failed at line $LINENO"; exit 1' ERR

say "WILL OF THE CITY :: THE INDEX — Fedora niri migration test"
command -v dnf >/dev/null 2>&1 || { bad "Fedora Linux with dnf is required."; exit 1; }
[[ -r /etc/fedora-release ]] || { bad "This patch helper is intended for Fedora Linux."; exit 1; }
FEDORA_VERSION="$(rpm -E %fedora)"
[[ "$FEDORA_VERSION" =~ ^[0-9]+$ ]] || { bad "could not determine Fedora release"; exit 1; }
(( FEDORA_VERSION >= 43 )) || { bad "Fedora 43 or newer is required; detected Fedora $FEDORA_VERSION"; exit 1; }
note "detected Fedora $FEDORA_VERSION"
validate_repository_layout

[[ -f "$HOME/.config/quickshell/shell.qml" ]] || {
  bad "THE INDEX does not appear to be installed for this user"
  note "Use install-fedora.sh for an initial installation."
  exit 1
}
command -v quickshell >/dev/null 2>&1 || { bad "existing THE INDEX install is missing Quickshell"; exit 1; }
command -v wlr-randr >/dev/null 2>&1 || { bad "existing THE INDEX install is missing wlr-randr"; exit 1; }

say "backing up current THE INDEX configuration..."
bash "$SCRIPT_DIR/index-backup"
export INDEX_BACKUP_DONE=1
ok "pre-migration backup created"

say "installing only the niri migration dependencies..."
sudo dnf -y install niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk
ok "niri migration dependencies installed"
for cmd in niri niri-session xwayland-satellite quickshell swaybg swayidle wlr-randr grim slurp wl-copy notify-send; do require_command "$cmd"; done

# Do not touch the currently installed ffmpeg or power-profile provider. This
# patch is intentionally narrower than the full Fedora installer.
export INDEX_COMPOSITOR=niri
export INDEX_CURSOR_ROOT="/usr/share/icons/Adwaita"
export INDEX_FILE_ROLLER_DESKTOP="org.gnome.FileRoller.desktop"
export INDEX_VALIDATE_CURSOR_ROOT=1 INDEX_GDM_SERVICE="gdm.service"
export INDEX_COMPLETION_EXTRA=$'\n   This was a migration test patch; distro packages unrelated to niri were left unchanged.\n'
export INDEX_COMPLETION_FIRST_LINE="Fedora niri migration patch complete. Log out and select THE INDEX from GDM to test it."

exec bash "$SCRIPT_DIR/install-niri-common.sh"
