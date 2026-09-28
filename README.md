# WILL OF THE CITY :: THE INDEX

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

THE INDEX is a Project Moon-inspired Wayland desktop built around [labwc](https://github.com/labwc/labwc) and [Quickshell](https://quickshell.org/). It provides a complete themed session with a custom top bar, settings panels, notifications, clipboard history, launcher, lock screen, GTK/Qt theming, and supporting helper tools.

The project currently targets **Arch Linux / Arch-based systems**, **Fedora Linux**, **Debian 13 (Trixie)**, and **Debian Sid**.

## Desktop overview

THE INDEX keeps a compact cyan/DOS-style interface while relying on standard Linux backends wherever possible.

- **labwc** compositor with THE INDEX server-side window decorations
- **Quickshell** top bar, menus, notifications, settings, clipboard popup, and session lock
- centered clock, workspaces, task buttons, notification history, battery status, system tray, and `SET` control in the bar
- native Settings panels for **Network**, **Bluetooth**, **Audio**, **Appearance**, **Power**, and **Notifications**
- pointer/touchpad controls integrated into Settings
- searchable clipboard history with `Super+V`, backed by `cliphist`
- configurable notification sounds, popup duration, Do Not Disturb, notification actions, and in-session history
- Wi-Fi management through NetworkManager with advanced configuration delegated to `nm-connection-editor`
- Bluetooth pairing/connection controls backed by BlueZ, with Blueman available for advanced management
- PipeWire/WirePlumber audio controls with `pavucontrol` available for advanced mixing
- power profiles, battery information, brightness, screen timeout, and lid behavior
- GTK3/GTK4, Qt, Wofi, Foot, Fastfetch, icon, cursor, and bundled font theming
- Thunar as the default file manager with THE INDEX GTK styling
- screenshot workflow using grim/slurp/swappy
- GDM Wayland session entry

## Install

The installers are intended for a normal systemd-based installation. They install the required packages, configure THE INDEX, create a backup of relevant existing user configuration, and register the Wayland session with GDM.

### Arch Linux

Target: Arch Linux or an Arch-based system using pacman and systemd.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./setup.sh
```

`setup.sh` runs the Arch installer (`install.sh`).

### Fedora Linux

Target: Fedora 43 or newer. Fedora 44 has been tested successfully.

```bash
sudo dnf install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-fedora.sh
```

Quickshell is installed from the `nett00n/hyprland` COPR because it is not currently provided by Fedora's official repositories.

### Debian 13 / Sid

Target: Debian 13 (Trixie) stable or Debian Sid.

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-debian.sh
```

On Debian 13, Quickshell 0.3+ is installed from `trixie-backports`. If that suite is not already configured, the installer adds `/etc/apt/sources.list.d/index-os-trixie-backports.sources`. Debian Sid installs Quickshell directly from Sid.

## Starting THE INDEX

After installation, log out or reboot and choose **THE INDEX** from GDM's session menu.

You can also start a session manually from a TTY:

```bash
dbus-run-session labwc
```

On an existing Fedora GNOME installation, you can switch to TTY3 with:

```bash
sudo chvt 3
```

## Settings

Open Settings with the `SET` control on the right side of the top bar.

| Area | Main controls |
|---|---|
| Network | current connection, networking/Wi-Fi radios, Wi-Fi selection, disconnect, advanced NetworkManager settings |
| Bluetooth | adapter power, discovery, pairing, connect/disconnect, advanced Blueman settings |
| Audio | output/input state and volume controls, advanced PipeWire mixer |
| Appearance | wallpaper, icon theme, cursor theme and cursor size |
| Power | power profile, battery state, brightness, suspend, screen timeout and lid behavior |
| Notifications | Do Not Disturb, notification sounds, popup duration, history controls and test notification |
| Input | pointer speed, natural scrolling and touchpad tap-to-click where supported |

Advanced system configuration stays in the relevant external tool rather than being reimplemented completely in QML.

## Main shortcuts

| Shortcut | Action |
|---|---|
| `Super+Return` | Foot terminal |
| `Super+D` | Wofi application launcher |
| `Super+Q` | Close window |
| `Super+F` | Toggle maximize |
| `Super+L` | Lock session |
| `Super+1` … `Super+5` | Switch workspace |
| `Super+V` | Open clipboard history |
| `Super+Shift+S` | Region screenshot/editor |
| `Print` | Full screenshot |

## Updating

Installed systems include an update helper:

```bash
index-update
```

`index-update` downloads the latest `main` branch, creates a normal pre-install backup, and reapplies the correct installer for the detected supported distribution.

After updating, log out and back in before judging session, theme, or Quickshell changes.

## Diagnostics

Run:

```bash
index-doctor
```

The doctor checks the installed THE INDEX files, helpers, fonts, themes, Quickshell configuration, and other expected desktop components.

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

Backups are stored under `${XDG_STATE_HOME:-~/.local/state}/index-os/backups`.

## Uninstall

Remove THE INDEX-managed configuration with:

```bash
index-uninstall
```

For non-interactive confirmation:

```bash
index-uninstall --yes
```

The uninstaller removes THE INDEX configuration, themes, bundled fonts, helper files, caches, and session registration. It intentionally leaves distro packages and saved backups installed so a previous configuration can still be restored afterward.

## VMware guests

VMware SVGA3D can provide working Mesa/OpenGL while Qt Quick's Wayland EGL path still fails. THE INDEX detects VMware guests and uses `QT_QUICK_BACKEND=software` for Quickshell and the Quickshell lock only; labwc continues using the normal graphics stack.

Install the appropriate `open-vm-tools` package separately if you want VMware guest integration.

## Optional assets

Drop optional replacements into `assets/`, then rerun the installer for your distribution.

| File | What it changes |
|---|---|
| `assets/intro.mp4` | lock-screen intro video |
| `assets/sounds/bg.mp3` | lock-screen music |
| `assets/DefaultProfile.jpg` | lock-screen profile picture |

## Project structure

The main implementation is split between:

- `quickshell/` — bar, settings panels, notifications, clipboard UI, lock screen and other QML components
- `labwc/` — compositor configuration, session scripts, GTK theme and desktop defaults
- `scripts/` — shared helpers, installer logic, diagnostics, backup/restore, update and uninstall tools
- `scripts/distro/` — Arch, Fedora and Debian package/setup adapters
- `assets/` — bundled fonts, sounds and optional media
- `preview/` — repository screenshots

## Licence

Code is GPL-3.0. Original artwork, sounds and the extended pixel fonts are also available under CC BY-SA 4.0. Some bundled files belong to other people and are not relicensed here; see `ATTRIBUTION.md`.

*Limbus Company* and *The House of Spiders: The Index* are the property of Project Moon. This is an unaffiliated fan project.
