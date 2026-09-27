#!/bin/sh
set -eu
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/60-index-browsers.conf" <<'EOF'
MOZ_ENABLE_WAYLAND=1
NIXOS_OZONE_WL=1
EOF
