#!/usr/bin/env bash
# Undo setup.sh:  sudo ./uninstall.sh
set -euo pipefail

state_file=/etc/bazzite-touch-unlock/state
dracut_conf=/etc/dracut.conf.d/90-bazzite-touch-unlock.conf

[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

initramfs_was_enabled=no
[[ -f "$state_file" ]] && . "$state_file"

echo "==> Removing layered package"
if rpm -q unl0kr-bazzite >/dev/null 2>&1 || rpm-ostree status | grep -q unl0kr-bazzite; then
    rpm-ostree uninstall unl0kr-bazzite || true
fi

echo "==> Removing dracut config"
rm -f "$dracut_conf"

echo "==> Restoring kernel arguments"
kargs=(--delete-if-present=rd.plymouth=0 --delete-if-present=plymouth.enable=0)
current_rotate="$(rpm-ostree kargs | tr ' ' '\n' | grep '^unl0kr.rotate=' || true)"
[[ -n "$current_rotate" ]] && kargs+=("--delete-if-present=$current_rotate")
rpm-ostree kargs "${kargs[@]}"

if [[ "$initramfs_was_enabled" != "yes" ]]; then
    echo "==> Turning local initramfs regeneration back off"
    rpm-ostree initramfs --disable || true
fi

rm -rf /etc/bazzite-touch-unlock

cat <<'EOF'

Done. Reboot to return to the normal Plymouth password screen.
The fallback deployment is still pinned; list with `rpm-ostree status`
and unpin with `sudo ostree admin pin --unpin <index>` if you want.
EOF
