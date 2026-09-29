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

Do not put advanced manual changes into the managed files; Settings may rewrite them. Put Niri-specific custom rules, gestures, binds, layout overrides, VRR settings, output-specific advanced options, and other native options in `~/.config/niri/custom.kdl`. The installer never overwrites that file.

All generated managed KDL is validated with `niri validate`; helpers restore the previous file if a generated change is invalid.

## Shared shell

The Quickshell layer is shared with labwc. Each connected output receives the same THE INDEX bar, atmosphere text, rising cyan motes, and global Prescript state. Notifications, clipboard history, launcher, Settings, audio, networking, Bluetooth, lock UI, and most helpers remain compositor-independent.

The labwc server-side titlebar cannot be carried over directly. Niri uses `prefer-no-csd` with a square THE INDEX cyan focus ring instead. This keeps the visual language while allowing Niri to own the scrolling layout.

## Display backend

`index-displays` is the stable backend used by `DisplaysPanel.qml`.

On labwc it reads/applies `wlr-randr` and delegates persistence to the existing labwc display saver. On Niri it reads structured state from `niri msg --json outputs`, writes `~/.config/niri/outputs.kdl`, validates it, and relies on Niri's live reload.

The logical MAIN display is still the active output at `0,0`; on Niri it is additionally given `focus-at-startup`.

## Screenshots

Niri uses its native screenshot actions. `Super+Shift+S` opens Niri's region selection and saves to `~/Pictures/Screenshots`; `Print` captures the focused screen; `Shift+Print` opens region selection without writing to disk. Niri also copies captures to the clipboard.

The labwc backend keeps the grim/slurp `index-snip` workflow.

## X11 applications

Niri 25.08+ integrates `xwayland-satellite` automatically when it is installed and available in `PATH`. The Niri installers install it where the distribution provides it; no manual `DISPLAY` or satellite startup is configured.

## Test checklist

Before the backend is considered ready, test all of these in a real Niri session:

- internal laptop panel, direct HDMI/DP display, and DisplayLink output together
- output enable/disable, resolution, refresh rate, scale, rotation and positions
- Set Main and persistence across logout/login and hotplug
- bar, atmosphere text/motes, and the same Prescript on every output
- per-monitor workspaces and Niri scrolling navigation
- launcher placement and window/task activation
- region and screen screenshots, clipboard copy, and screenshot directory
- ext-session-lock and idle locking/monitor power-off/resume
- pointer speed, natural scroll, tap-to-click, appearance and cursor changes
- PipeWire audio, NetworkManager, BlueZ, notifications and clipboard history
- Xwayland-satellite applications and games
- screen sharing/file chooser portals
- `index-doctor`, `index-update`, backup/restore and uninstall

If a test fails, keep the Niri PR in draft and use the labwc session until the backend is fixed.
