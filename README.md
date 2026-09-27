# WILL OF THE CITY :: THE INDEX

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

A labwc desktop environment themed after *The Index* from Project Moon. labwc is the compositor and Quickshell 0.3+ provides the bar, menus, notifications, widgets and session lock.

## Install

Target: a fresh Arch Linux or Arch-based installation using pacman and systemd.

```bash
sudo pacman -S --needed git base-devel
git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./setup.sh
```

The setup installs the desktop only. It does not install a display manager, enable autologin, or modify the bootloader/kernel command line.

After boot, log in on the normal Arch TTY and start Index with:

```bash
dbus-run-session labwc
```

If you installed the earlier experimental greetd/ReGreet login, remove its active system configuration with:

```bash
bash ./remove-display-manager.sh
sudo reboot
```

The cleanup disables greetd and removes the Index-specific greeter/session files without touching the labwc/Quickshell desktop.

## VMware guests

VMware SVGA3D can provide working Mesa/OpenGL while Qt Quick's Wayland EGL path still fails. Index detects VMware guests and uses `QT_QUICK_BACKEND=software` for Quickshell and the Quickshell lock only; labwc keeps using the normal graphics stack.

For VMware guest integration, `open-vm-tools` can be installed separately.

## What you get

- Index-themed labwc server-side decorations
- Quickshell bar with workspaces, taskbar, network, Bluetooth, battery, volume, keyboard layout, tray, date and clock
- Bluetooth, notification-history and settings panels
- Quickshell `ext-session-lock-v1` lock screen with PAM authentication
- Prescript and atmosphere desktop layers
- UI sound/animation controls
- grim/slurp/swappy screen capture
- wlroots/GTK portal configuration
- Normal TTY login with no display-manager dependency

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

Drop optional assets in `assets/`, then rerun `bash ./setup.sh`.

| File | What it changes |
|---|---|
| `assets/intro.mp4` | lock intro video |
| `assets/sounds/bg.mp3` | lock-screen music |
| `assets/DefaultProfile.jpg` | lock-screen profile picture |

## Licence

Code is GPL-3.0. Original artwork, sounds and the extended pixel fonts are also available under CC BY-SA 4.0. Some bundled files belong to other people and are not relicensed here; see `ATTRIBUTION.md`.

*Limbus Company* and *The House of Spiders: The Index* are the property of Project Moon. This is an unaffiliated fan project.
