#!/usr/bin/env bash
set -Eeuo pipefail

# Undo the previously shipped Index greetd/ReGreet integration without touching
# the user's labwc/Quickshell desktop configuration.
sudo systemctl disable --now greetd.service 2>/dev/null || true

for path in \
  /etc/greetd/config.toml \
  /etc/greetd/regreet.toml \
  /etc/index-greeter \
  /usr/share/index-os/greeter \
  /usr/share/themes/the-index-greeter \
  /usr/local/bin/index-session \
  /usr/share/wayland-sessions/index.desktop \
  /usr/local/share/wayland-sessions/labwc.desktop; do
  sudo rm -rf -- "$path"
done

printf '%s\n' 'Index display manager disabled and its configuration removed.'
printf '%s\n' 'After reboot, log in on the TTY and run: dbus-run-session labwc'
