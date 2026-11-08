#!/usr/bin/env bash
# Check that touch unlock is still set up, e.g. after a Bazzite update.
#   ./status.sh
set -uo pipefail

fedora="$(rpm -E %fedora)"
pkg="$(rpm -q unl0kr-bazzite 2>/dev/null || true)"
ok=1

echo "Bazzite is on Fedora $fedora, kernel $(uname -r)."

if [[ "$pkg" == unl0kr-bazzite-* ]]; then
    echo "Installed package: $pkg"
    if [[ "$pkg" != *".fc$fedora."* ]]; then
        echo "  ! Built for a different Fedora version. Get a matching build"
        echo "    (./quick-test.sh, or ./build.sh) and run: sudo ./setup.sh"
        ok=0
    fi
else
    echo "  ! unl0kr-bazzite is not installed in the running system."
    ok=0
fi

# Which boot image did we start from? (ostree=/ostree/boot.N/<os>/<csum>/<n>)
ostree_arg="$(tr ' ' '\n' < /proc/cmdline | grep '^ostree=' | cut -d= -f2)"
osname="$(cut -d/ -f4 <<< "$ostree_arg")"
csum="$(cut -d/ -f5 <<< "$ostree_arg")"
img="/boot/ostree/$osname-$csum/initramfs-$(uname -r).img"
if [[ -f "$img" ]]; then
    mods="$(sudo lsinitrd -m "$img" 2>/dev/null)"
    if grep -qw unl0kr <<< "$mods"; then
        echo "Current boot image includes unl0kr: yes"
    else
        echo "  ! Current boot image does not include unl0kr."
        ok=0
    fi
else
    echo "  ? Couldn't find the current boot image to check."
fi

echo
rpm-ostree status | grep -E '^[ ●]+ostree|Version:|Pinned:|LocalPackages:' \
    | sed -E 's/^ *● */* booted: /; s/^ +ostree/  other:  ostree/'

if rpm-ostree status --pending-exit-77 >/dev/null 2>&1; then
    :
elif [[ $? -eq 77 ]]; then
    echo
    echo "An update is staged and will apply on the next reboot."
    echo "Reboot undocked, with your USB keyboard or pinned entry as fallback."
fi

echo
if [[ $ok -eq 1 ]]; then
    echo "Touch unlock: set up."
else
    echo "Touch unlock: needs attention (see ! above)."
fi
