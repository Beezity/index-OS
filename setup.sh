#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Arch convenience wrapper. Fedora users should run install-fedora.sh directly.
bash "$DIR/install.sh"

echo
echo "THE INDEX installation is complete."
echo "Log in on a TTY and start it with: dbus-run-session labwc"
