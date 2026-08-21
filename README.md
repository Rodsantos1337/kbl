# kbl

Keyboard backlight toggle for the **Gigabyte G5 KF** on Linux (works on any
machine exposing the LED via `tuxedo_keyboard`).

`kbl` toggles the RGB keyboard backlight between:

*   **off**
*   **everforest green** (`167 192 128`) at low brightness (`40/255`)

Fixed config by design - no colors, no brightness arguments. Just a toggle.

## How it works

The backlight is the `rgb:kbd_backlight` LED exposed by the `tuxedo_keyboard`
kernel module (same driver family that powers fan control via `tuxedo_io`):

```
/sys/class/leds/rgb:kbd_backlight/brightness       # 0-255, read = state
/sys/class/leds/rgb:kbd_backlight/multi_intensity  # "R G B" color
```

LED sysfs is root-only writable, so the toggle runs through sudo with a
**scoped** NOPASSWD rule - `kbl` and i3 keybinds are fully passwordless.

## Install - final setup

One password (the last one you'll type for this):

```bash
git clone https://github.com/Rodsantos1337/kbl.git
cd kbl
sudo ./install.sh
```

What it does: installs `kbl` + `kbl-core` to `/usr/local/bin/`, writes
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

## Prerequisite

`tuxedo-drivers` / `tuxedo-keyboard` must be loaded so the LED exists:

```bash
ls /sys/class/leds/ | grep kbd_backlight   # want: rgb:kbd_backlight
```

## Files

*   `kbl` - wrapper: `exec sudo /usr/local/bin/kbl-core` (silent via sudoers)
*   `kbl-core` - the actual toggle (fixed everforest green config)
*   `install.sh` - installer + scoped sudoers rule
