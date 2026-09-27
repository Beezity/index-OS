#!/usr/bin/env bash
set -Eeuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Keep the desktop installer and privileged display-manager installer separated
# internally, while providing one command for a fresh Arch installation.
bash "$DIR/install.sh"
bash "$DIR/greeter/install.sh"

echo
echo "THE INDEX installation is complete. Reboot to enter the Index greeter."
