#!/usr/bin/env bash
# CI check (inside a Fedora container): install the built RPM and build a
# kernel-less initramfs the way setup.sh configures it, then confirm the
# unl0kr pieces AND the disk-unlock pieces are in it. Doesn't prove it boots.
set -euo pipefail
SRC="${SRC:-/src}"
dnf -y install dracut systemd cryptsetup plymouth binutils >/dev/null
dnf -y install "$SRC"/dist/unl0kr-bazzite-*.rpm "$SRC"/dist/deps/inih-*.x86_64.rpm >/dev/null 2>&1 \
    || dnf -y install "$SRC"/dist/unl0kr-bazzite-*.rpm
echo 'add_dracutmodules+=" unl0kr "' > /etc/dracut.conf.d/90-bazzite-touch-unlock.conf

img="$(mktemp -d)/initramfs.img"
dracut --no-kernel --no-hostonly --add "crypt systemd-cryptsetup" -f "$img"
list="$(lsinitrd "$img")"

fail=0
for want in \
    usr/bin/unl0kr \
    usr/libexec/unl0kr-agent \
    usr/libexec/unl0kr-wait-drm \
    usr/lib/systemd/system/unl0kr-agent.path \
    usr/lib/systemd/system/unl0kr-agent.service \
    usr/lib/systemd/system/sysinit.target.wants/unl0kr-agent.path \
    usr/lib/systemd/system/unl0kr-agent.service.d/10-bazzite-touch-unlock.conf \
    usr/lib/systemd/system/systemd-ask-password-plymouth.path.d/10-bazzite-touch-unlock.conf \
    usr/share/unl0kr/unl0kr.conf.d/50-handheld.conf \
    usr/lib/systemd/system-generators/systemd-cryptsetup-generator \
    usr/bin/plymouth
do
    if grep -q " $want\$\| $want ->" <<< "$list"; then
        echo "ok      $want"
    else
        echo "MISSING $want"; fail=1
    fi
done
# Plymouth/console agents must not be masked.
if grep -E 'systemd-ask-password-(console|plymouth)\.(path|service) -> /dev/null' <<< "$list"; then
    echo "MASKED password agent found"; fail=1
fi
exit $fail
