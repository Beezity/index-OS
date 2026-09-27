<div align="center">

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

# WILL OF THE CITY :: THE INDEX

![labwc](https://img.shields.io/badge/wm-labwc-5DADE2?style=flat-square&labelColor=05080d)
![quickshell](https://img.shields.io/badge/shell-quickshell%200.3%2B-5DADE2?style=flat-square&labelColor=05080d)
![arch](https://img.shields.io/badge/target-Arch-5DE285?style=flat-square&labelColor=05080d)
![licence](https://img.shields.io/badge/code-GPL--3.0-5DADE2?style=flat-square&labelColor=05080d)

</div>

---

## What is this

A labwc desktop environment themed after *The Index* from Project Moon.

The compositor is **labwc**. **Quickshell 0.3+** provides the bar, menus,
notifications, widgets and session lock. Workspace state is read directly from
labwc through the standard `ext-workspace-v1` protocol rather than simulated
key presses.

> This installer is intended for a fresh Arch-based system with no existing
> desktop environment configuration that needs to be preserved.

---

## Install

Supported target: Arch Linux or an Arch-based distribution using `pacman` and
systemd.

```bash
sudo pacman -S --needed git base-devel

git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
bash ./install.sh
```

The installer uses Arch's official repositories and installs every required
package, including `quickshell`, before applying desktop configuration. It runs
in fail-fast mode: a required package, command, source file or validation step
failing stops the install rather than leaving it to continue silently.

The installer deliberately does **not** configure TTY autologin, automatically
start labwc from a shell profile, or modify GRUB, systemd-boot, Limine, kernel
command lines or initramfs settings.

After installation, start the session from a TTY with:

```bash
dbus-run-session labwc
```

`bash ./install.sh` can be rerun on the intended fresh/no-other-DE setup. It
replaces this project's labwc and Quickshell configuration rather than merging
arbitrary existing desktop configuration.

### VMware guests

VMware SVGA3D can expose working direct-rendered Mesa/OpenGL while Qt Quick's
Wayland EGL swap path still fails with an EGL surface/protocol error. Index
detects VMware guests and uses `QT_QUICK_BACKEND=software` for the Quickshell
shell and lock only. labwc and the rest of the desktop keep using the normal
Mesa/VMware graphics stack. No override is applied on physical hardware.

For VMware guest integration, install and enable `open-vm-tools` separately if
you want clipboard/host integration; it is not required by Index itself.

---

## What you get

- **Bracket titlebars** and matching labwc server-side decorations
- **The bar** — start menu, native workspaces, taskbar, network, Bluetooth,
  battery, volume, keyboard layout, tray, date and centred clock
- **Panels** — Bluetooth pairing, notification history and quick system settings
- **The lock** — a real `ext-session-lock-v1` Quickshell session lock with PAM
  authentication, optional intro video and the WILL OF THE CITY presentation
- **Prescript of the day** — the desktop Prescript widget and atmosphere layer
- **Sound and animation** with a UI-sound toggle
- **Screen capture** through grim/slurp/swappy
- **Portal configuration** for wlroots screen sharing and GTK file pickers
- **Normal login semantics** — logout exits labwc; there is no autologin shortcut

The lock, panels and compositor integration should still be tested on the target
hardware before relying on the setup as a daily desktop. Static repository
checks cannot reproduce every GPU, monitor, PAM or portal configuration.

---

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
| `Super+Shift+S` | Region screenshot / editor |
| `Print` | Full screenshot |

---

## Make it yours

Drop optional assets in `assets/`, then rerun `bash ./install.sh`.

| File | What it changes |
|---|---|
| `assets/intro.mp4` | lock intro video |
| `assets/sounds/bg.mp3` | lock-screen music |
| `assets/DefaultProfile.jpg` | lock-screen profile picture |

The desktop works without these optional files.

---

## Licence

Code is **GPL-3.0**. Original artwork, sounds and the extended pixel fonts are
also available under **CC BY-SA 4.0**.

Some bundled files belong to other people and are not relicensed here — see
[ATTRIBUTION.md](ATTRIBUTION.md).

*Limbus Company* and *The House of Spiders: The Index* are the property of
Project Moon. This is an unaffiliated fan project.

---

<div align="center">

*"We're simply carrying out our Prescript. No personal feelings are involved in this process."*

`>_ THE INDEX_`

</div>
