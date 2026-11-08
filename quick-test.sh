#!/usr/bin/env bash
# Download the latest released build for this machine's Fedora/Bazzite version
# and run the on-screen keyboard test (installs nothing). Desktop Mode only.
#   ./quick-test.sh
set -euo pipefail

repo="jg00dman/bazzite-touch-unlock"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fedora="$(rpm -E %fedora)"

echo "Fetching the latest build for Fedora $fedora ..."
rm -rf "$here/dist" && mkdir -p "$here/dist/deps"
urls="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | python3 -c '
import json, sys
fed = sys.argv[1]
for a in json.load(sys.stdin)["assets"]:
    if f".fc{fed}." in a["name"] and a["name"].endswith(".rpm"):
        print(a["browser_download_url"])' "$fedora")"
[[ -n "$urls" ]] || { echo "No release build for Fedora $fedora yet; run ./build.sh instead." >&2; exit 1; }

while IFS= read -r url; do
    name="$(basename "$url")"
    case "$name" in
        unl0kr-bazzite-*) dest="$here/dist/$name" ;;
        *) dest="$here/dist/deps/$name" ;;
    esac
    curl -fsSL -o "$dest" "$url"
    echo "  got $name"
done <<< "$urls"

echo
echo "Quit Steam first if it's running (it disables the trackpad/buttons as mouse/keys)."
echo "Your sudo password is needed to switch screens and read input devices."
sudo "$here/test-on-vt.sh"
