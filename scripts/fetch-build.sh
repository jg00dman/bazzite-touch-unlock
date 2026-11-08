#!/usr/bin/env bash
# Download the latest published build for a Fedora version into dist/.
#   scripts/fetch-build.sh [FEDORA_VERSION]      (default: this machine's)
# PATCHES=0 picks plain upstream instead of the Deck-patched build.
# Exits 3 if no build exists for that Fedora version.
set -euo pipefail

repo="jg00dman/bazzite-touch-unlock"
top="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fedora="${1:-$(rpm -E %fedora)}"

echo "Fetching the latest build for Fedora $fedora ..."
release_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/tags/test-build")" \
    || { echo "Couldn't fetch the build list from GitHub." >&2; exit 1; }
urls="$(printf '%s' "$release_json" | python3 -c '
import json, sys
fed, patched = sys.argv[1], sys.argv[2] != "0"
assets = [a for a in json.load(sys.stdin)["assets"]
          if f".fc{fed}." in a["name"] and a["name"].endswith(".rpm")]
main = [a for a in assets if a["name"].startswith("unl0kr-bazzite-")
        and (".deck." in a["name"]) == patched]
deps = [a for a in assets if not a["name"].startswith("unl0kr-bazzite-")]
if main:
    for a in sorted(main, key=lambda a: a["updated_at"])[-1:] + deps:
        print(a["browser_download_url"])' "$fedora" "${PATCHES:-1}")"
if [[ -z "$urls" ]]; then
    echo "No published build for Fedora $fedora yet." >&2
    echo "Build one locally with: FEDORA_VERSION=$fedora ./build.sh" >&2
    exit 3
fi

rm -rf "$top/dist" && mkdir -p "$top/dist/deps"
while IFS= read -r url; do
    name="$(basename "$url")"
    case "$name" in
        unl0kr-bazzite-*) dest="$top/dist/$name" ;;
        *) dest="$top/dist/deps/$name" ;;
    esac
    curl -fsSL -o "$dest" "$url"
    echo "  got $name"
done <<< "$urls"
