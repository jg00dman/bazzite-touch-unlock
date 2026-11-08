#!/usr/bin/env bash
# Download the latest released build for this machine's Fedora/Bazzite version
# and run the on-screen keyboard test (installs nothing). Desktop Mode only.
#   ./quick-test.sh            (with the Deck orientation patches)
#   PATCHES=0 ./quick-test.sh  (plain upstream unl0kr)
set -euo pipefail

repo="jg00dman/bazzite-touch-unlock"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fedora="$(rpm -E %fedora)"

echo "Fetching the latest build for Fedora $fedora ..."
rm -rf "$here/dist" && mkdir -p "$here/dist/deps"
release_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/tags/test-build")" \
    || { echo "Couldn't fetch the test build from GitHub." >&2; exit 1; }
urls="$(printf '%s' "$release_json" | python3 -c '
import json, sys
fed, patched = sys.argv[1], sys.argv[2] != "0"
assets = [a for a in json.load(sys.stdin)["assets"]
          if f".fc{fed}." in a["name"] and a["name"].endswith(".rpm")]
main = [a for a in assets if a["name"].startswith("unl0kr-bazzite-")
        and (".deck." in a["name"]) == patched]
deps = [a for a in assets if not a["name"].startswith("unl0kr-bazzite-")]
for a in sorted(main, key=lambda a: a["updated_at"])[-1:] + deps:
    print(a["browser_download_url"])' "$fedora" "${PATCHES:-1}")"
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
