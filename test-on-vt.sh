#!/usr/bin/env bash
# Try the built unl0kr on a spare virtual terminal BEFORE touching boot.
# Nothing is installed: the RPM is unpacked into a temporary folder.
#
# Before running: quit Steam (Steam disables the Deck controller's
# mouse/keyboard emulation while it runs). Run from Desktop Mode:
#   sudo ./test-on-vt.sh
# Type any dummy text and press Enter (or wait 120 s) to return.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -eq 0 ]] || { echo "Run with sudo." >&2; exit 1; }

rpm_file="$(ls "$here"/dist/unl0kr-bazzite-*.rpm 2>/dev/null | grep -v '\.src\.rpm$' | sort -V | tail -n1 || true)"
[[ -n "$rpm_file" ]] || { echo "No RPM in dist/. Run ./build.sh first." >&2; exit 1; }

if pgrep -x steam >/dev/null 2>&1; then
    echo "Steam is running; the trackpad/buttons won't act as mouse/keys until you quit it."
    read -rp "Continue anyway? [y/N] " a; [[ "$a" == [yY]* ]] || exit 1
fi

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
( cd "$root" && rpm2cpio "$rpm_file" | cpio -idm --quiet )
for dep in "$here"/dist/deps/*.rpm; do
    [[ -f "$dep" ]] && ( cd "$root" && rpm2cpio "$dep" | cpio -idm --quiet )
done

bin="$root/usr/bin/unl0kr"
[[ -x "$bin" ]] || { echo "unl0kr binary not found in the RPM." >&2; exit 1; }
export LD_LIBRARY_PATH="$root/usr/lib64:$root/usr/lib"
if ldd "$bin" | grep -q 'not found'; then
    echo "Missing libraries:" >&2; ldd "$bin" | grep 'not found' >&2; exit 1
fi

conf="$root/usr/share/unl0kr/unl0kr.conf.d/50-handheld.conf"
log="$here/dist/test-on-vt.log"
orig_vt="$(fgconsole 2>/dev/null || echo 1)"

echo "Switching to a spare console now. Type dummy text, press Enter."
sleep 2
openvt -s -w -- /bin/bash -c \
    "timeout 120 '$bin' -v -C '$conf' >'$root/out' 2>'$log'; true"
chvt "$orig_vt" 2>/dev/null || true

chars="$(tr -d '\n' < "$root/out" 2>/dev/null | wc -c)"
echo
echo "unl0kr returned $chars character(s). Log: $log"
echo "Report back: did touch work? trackpad pointer + trigger click? d-pad? A/Enter?"
echo "Which way up was it, and was it usable that way?"
