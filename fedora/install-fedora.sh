#!/bin/bash
set -e

# kbl - Fedora install script
# usage: sudo ./fedora/install-fedora.sh  (or sudo ./install-fedora.sh from inside fedora/)
#
# Fedora port of ../install.sh (Arch). Handles everything: official Tuxedo
# repo + drivers (if missing), module loading + boot persistence, binaries,
# sudoers rule. One password, done.
#
# Idempotent: safe to re-run.

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

USER_NAME="${SUDO_USER:-$USER}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f /etc/fedora-release ]]; then
    echo "warning: no /etc/fedora-release found - continuing anyway (expected Fedora)" >&2
fi

# --- prerequisite: tuxedo drivers (official repo) --------------------------
# clevo_acpi is what binds to the hardware - without it there is no LED and
# every keyboard cmd logs "no active interface"
echo "== [1/3] tuxedo drivers =="
if ! modinfo -n clevo_acpi >/dev/null 2>&1; then
    # config-manager lives in dnf-plugins-core; ensure present for addrepo
    dnf install -y dnf-plugins-core curl
    if [[ ! -f /etc/yum.repos.d/tuxedo.repo ]]; then
        echo "adding official Tuxedo repo for Fedora"
        dnf config-manager addrepo --from-repofile="https://rpm.tuxedocomputers.com/fedora/tuxedo.repo"
    fi
    echo "installing tuxedo-drivers (official repo, DKMS)"
    dnf install -y tuxedo-drivers
fi

if ! modinfo -n clevo_acpi >/dev/null 2>&1; then
    echo "ERROR: clevo_acpi still missing after tuxedo-drivers install." >&2
    echo "DKMS may have built for a different kernel - reboot, then re-run this script." >&2
    exit 1
fi

# load now + persist across reboots (one module per modprobe call)
lsmod | grep -q '^clevo_acpi ' || modprobe clevo_acpi || {
    echo "WARNING: modprobe clevo_acpi failed - likely needs a reboot after DKMS build." >&2
}
cat > /etc/modules-load.d/tuxedo.conf <<EOF
clevo_acpi
tuxedo_io
tuxedo_keyboard
EOF

# --- kbl itself ---------------------------------------------------------------
echo "== [2/3] install kbl =="
install -Dm755 "$REPO_ROOT/kbl"      /usr/local/bin/kbl
install -Dm755 "$REPO_ROOT/kbl-core" /usr/local/bin/kbl-core

# passwordless sudo for the toggle backend ONLY (fixed script, no arguments,
# no arbitrary command execution) - keeps `kbl` and i3 keybinds silent
echo "== [3/3] sudoers =="
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
