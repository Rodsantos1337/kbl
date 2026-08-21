#!/bin/bash
set -e

# kbl - install script
# usage: sudo ./install.sh

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

USER_NAME="${SUDO_USER:-$USER}"

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
echo "done. toggle with: kbl"
echo "optional i3 bind (~/.config/i3/config):"
echo '  bindsym $mod+b exec --no-startup-id kbl'
