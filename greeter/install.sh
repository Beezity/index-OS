#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

for f in config.toml regreet.toml gtk.css index-session index.desktop hide-labwc.desktop labwc/rc.xml labwc/autostart; do
  [[ -f "$DIR/$f" ]] || { echo "missing greeter/$f" >&2; exit 1; }
done
[[ -f "$ROOT/wallpaper/the-index.png" ]] || { echo "missing wallpaper" >&2; exit 1; }

# labwc is already part of Index, but keep it here as an explicit dependency of
# the display-manager path. Cage is intentionally not used: its DRM backend can
# fail to create a VMware SVGA3D output even when labwc works on the same guest.
sudo pacman -S --needed --noconfirm greetd greetd-regreet labwc

for cmd in greetd regreet labwc; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing command after install: $cmd" >&2; exit 1; }
done

sudo install -d -m755 /usr/local/share/fonts/index-os
shopt -s nullglob
fonts=("$ROOT"/assets/*.ttf "$ROOT"/assets/*.otf)
((${#fonts[@]})) || { echo "no bundled Index fonts found" >&2; exit 1; }
sudo install -m644 "${fonts[@]}" /usr/local/share/fonts/index-os/
shopt -u nullglob
sudo fc-cache -f >/dev/null

sudo install -d -m755 \
  /etc/greetd \
  /etc/index-greeter/labwc \
  /usr/share/index-os/greeter \
  /usr/share/themes/the-index-greeter/gtk-4.0 \
  /usr/share/wayland-sessions \
  /usr/local/share/wayland-sessions

sudo install -m644 "$DIR/config.toml" /etc/greetd/config.toml
sudo install -m644 "$DIR/regreet.toml" /etc/greetd/regreet.toml
sudo install -m644 "$DIR/labwc/rc.xml" /etc/index-greeter/labwc/rc.xml
sudo install -m755 "$DIR/labwc/autostart" /etc/index-greeter/labwc/autostart
sudo install -m644 "$DIR/gtk.css" /usr/share/themes/the-index-greeter/gtk-4.0/gtk.css
sudo install -m644 "$ROOT/wallpaper/the-index.png" /usr/share/index-os/greeter/wall.png
sudo install -m755 "$DIR/index-session" /usr/local/bin/index-session
sudo install -m644 "$DIR/index.desktop" /usr/share/wayland-sessions/index.desktop
sudo install -m644 "$DIR/hide-labwc.desktop" /usr/local/share/wayland-sessions/labwc.desktop

sudo systemd-tmpfiles --create
sudo systemctl enable greetd.service

for f in \
  /etc/greetd/config.toml \
  /etc/greetd/regreet.toml \
  /etc/index-greeter/labwc/rc.xml \
  /etc/index-greeter/labwc/autostart \
  /usr/share/themes/the-index-greeter/gtk-4.0/gtk.css \
  /usr/share/index-os/greeter/wall.png \
  /usr/local/bin/index-session \
  /usr/share/wayland-sessions/index.desktop \
  /usr/local/share/wayland-sessions/labwc.desktop; do
  sudo test -s "$f" || { echo "greeter install verification failed: $f" >&2; exit 1; }
done

echo "Index greetd/ReGreet login installed and enabled for next boot."
