<div align="center">

![WILL OF THE CITY :: THE INDEX](preview/desktop.png)

# WILL OF THE CITY :: THE INDEX

![labwc](https://img.shields.io/badge/wm-labwc-5DADE2?style=flat-square&labelColor=05080d)
![quickshell](https://img.shields.io/badge/shell-quickshell-5DADE2?style=flat-square&labelColor=05080d)
![arch](https://img.shields.io/badge/arch-tested-5DE285?style=flat-square&labelColor=05080d)
![licence](https://img.shields.io/badge/code-GPL--3.0-5DADE2?style=flat-square&labelColor=05080d)

</div>

---

## What is this

A complete desktop environment, themed after *The Index* from Project Moon.

Built on **labwc** (window manager) and **Quickshell** (bar, menus, lock).

> Install it on a fresh Arch-based system with **no desktop environment** — this
> is intended to provide the desktop environment itself.

---

## Install

You need an Arch-based system such as Arch Linux, CachyOS, or EndeavourOS.

```bash
sudo pacman -S --needed git base-devel

git clone https://github.com/Beezity/index-OS.git ~/index-OS
cd ~/index-OS
./install.sh
```

The installer uses Arch's official repositories and installs all required
packages, including `quickshell`, before any desktop configuration is applied.
If a required installation step fails, the script exits instead of continuing
with a partially configured desktop.

The installer deliberately does **not** configure TTY autologin, automatically
start labwc at login, or modify GRUB/systemd-boot/Limine/kernel command lines.

After installation, start the session from a TTY with:

```bash
dbus-run-session labwc
```

`./install.sh` is safe to run again on the intended fresh/no-other-DE setup.

---

## What you get

- **Bracket titlebars** on every window, forced server-side so apps use one bar
- **The bar** — start menu with search, workspaces, taskbar, media, network,
  Bluetooth, battery, volume, keyboard layout, tray, centred clock
- **Panels** — Wi-Fi picker, Bluetooth pairing, notification history, quick settings
- **The lock** — intro video support, scramble auth, WILL OF THE CITY fixer modal
- **Prescript of the day** — a desktop widget that scrambles into a new
  instruction each morning
- **Sound and animation** throughout, with an ON/OFF toggle
- **Standard session startup** — no autologin or bootloader modifications

---

## Make it yours

Drop a file in `assets/`, re-run `./install.sh`.

| File | What it changes |
|------|-----------------|
| `assets/intro.mp4` | lock intro video |
| `assets/sounds/bg.mp3` | lock screen music |
| `assets/DefaultProfile.jpg` | your profile picture |

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

*"We're simply carrying out our Prescript. No personal feelings are involved in this process.\t"*

`>_ THE INDEX_`

</div>
