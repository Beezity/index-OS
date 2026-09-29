# WILL OF THE CITY :: THE INDEX

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

THE INDEX is a Project Moon-inspired Wayland desktop built around Quickshell. **labwc remains the stable/default compositor**, with an **experimental Niri backend** that provides a scrolling-tiling workflow while reusing the same shell, settings, services, and visual language.

The project currently targets **Arch Linux / Arch-based systems**, **Fedora Linux**, **Debian 13 (Trixie)**, and **Debian Sid**. Niri support is opt-in and remains in testing; installing it does not remove the labwc session.

## Desktop overview

THE INDEX keeps a compact cyan/DOS-style interface while relying on standard Linux backends wherever possible.

- **labwc** stable stacking session with THE INDEX server-side window decorations
- optional **Niri** scrolling-tiling session with square cyan focus rings and `prefer-no-csd`
- **Quickshell** top bar, menus, notifications, settings, clipboard popup, desktop atmosphere and session lock shared between both compositors
- the top bar is rendered on every connected monitor and follows monitor hotplug/unplug events
- desktop atmosphere elements are rendered per monitor, including district text, top-right quote, bottom-right standby text, centered quote ticker, and rising cyan motes
- Prescript of the Day is rendered on every monitor from one shared global state, so all copies show and reroll the same prescript
- centered clock, workspaces, task buttons, notification history, battery status, system tray, and `SET` control in the bar
- task buttons are clipped before the centered clock, so many or long-titled windows cannot overrun the time display
- centered THE INDEX application/search menu with `Super+Space` and `= expression` calculator input backed by Qalculate!
- native Settings panels for **Network**, **Bluetooth**, **Audio**, **Appearance**, **Power**, **Displays**, **Input**, and **Notifications**
- compositor-neutral display UI: labwc uses `wlr-randr`; Niri uses `niri msg --json outputs` plus validated managed KDL
- searchable clipboard history with `Super+V`, backed by `cliphist`
- configurable notification sounds, popup duration, Do Not Disturb, notification actions, and in-session history
- Wi-Fi through NetworkManager, Bluetooth through BlueZ, and PipeWire/WirePlumber audio controls
- power profiles, battery information, brightness, screen timeout, and lid behavior
- GTK3/GTK4, Qt, Wofi, Foot, Fastfetch, icon, cursor, and bundled font theming
- Thunar as the default file manager with THE INDEX GTK styling
- screenshot workflow using grim/slurp with automatic saves to `Pictures/Screenshots`, clipboard copy, and a completion notification; no Swappy window opens automatically
- separate GDM Wayland session entries for labwc and Niri

## Install

The installers are intended for a normal systemd-based installation. They install required packages, create a backup of relevant user configuration, configure THE INDEX, and register the selected Wayland session with GDM.

### Stable labwc session

#### Arch Linux

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./setup.sh
```

`setup.sh` runs the Arch labwc installer (`install.sh`).

#### Fedora Linux

Target: Fedora 43 or newer. Fedora 44 is the primary Fedora target.

```bash
sudo dnf install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-fedora.sh
```

Quickshell is installed from the `nett00n/hyprland` COPR when needed. The Fedora installer preserves an already-installed RPM Fusion `ffmpeg` rather than forcing Fedora's conflicting `ffmpeg-free`, and respects an existing `power-profiles-daemon` instead of replacing it with the mutually exclusive `tuned-ppd` backend.

For testing a development branch on an existing Fedora labwc installation without invoking DNF or changing installed packages, use:

```bash
bash ./patch-fedora.sh
```

#### Debian 13 / Sid

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-debian.sh
```

On Debian 13, Quickshell 0.3+ is installed from `trixie-backports`. Debian Sid installs Quickshell directly from Sid.

### Experimental Niri session

The Niri backend is installed alongside labwc rather than replacing it.

Fedora 43+:

```bash
bash ./install-niri-fedora.sh
```

Arch Linux:

```bash
bash ./install-niri.sh
```

