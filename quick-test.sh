#!/usr/bin/env bash
# Download the latest released build for this machine's Fedora/Bazzite version
# and run the on-screen keyboard test (installs nothing). Desktop Mode only.
#   ./quick-test.sh            (with the Deck orientation patches)
#   PATCHES=0 ./quick-test.sh  (plain upstream unl0kr)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$here/scripts/fetch-build.sh"

echo
echo "Quit Steam first if it's running (it disables the trackpad/buttons as mouse/keys)."
echo "Your sudo password is needed to switch screens and read input devices."
sudo "$here/test-on-vt.sh"
