# kbl

Keyboard backlight toggle for the **Gigabyte G5 KF** on Linux (works on any
machine exposing the LED via `tuxedo_keyboard`).

`kbl` toggles the RGB keyboard backlight between:

*   **off**
*   **everforest green** (`167 192 128`) at low brightness (`40/255`)

Fixed config by design - no colors, no brightness arguments. Just a toggle.

## How it works

The backlight is the `rgb:kbd_backlight` LED exposed by the `tuxedo_keyboard`
kernel module:

```
/sys/class/leds/rgb:kbd_backlight/brightness       # 0-255, read = state
/sys/class/leds/rgb:kbd_backlight/multi_intensity  # "R G B" color
```

LED sysfs is root-only writable, so the toggle runs through sudo with a
**scoped** NOPASSWD rule - `kbl` and i3 keybinds are fully passwordless.

## Prerequisites (handled by install.sh)

`kbl` needs three kernel modules loaded - **and `clevo_acpi` is the one that
actually binds to the hardware**. Loading only `tuxedo_io` +
`tuxedo_keyboard` gives you a silent failure: no LED appears and every
keyboard command logs
`clevo_keyboard: no active interface while attempting cmd ...`.

**The installer now does all of this automatically**: it installs
`tuxedo-drivers-dkms` via your AUR helper if missing, loads `clevo_acpi`,
writes `/etc/modules-load.d/tuxedo.conf` for boot persistence, and warns you
if a reboot is needed. Just run `sudo ./install.sh`.

Manual fallback (e.g. after adding the drivers outside the installer), on
plain Arch (this machine runs `linux-zen`):

```bash
yay -S tuxedo-drivers-dkms          # needs matching kernel headers installed
sudo modprobe clevo_acpi            # loads tuxedo_io + tuxedo_keyboard as deps
printf 'clevo_acpi\ntuxedo_io\ntuxedo_keyboard\n' | \
    sudo tee /etc/modules-load.d/tuxedo.conf    # persist across reboots
```

Verify before installing:

```bash
ls /sys/class/leds/ | grep kbd_backlight   # want: rgb:kbd_backlight
```

If the module was already half-loaded when you ran modprobe, reboot once -
the `modules-load.d` entry above will bring everything up cleanly.

> Gotcha: `modprobe` takes **one** module per call. `sudo modprobe a b`
> silently ignores `b` as an unknown parameter of `a`.

## Install - final setup

> **Fedora?** Use `sudo ./fedora/install-fedora.sh` instead — see
> [`fedora/README.md`](fedora/README.md). All Fedora-specific files live in
> `fedora/`; shared scripts are identical on both distros.

One password (the last one you'll type for this) - covers drivers, modules,
binaries and sudoers:

```bash
git clone https://github.com/Rodsantos1337/kbl.git
cd kbl
sudo ./install.sh
```

What it does: installs `tuxedo-drivers-dkms` if missing, loads + persists the
`tuxedo` modules, installs `kbl` + `kbl-core` to `/usr/local/bin/`, writes
`/etc/sudoers.d/kbl` (`<user> ALL=(root) NOPASSWD: /usr/local/bin/kbl-core`)
and validates it with `visudo -c`. Nothing else runs passwordless.

Then test: `kbl` → "keyboard light: on (everforest green, low)" / `kbl` again
→ "keyboard light: off".

## i3 keybind

```bash
bindsym $mod+b exec --no-startup-id kbl
```

Reload i3 with `$mod+Shift+c`.

## Changing the look (only if you ever want to)

Edit the two variables at the top of `kbl-core`, then reinstall:

*   `GREEN="167 192 128"` - RGB color (everforest green)
*   `LOW=40` - brightness out of 255

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `No such file or directory: rgb:kbd_backlight/...` + claims success | LED doesn't exist - `clevo_acpi` not bound | See [Prerequisites](#prerequisites-do-this-first); check `journalctl -k \| grep clevo` |
| LED gone after reboot | Modules not persisted | `/etc/modules-load.d/tuxedo.conf` missing |
| Asks for password | sudoers rule stale | Re-run `sudo ./install.sh` |

## Files

*   `kbl` - wrapper: `exec sudo /usr/local/bin/kbl-core` (silent via sudoers)
*   `kbl-core` - the actual toggle (fixed everforest green config)
*   `install.sh` - installer + scoped sudoers rule
*   `fedora/` - Fedora port: `install-fedora.sh` (official Tuxedo repo), `README.md`
