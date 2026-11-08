#!/usr/bin/env bash
# Install unl0kr as the LUKS unlock screen on Bazzite (rpm-ostree).
#
#   sudo ./setup.sh [--rpm PATH] [--yes]
#   sudo ./setup.sh --regenerate      # rebuild initramfs after config changes
#
# What it changes (all reversible with ./uninstall.sh):
#   - pins your current deployment so it stays in the boot menu as a fallback
#   - layers the unl0kr-bazzite RPM
#   - /etc/dracut.conf.d/90-bazzite-touch-unlock.conf (add unl0kr, drop plymouth)
#   - enables local initramfs regeneration
#   - kernel args: rd.plymouth=0 plymouth.enable=0
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_dir=/etc/bazzite-touch-unlock
state_file="$state_dir/state"
dracut_conf=/etc/dracut.conf.d/90-bazzite-touch-unlock.conf

rpm_file=""; assume_yes=0; regenerate=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rpm) rpm_file="$2"; shift 2 ;;
        --yes|-y) assume_yes=1; shift ;;
        --regenerate) regenerate=1; shift ;;
        -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die "Run with sudo."
command -v rpm-ostree >/dev/null || die "This is for rpm-ostree systems like Bazzite."

if [[ $regenerate -eq 1 ]]; then
    [[ -f "$state_file" ]] || die "Not set up yet."
    rpm-ostree initramfs --disable
    rpm-ostree initramfs --enable
    echo "Initramfs will be rebuilt with your current config. Reboot to apply."
    exit 0
fi

lsblk -rno TYPE | grep -qx crypt || die "No LUKS-encrypted device found; nothing to unlock."

if [[ -z "$rpm_file" ]]; then
    rpm_file="$(ls "$here"/dist/unl0kr-bazzite-*.rpm 2>/dev/null | grep -v '\.src\.rpm$' | sort -V | tail -n1 || true)"
fi
[[ -f "$rpm_file" ]] || die "No RPM found. Run ./build.sh first (or pass --rpm)."

set +e; rpm-ostree status --pending-exit-77 >/dev/null; rc=$?; set -e
[[ $rc -ne 77 ]] || die "An update is already staged. Reboot into it first (or run: rpm-ostree cleanup -p)."

initramfs_was_enabled="$(rpm-ostree status --json | python3 -c '
import json, sys
d = json.load(sys.stdin)["deployments"]
b = next(x for x in d if x.get("booted"))
print("yes" if b.get("regenerate-initramfs") else "no")')"

cat <<EOF

This will make unl0kr (on-screen keyboard) your disk unlock screen.
  Package:  $(basename "$rpm_file")

Keep a USB keyboard nearby for the first boot. If the new screen doesn't
work, pick the previous (pinned) entry in the boot menu, then run
./uninstall.sh. Did ./test-on-vt.sh work for you first?
EOF
if [[ $assume_yes -ne 1 ]]; then
    read -rp "Proceed? [y/N] " a; [[ "$a" == [yY]* ]] || exit 1
fi

mkdir -p "$state_dir"
if [[ ! -f "$state_file" ]]; then
    printf 'initramfs_was_enabled=%s\n' "$initramfs_was_enabled" > "$state_file"
fi

echo "==> Pinning current deployment as a fallback"
ostree admin pin 0

echo "==> Writing $dracut_conf"
mkdir -p /etc/dracut.conf.d
cat > "$dracut_conf" <<'EOF'
# Managed by bazzite-touch-unlock. Remove with uninstall.sh.
add_dracutmodules+=" unl0kr "
omit_dracutmodules+=" plymouth "
EOF

echo "==> Layering $(basename "$rpm_file")"
if rpm-ostree status --booted | grep -q 'unl0kr-bazzite'; then
    rpm-ostree uninstall unl0kr-bazzite --install "$rpm_file"
else
    rpm-ostree install --idempotent "$rpm_file"
fi

echo "==> Enabling local initramfs regeneration"
if [[ "$initramfs_was_enabled" != "yes" ]]; then
    rpm-ostree initramfs --enable
fi

echo "==> Setting kernel arguments"
kargs=(--append-if-missing=rd.plymouth=0 --append-if-missing=plymouth.enable=0)
rpm-ostree kargs "${kargs[@]}"

cat <<'EOF'

Done. Reboot to try it:  systemctl reboot

If the unlock screen fails: use the USB keyboard, or choose the previous
(pinned) boot entry, then run: sudo ./uninstall.sh
EOF
