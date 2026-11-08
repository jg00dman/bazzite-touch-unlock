#!/usr/bin/env bash
# Runs INSIDE a Fedora container (called by build.sh or CI).
# Fetches upstream BuffyBox, builds an RPM containing unl0kr, its systemd
# password agent, and this repo's dracut module and handheld defaults.
set -euo pipefail

SRC="${SRC:-/src}"
BUFFYBOX_REPO="${BUFFYBOX_REPO:-https://gitlab.postmarketos.org/postmarketOS/buffybox.git}"
BUFFYBOX_REF="${BUFFYBOX_REF:-}"

dnf -y install \
    git rpm-build tar gzip meson ninja-build gcc pkgconf-pkg-config \
    libinput-devel libxkbcommon-devel systemd-devel inih-devel \
    libdrm-devel scdoc

work="$(mktemp -d)"
cd "$work"

if [[ -z "$BUFFYBOX_REF" ]]; then
    BUFFYBOX_REF="$(git ls-remote --tags --refs "$BUFFYBOX_REPO" \
        | awk -F/ '{print $NF}' \
        | grep -E '^v?[0-9]+(\.[0-9]+)*$' \
        | sort -V | tail -n1)"
fi
[[ -n "$BUFFYBOX_REF" ]] || { echo "No upstream release tag found." >&2; exit 1; }
echo "Using upstream BuffyBox $BUFFYBOX_REF"

git clone --depth 1 --branch "$BUFFYBOX_REF" \
    --recurse-submodules --shallow-submodules \
    "$BUFFYBOX_REPO" buffybox

if [[ ! -f buffybox/unl0kr/unl0kr-agent.c ]]; then
    echo "BuffyBox $BUFFYBOX_REF has no systemd password agent; need a newer release." >&2
    exit 1
fi

version="${BUFFYBOX_REF#v}"
topdir="$work/rpmbuild"
mkdir -p "$topdir/SOURCES"

tar -czf "$topdir/SOURCES/buffybox-$version.tar.gz" buffybox

# This repo's integration files (dracut module + config), shipped in the RPM.
mkdir -p extra
cp -r "$SRC/dracut" "$SRC/conf" extra/
tar -czf "$topdir/SOURCES/bazzite-touch-unlock-extra.tar.gz" extra

rpmbuild -bb "$SRC/packaging/unl0kr-bazzite.spec" \
    --define "_topdir $topdir" \
    --define "upstream_version $version"

mkdir -p "$SRC/dist" "$SRC/dist/deps"
cp "$topdir"/RPMS/*/*.rpm "$SRC/dist/"

# Runtime libraries Bazzite may not ship, used only by test-on-vt.sh for the
# pre-reboot test. (rpm-ostree pulls real dependencies itself when layering.)
dnf -y download --destdir "$SRC/dist/deps" inih || true

echo "Built: $(ls "$topdir"/RPMS/*/*.rpm)"
