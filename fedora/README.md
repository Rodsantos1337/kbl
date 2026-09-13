# kbl — Fedora support (`fedora/`)

Fedora port of the Arch installer. Shared scripts (`kbl`, `kbl-core`) live at
the repo root and are identical on both distros — everything Fedora-specific
lives in this folder.

## Install (Fedora 44+, Gigabyte G5 KF / Clevo NP50RND)

```bash
git clone https://github.com/Rodsantos1337/kbl.git
cd kbl
sudo ./fedora/install-fedora.sh
```

What `install-fedora.sh` does (mirrors `../install.sh` for Arch):

1. Adds the **official Tuxedo repo** (`rpm.tuxedocomputers.com/fedora/tuxedo.repo`)
   if `clevo_acpi` is missing, then `dnf install -y tuxedo-drivers` (DKMS).
2. Loads `clevo_acpi` + persists `clevo_acpi/tuxedo_io/tuxedo_keyboard` in
   `/etc/modules-load.d/tuxedo.conf`.
3. Installs `kbl` + `kbl-core` to `/usr/local/bin/`.
4. Writes scoped sudoers rule `<user> ALL=(root) NOPASSWD: /usr/local/bin/kbl-core`
   and validates with `visudo -c`.

Idempotent: safe to re-run.

## Verify

```bash
kbl   # -> "keyboard light: on (everforest green, low)"
kbl   # -> "keyboard light: off"
ls /sys/class/leds/ | grep kbd_backlight   # want: rgb:kbd_backlight
```

If the LED is missing right after install, reboot once (DKMS module was
built for the new kernel but the old one is still running), then re-check.

## Secure Boot

DKMS modules require MOK enrollment when Secure Boot is on. This laptop runs
with Secure Boot disabled, so no extra step is needed.

## Files here

* `install-fedora.sh` — Fedora installer (run with sudo)
* `README.md` — this file
