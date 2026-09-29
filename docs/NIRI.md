# THE INDEX — Niri backend

THE INDEX can run on Niri without removing the existing labwc session. The Niri backend is deliberately a separate session while it is being tested.

## Install

Fedora 43+:

```bash
bash ./install-niri-fedora.sh
```

Arch Linux:

```bash
bash ./install-niri.sh
```

Debian 13/Sid has a guarded installer:

```bash
bash ./install-niri-debian.sh
```

The Debian installer only proceeds when the configured repositories actually provide `niri >= 26.04` and `xwayland-satellite`. It does not silently compile an unmanaged compositor from source.

After installation, log out and select **THE INDEX (Niri)** in GDM. The existing **THE INDEX** labwc session remains installed.

## Configuration ownership

`~/.config/niri/config.kdl` is THE INDEX's static compositor policy. It includes:

- `input.kdl` — managed by the Input Settings backend
- `outputs.kdl` — managed by the Displays Settings backend
- `cursor.kdl` — managed by Appearance Settings
- `custom.kdl` — optional user-owned advanced Niri overrides

Do not put advanced manual changes into the managed files; Settings may rewrite them. Put Niri-specific custom rules, gestures, binds, layout overrides, VRR settings, output-specific advanced options, and other native options in `~/.config/niri/custom.kdl`. Normal installs/updates never overwrite that file, and `index-uninstall` leaves it in place.

All generated managed KDL is validated with `niri validate`; helpers restore the previous file if a generated change is invalid.

## Shared shell

The Quickshell layer is shared with labwc. Each connected output receives the same THE INDEX bar, atmosphere text, rising cyan motes, and global Prescript state. Notifications, clipboard history, launcher, Settings, audio, networking, Bluetooth, lock UI, and most helpers remain compositor-independent.

The labwc server-side titlebar cannot be carried over directly. Niri uses `prefer-no-csd` with a square THE INDEX cyan focus ring instead. This keeps the visual language while allowing Niri to own the scrolling layout.

## Display backend

`index-displays` is the stable backend used by `DisplaysPanel.qml`.

On labwc it reads/applies `wlr-randr` and delegates persistence to the existing labwc display saver. On Niri it reads structured state from `niri msg --json outputs`, writes `~/.config/niri/outputs.kdl`, validates it, and relies on Niri's live reload.

Niri display persistence also keeps a private managed snapshot at `~/.config/the-index/displays.json`. This retains configuration for temporarily disconnected outputs, including USB/DisplayLink monitors, so changing another connected display does not erase the disconnected output's saved mode or position. The Settings panel itself still lists only outputs currently reported by Niri.

The logical MAIN display is the active output at `0,0`; on Niri it is additionally given `focus-at-startup`.

## Portals

The Niri installers install `xdg-desktop-portal-gnome`, `xdg-desktop-portal-gtk`, and `gnome-keyring`. THE INDEX installs `~/.config/xdg-desktop-portal/niri-portals.conf` with GNOME as the general Niri portal backend so screencasting continues to use Niri/GNOME integration, while `FileChooser` is explicitly assigned to GTK. This avoids requiring Nautilus merely for file selection when the desktop's file manager is Thunar.

## Screenshots

Both compositor backends use the same DMS-inspired `index-snip` workflow so screenshot behavior stays consistent when switching sessions:

- `Super+Shift+S` selects a region with `slurp`, captures it with `grim`, saves it to the XDG Pictures directory under `Screenshots/`, copies it to the clipboard, and sends a notification.
- `Print` captures the full logical desktop with `grim`, saves it, copies it to the clipboard, and sends a notification.
- `Shift+Print` selects a region and copies it to the clipboard without saving a file.

The Screenshots directory is created automatically and timestamped names are collision-safe. Swappy or another editor is not opened automatically. Niri supports the screencopy path used by `grim`, so the same helper can be shared rather than maintaining two screenshot implementations.

The `screenshot-path` setting remains configured in Niri as a sane destination for native Niri screenshot actions invoked manually or through user overrides.

## X11 applications

Niri 25.08+ integrates `xwayland-satellite` automatically when it is installed and available in `PATH`. The Niri installers install it where the distribution provides it; no manual `DISPLAY` or satellite startup is configured.

## Test checklist

Before the backend is considered ready, test all of these in a real Niri session:

- internal laptop panel, direct HDMI/DP display, and DisplayLink output together
- output enable/disable, resolution, refresh rate, scale, rotation and positions
- Set Main and persistence across logout/login and hotplug
- disconnect/reconnect DisplayLink after changing another monitor and confirm its saved position survives
- bar, atmosphere text/motes, and the same Prescript on every output
- per-monitor workspaces and Niri scrolling navigation
- launcher placement and window/task activation
- region and full-layout screenshots, clipboard copy, notification, and screenshot directory
- ext-session-lock and idle locking/monitor power-off/resume
- pointer speed, natural scroll, tap-to-click, appearance and cursor changes
- PipeWire audio, NetworkManager, BlueZ, notifications and clipboard history
- Xwayland-satellite applications and games
- screen sharing through the GNOME portal and file choosing through GTK
- `index-doctor`, `index-update`, backup/restore and uninstall
- confirm `index-uninstall` preserves a pre-existing `~/.config/niri/custom.kdl`

If a test fails, keep the Niri PR in draft and use the labwc session until the backend is fixed.