Debian 13/Sid:

```bash
bash ./install-niri-debian.sh
```

The Debian Niri installer is deliberately guarded: it proceeds only when the configured repositories provide a supported Niri and `xwayland-satellite`. It does not silently build an unmanaged compositor from source.

After installation, choose **THE INDEX (Niri)** from GDM. The existing **THE INDEX** labwc session remains available for fallback. See [`docs/NIRI.md`](docs/NIRI.md) for Niri configuration ownership, architecture and the current test checklist.

## Starting THE INDEX

After installation, log out or reboot and choose the desired session from GDM:

- **THE INDEX** — labwc
- **THE INDEX (Niri)** — experimental Niri backend

For manual labwc testing from a TTY:

```bash
dbus-run-session labwc
```

For Niri, prefer its normal `niri-session` entry through GDM so the expected systemd/user-session targets and portal environment are established correctly.

## Settings

Open Settings with the `SET` control on the right side of the top bar.

| Area | Main controls |
|---|---|
| Network | current connection, networking/Wi-Fi radios, Wi-Fi selection, disconnect, advanced NetworkManager settings |
| Bluetooth | adapter power, discovery, pairing, connect/disconnect, advanced Blueman settings |
| Audio | output/input state and volume controls, advanced PipeWire mixer |
| Appearance | wallpaper, icon theme, cursor theme and cursor size |
| Power | power profile, battery state, brightness, suspend, screen timeout and lid behavior |
| Displays | output enable/disable, main display, resolution, refresh rate, position, scale, rotation, save layout |
| Notifications | Do Not Disturb, notification sounds, popup duration, history controls and test notification |
| Input | pointer speed, natural scrolling and touchpad tap-to-click where supported |

The Displays panel treats the output at logical position `0,0` as the main display. **Set Main** rebases the active monitor layout around the selected output without changing monitors' relative arrangement.

On labwc, the shared display backend applies state through `wlr-randr` and uses the existing layout saver. On Niri, it reads structured Niri IPC state and writes a validated managed `outputs.kdl`; a private snapshot retains configuration for temporarily disconnected outputs such as DisplayLink adapters.

Advanced compositor-specific configuration stays in the compositor's native configuration instead of being recreated completely in QML. Niri users should place advanced overrides in `~/.config/niri/custom.kdl`; normal THE INDEX updates do not overwrite that file.

## Niri scrolling workflow

The Niri backend uses native scrolling columns rather than simulating tiling on top of labwc. Core bindings include:

| Shortcut | Niri action |
|---|---|
| `Super+Left/Right` | focus column left/right |
| `Super+Up/Down` | focus window up/down |
| `Super+Ctrl+Left/Right` | move column left/right |
| `Super+Shift+Arrow` | focus neighboring monitor |
| `Super+Ctrl+Shift+Arrow` | move column to neighboring monitor |
| `Super+PageUp/PageDown` | focus workspace up/down |
| `Super+Ctrl+PageUp/PageDown` | move column to workspace up/down |
| `Super+R` | cycle preset column width |
| `Super+-` / `Super+=` | shrink/grow column |
| `Super+Shift+V` | toggle floating |
| `Super+W` | toggle tabbed column display |
| `Super+O` | overview |

The labwc session keeps its existing stacking/snapping behavior and window decorations.

## Application/search menu

Open the centered THE INDEX menu with `Super+Space` or by clicking `// THE INDEX` in the top bar. Normal text filters installed desktop applications. On a multi-monitor setup, the keyboard shortcut targets the monitor containing the active application and falls back to the logical main display when no application is active.

Prefix a query with `=` to use the Qalculate!-backed calculator. For example:

```text
= 2 + 2
= sqrt(144)
= 5 ft to cm
```

Press Enter or click the calculator result to copy it to the clipboard. `Super+D` remains available as a Wofi fallback launcher.

## Main shortcuts

Shared shortcuts:

