#!/bin/bash
set -e

# kbl - install script
# usage: sudo ./install.sh
#
# Handles everything: tuxedo drivers (if missing), module loading + boot
# persistence, binaries, sudoers rule. One password, done.

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

USER_NAME="${SUDO_USER:-$USER}"

# --- prerequisite: tuxedo drivers ------------------------------------------
# clevo_acpi is what binds to the hardware - without it there is no LED and
# every keyboard cmd logs "no active interface"

if ! modinfo -n clevo_acpi >/dev/null 2>&1; then
    HELPER="$(command -v yay || command -v paru || true)"
    if [ -z "$HELPER" ]; then
        echo "ERROR: clevo_acpi module missing and no AUR helper (yay/paru) found."
        echo "Install tuxedo-drivers-dkms manually, then re-run this script."
        exit 1
    fi
    if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
        echo "WARNING: kernel headers for $(uname -r) missing - DKMS build will fail."
        echo "Install them (e.g. linux-zen-headers), then re-run."
        exit 1
    fi
    echo "== tuxedo-drivers not found - installing tuxedo-drivers-dkms =="
    sudo -u "$USER_NAME" "$HELPER" -S --needed tuxedo-drivers-dkms
fi

# load now + persist across reboots
lsmod | grep -q '^clevo_acpi ' || modprobe clevo_acpi
cat > /etc/modules-load.d/tuxedo.conf <<EOF
clevo_acpi
tuxedo_io
tuxedo_keyboard
EOF

# --- kbl itself -------------------------------------------------------------

install -Dm755 kbl      /usr/local/bin/kbl
install -Dm755 kbl-core /usr/local/bin/kbl-core

# passwordless sudo for the toggle backend ONLY (fixed script, no arguments,
# no arbitrary command execution) - keeps `kbl` and i3 keybinds silent
cat > /etc/sudoers.d/kbl <<EOF
${USER_NAME} ALL=(root) NOPASSWD: /usr/local/bin/kbl-core
EOF
chmod 440 /etc/sudoers.d/kbl
visudo -c

echo
if [ -e /sys/class/leds/rgb:kbd_backlight/brightness ]; then
    echo "done. toggle with: kbl"
else
    echo "installed, but rgb:kbd_backlight doesn't exist yet -"
    echo "the module was likely half-loaded before this install. Reboot once,"
    echo "then kbl will work (modules are persisted in /etc/modules-load.d)."
fi
echo "optional i3 bind (~/.config/i3/config):"
echo '  bindsym $mod+b exec --no-startup-id kbl'
