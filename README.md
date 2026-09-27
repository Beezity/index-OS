# WILL OF THE CITY :: THE INDEX

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

A labwc desktop environment themed after *The Index* from Project Moon. labwc is the compositor and Quickshell 0.3+ provides the bar, menus, notifications, widgets and session lock.

## Install

THE INDEX currently supports Arch Linux/Arch-based systems, Fedora Linux, Debian 13 (Trixie), and Debian Sid. All installers configure the same labwc/Quickshell desktop while using distribution-appropriate packages and setup.

### Arch Linux

Target: a fresh Arch Linux or Arch-based installation using pacman and systemd.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./setup.sh
```

`setup.sh` runs the Arch installer (`install.sh`).

### Fedora Linux

Target: Fedora 43 or newer using dnf and systemd. Fedora 44 has been tested successfully.

```bash
sudo dnf install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-fedora.sh
```

The Fedora installer uses Fedora packages where available. Quickshell is installed from the `nett00n/hyprland` COPR because it is not currently provided by the official Fedora repositories. The Capitaine cursor theme is built from its upstream source and installed for the current user.

### Debian 13 / Sid

Target: Debian 13 (Trixie) stable or Debian Sid using APT and systemd.

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install-debian.sh
```

On Debian 13, Quickshell 0.3+ is installed from `trixie-backports`; if the backports suite is not already configured, the installer adds an `index-os-trixie-backports.sources` entry under `/etc/apt/sources.list.d/`. Debian Sid installs Quickshell directly from the normal Sid repositories. Capitaine is built from upstream source and installed for the current user.

All supported installers install and enable GDM and register THE INDEX as a Wayland session. Reboot after installation, choose THE INDEX from GDM's session menu, and sign in normally.

You can also start THE INDEX manually from a TTY with:

```bash
dbus-run-session labwc
```

On an existing Fedora GNOME installation, you can switch to TTY3 from a terminal with:

```bash
sudo chvt 3
```

If you want to test Index without GDM retaining the graphical session, save your work first and then stop GDM from the TTY. On Arch/Fedora use `gdm`; on Debian use `gdm3`:

```bash
sudo systemctl stop gdm      # Arch/Fedora
sudo systemctl stop gdm3     # Debian
dbus-run-session labwc
```

Start the appropriate GDM service again afterward or reboot.

If you installed the earlier experimental greetd/ReGreet login on Arch, remove its active system configuration with:

```bash
bash ./remove-display-manager.sh
sudo reboot
```

The cleanup disables greetd and removes the Index-specific greeter/session files without touching the labwc/Quickshell desktop.

## VMware guests

VMware SVGA3D can provide working Mesa/OpenGL while Qt Quick's Wayland EGL path still fails. Index detects VMware guests and uses `QT_QUICK_BACKEND=software` for Quickshell and the Quickshell lock only; labwc keeps using the normal graphics stack.

For VMware guest integration, install the appropriate open-vm-tools package for your distribution separately.

## What you get

- Index-themed labwc server-side decorations
- Quickshell bar with workspaces, taskbar, network, Bluetooth, battery, volume, tray, date and clock
- Bluetooth, notification-history and settings panels
- Quickshell `ext-session-lock-v1` lock screen with PAM authentication
- Prescript and atmosphere desktop layers
- UI sound/animation controls
- grim/slurp/swappy screen capture
- wlroots/GTK portal configuration
- Papirus-Dark application icons and Capitaine cursors
- GDM session entry for THE INDEX

## Main shortcuts

| Shortcut | Action |
|---|---|
| `Super+Return` | Foot terminal |
| `Super+D` | Wofi application launcher |
| `Super+Q` | Close window |
| `Super+F` | Toggle maximize |
| `Super+L` | Lock session |
| `Super+1` … `Super+5` | Switch workspace |
| `Super+V` | Clipboard history |
| `Super+Shift+S` | Region screenshot/editor |
| `Print` | Full screenshot |

## Optional assets

Drop optional assets in `assets/`, then rerun the installer for your distribution (`bash ./setup.sh` on Arch, `bash ./install-fedora.sh` on Fedora, or `bash ./install-debian.sh` on Debian).

| File | What it changes |
|---|---|
| `assets/intro.mp4` | lock intro video |
| `assets/sounds/bg.mp3` | lock-screen music |
| `assets/DefaultProfile.jpg` | lock-screen profile picture |

## Licence

Code is GPL-3.0. Original artwork, sounds and the extended pixel fonts are also available under CC BY-SA 4.0. Some bundled files belong to other people and are not relicensed here; see `ATTRIBUTION.md`.

*Limbus Company* and *The House of Spiders: The Index* are the property of Project Moon. This is an unaffiliated fan project.