| Shortcut | Action |
|---|---|
| `Super+Return` | Foot terminal |
| `Super+Space` | Toggle THE INDEX application/search menu |
| `Super+D` | Wofi application launcher |
| `Super+Q` | Close window |
| `Super+L` | Lock session |
| `Super+1` … `Super+5` | Switch/focus workspace |
| `Super+P` | Toggle Prescript of the Day on all monitors |
| `Super+V` | Open clipboard history |
| `Super+Shift+S` | Select a region, save it to `Pictures/Screenshots`, and copy it to the clipboard |
| `Print` | Save a full screenshot to `Pictures/Screenshots` and copy it to the clipboard |
| `Shift+Print` | Select a region and copy it to the clipboard without saving |

The screenshot helper creates the `Screenshots` directory automatically if it does not exist and uses timestamped collision-safe filenames. It does not open an editor after capture.

## Updating

Installed systems include:

```bash
index-update
```

`index-update` downloads the latest `main` branch and reapplies the installer for the recorded compositor backend and detected distribution. A normal pre-install backup is created first. Log out and back in before judging compositor, theme or Quickshell changes.

## Diagnostics

Run:

```bash
index-doctor
```

The doctor prefers the compositor detected from the current live session, with the recorded install backend as a fallback when run from another desktop or TTY. It checks expected compositor configuration, THE INDEX helpers, Quickshell files, themes, screenshot path, and relevant desktop services. In a Niri session it also checks that Niri IPC/output state is reachable.

## Backup and restore

The installer automatically creates a backup before applying THE INDEX. You can also create one manually:

```bash
index-backup
```

Restore the newest backup with:

```bash
index-restore latest
```

List available backups with:

```bash
index-restore --list
```

Backups are stored under `${XDG_STATE_HOME:-~/.local/state}/index-os/backups` and include both labwc and Niri managed state where present.

## Uninstall

Remove THE INDEX-managed configuration with:

```bash
index-uninstall
```

For non-interactive confirmation:

```bash
index-uninstall --yes
```

The uninstaller removes THE INDEX-managed configuration, themes, bundled fonts, helper files, caches, and session registration while leaving distro packages and saved backups installed. A user-owned Niri `custom.kdl` is intentionally preserved.

## VMware guests

VMware SVGA3D can provide working Mesa/OpenGL while Qt Quick's Wayland EGL path still fails. THE INDEX detects VMware guests and uses `QT_QUICK_BACKEND=software` for Quickshell and the Quickshell lock only; the compositor itself continues using the normal graphics stack.

Install the appropriate `open-vm-tools` package separately if you want VMware guest integration.

## Optional assets

Drop optional replacements into `assets/`, then rerun the installer for your distribution/backend.

| File | What it changes |
|---|---|
| `assets/intro.mp4` | lock-screen intro video |
| `assets/sounds/bg.mp3` | lock-screen music |
| `assets/DefaultProfile.jpg` | lock-screen profile picture |

## Project structure

The main implementation is split between:

- `quickshell/` — shared bar, per-monitor desktop surfaces, settings panels, notifications, clipboard UI, lock screen and other QML components
- `labwc/` — stable compositor configuration, labwc layout persistence, session scripts, GTK theme and desktop defaults
- `niri/` — Niri compositor policy, managed KDL defaults, session startup and portal preferences
- `scripts/` — shared compositor-aware helpers, installer logic, diagnostics, backup/restore, update and uninstall tools
- `scripts/distro/` — Arch, Fedora and Debian adapters for both compositor backends
- `docs/NIRI.md` — Niri ownership model and real-hardware test checklist
- `assets/` — bundled fonts, sounds and optional media
- `preview/` — repository screenshots

## Licence

Code is GPL-3.0. Original artwork, sounds and the extended pixel fonts are also available under CC BY-SA 4.0. Some bundled files belong to other people and are not relicensed here; see `ATTRIBUTION.md`.

*Limbus Company* and *The House of Spiders: The Index* are the property of Project Moon. This is an unaffiliated fan project.
