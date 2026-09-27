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
notifications, widgets and session lock. **greetd + ReGreet + Cage** provide a
small graphical login environment using the same wallpaper, pixel font and
cyan/black visual language.

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
bash ./setup.sh
sudo reboot
```

`setup.sh` runs the desktop installer and then installs the graphical login.
The installers use Arch's official repositories and fail immediately if a
required package, command, source file or validation step fails.

The setup deliberately does **not** enable autologin or modify GRUB,
systemd-boot, Limine, kernel command lines or initramfs settings. greetd owns
TTY1; other TTYs remain available as recovery consoles.

### Login

At boot, greetd launches **ReGreet** inside the minimal **Cage** compositor.
`THE INDEX` is installed in `/usr/share/wayland-sessions` and is the session
provided by a fresh Index installation. ReGreet also lists other X11/Wayland
sessions installed later and remembers the last session used by each account.
Authentication is always required; no greetd `initial_session` is configured.

If the graphical greeter ever fails, switch to another TTY (for example
`Ctrl+Alt+F2`), log in, and run:

```bash
index-session
```

### VMware guests

VMware SVGA3D can expose working direct-rendered Mesa/OpenGL while Qt Quick's
Wayland EGL swap path still fails with an EGL surface/protocol error. Index
detects VMware guests and uses `QT_QUICK_BACKEND=software` for the Quickshell
shell and lock only. labwc, Cage, ReGreet and the rest of the desktop keep using
the normal graphics stack.

For VMware guest integration, install and enable `open-vm-tools` separately if
you want clipboard/host integration; it is not required by Index itself.

---

## What you get

- **Index login** — greetd/ReGreet hosted by Cage, with Index wallpaper, font,
  dark GTK4 styling, clock, session selection and reboot/shutdown controls
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
- **Normal login semantics** — logout returns to the graphical greeter

The greeter, lock, panels and compositor integration should still be tested on
the target hardware before relying on the setup as a daily desktop. Static
repository checks cannot reproduce every GPU, monitor, PAM or portal setup.

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

Drop optional assets in `assets/`, then rerun `bash ./setup.sh`.

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
