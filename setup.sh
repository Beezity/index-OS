#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install the Index desktop only. Login remains the normal Arch TTY flow.
bash "$DIR/install.sh"

echo
echo "THE INDEX installation is complete."
echo "Log in on a TTY and start it with: dbus-run-session labwc"
