#!/usr/bin/env bash
set -Eeuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"

for f in config.toml regreet.toml gtk.css index-session index.desktop hide-labwc.desktop; do
  [[ -f "$DIR/$f" ]] || { echo "missing greeter/$f" >&2; exit 1; }
done
[[ -f "$ROOT/wallpaper/the-index.png" ]] || { echo "missing wallpaper" >&2; exit 1; }

sudo pacman -S --needed --noconfirm greetd greetd-regreet cage

for cmd in greetd regreet cage; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "missing command after install: $cmd" >&2; exit 1; }
done

# ReGreet runs as its own greeter account, so install the Index font globally.
sudo install -d -m755 /usr/local/share/fonts/index-os
shopt -s nullglob
fonts=("$ROOT"/assets/*.ttf "$ROOT"/assets/*.otf)
((${#fonts[@]})) || { echo "no bundled Index fonts found" >&2; exit 1; }
sudo install -m644 "${fonts[@]}" /usr/local/share/fonts/index-os/
shopt -u nullglob
sudo fc-cache -f >/dev/null

sudo install -d -m755 \
  /etc/greetd \
  /usr/share/index-os/greeter \
  /usr/share/themes/the-index-greeter/gtk-4.0 \
  /usr/share/wayland-sessions \
  /usr/local/share/wayland-sessions

sudo install -m644 "$DIR/config.toml" /etc/greetd/config.toml
sudo install -m644 "$DIR/regreet.toml" /etc/greetd/regreet.toml
sudo install -m644 "$DIR/gtk.css" /usr/share/themes/the-index-greeter/gtk-4.0/gtk.css
sudo install -m644 "$ROOT/wallpaper/the-index.png" /usr/share/index-os/greeter/wall.png
sudo install -m755 "$DIR/index-session" /usr/local/bin/index-session
sudo install -m644 "$DIR/index.desktop" /usr/share/wayland-sessions/index.desktop

# labwc itself ships a generic labwc session. Hide that duplicate from ReGreet
# through a higher-priority XDG data directory: users should normally select
# THE INDEX, whose launcher establishes the intended session environment.
sudo install -m644 "$DIR/hide-labwc.desktop" /usr/local/share/wayland-sessions/labwc.desktop

# The package's tmpfiles configuration prepares writable ReGreet state/log dirs.
sudo systemd-tmpfiles --create

# No initial_session is configured: authentication is always required.
sudo systemctl enable greetd.service

for f in \
  /etc/greetd/config.toml \
  /etc/greetd/regreet.toml \
  /usr/share/themes/the-index-greeter/gtk-4.0/gtk.css \
  /usr/share/index-os/greeter/wall.png \
  /usr/local/bin/index-session \
  /usr/share/wayland-sessions/index.desktop \
  /usr/local/share/wayland-sessions/labwc.desktop; do
  sudo test -s "$f" || { echo "greeter install verification failed: $f" >&2; exit 1; }
done

echo "Index greetd/ReGreet login installed and enabled for next boot."
