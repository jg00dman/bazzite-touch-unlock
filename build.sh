#!/usr/bin/env bash
# Build an unl0kr RPM (upstream BuffyBox, unmodified) for this machine's
# Fedora release, inside a throwaway Fedora container. Output goes to ./dist/.
#
# Environment overrides:
#   FEDORA_VERSION   Fedora release to build for (default: this machine's)
#   BUFFYBOX_REF     upstream git tag to build (default: newest release tag)
#   BUFFYBOX_REPO    upstream git URL
#   ENGINE           podman or docker (default: whichever is installed)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora 2>/dev/null || true)}"
if [[ -z "$FEDORA_VERSION" || "$FEDORA_VERSION" == "%fedora" ]]; then
    echo "Could not detect the Fedora version. Set FEDORA_VERSION=NN and re-run." >&2
    exit 1
fi

export BUFFYBOX_REPO="${BUFFYBOX_REPO:-https://gitlab.postmarketos.org/postmarketOS/buffybox.git}"
export BUFFYBOX_REF="${BUFFYBOX_REF:-}"

ENGINE="${ENGINE:-$(command -v podman || command -v docker || true)}"
if [[ -z "$ENGINE" ]]; then
    echo "Need podman or docker (Bazzite ships podman)." >&2
    exit 1
fi

mkdir -p "$here/dist"
echo "Building unl0kr for Fedora $FEDORA_VERSION using $ENGINE ..."

"$ENGINE" run --rm \
    -v "$here:/src:Z" \
    -e BUFFYBOX_REPO -e BUFFYBOX_REF -e SRC=/src \
    "registry.fedoraproject.org/fedora:${FEDORA_VERSION}" \
    bash /src/scripts/container-build.sh

echo
echo "Done. Packages in: $here/dist"
ls -1 "$here/dist"
