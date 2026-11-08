#!/usr/bin/env bash
# Update Bazzite's system image and keep touch unlock working.
#   ./update.sh
#
# 1. checks touch unlock is set up now;
# 2. checks for a system update; if it moves to a new Fedora version, fetches
#    the matching touch-unlock build and swaps it in as part of the update;
# 3. installs the update (it applies on the next reboot);
# 4. checks the staged update keeps touch unlock, discarding it if not.
# After rebooting (undocked), run ./status.sh to confirm.
#
# This updates the system image only. Flatpak apps update separately (Bazaar).
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { echo; echo "ERROR: $*" >&2; exit 1; }

echo "== 1. Current state"
"$here/status.sh" || die "Touch unlock isn't fully set up now; fix that first (see above)."

set +e; rpm-ostree status --pending-exit-77 >/dev/null; rc=$?; set -e
[[ $rc -ne 77 ]] || die "An update is already staged. Reboot into it (then ./status.sh), or discard it: sudo rpm-ostree cleanup -p"
set +e

echo
echo "== 2. Checking for a system update"
check="$(sudo rpm-ostree upgrade --check 2>&1)"; rc=$?
echo "$check"
if [[ $rc -ne 0 && $rc -ne 77 ]]; then
    # Couldn't check ahead; just try the update and rely on step 4.
    echo
    echo "== 3. Couldn't check ahead; trying the update directly"
    if ! sudo rpm-ostree upgrade; then
        die "The update failed (see above); nothing was changed. If it mentions
unl0kr-bazzite, Bazzite has probably moved to a new Fedora version: get a
matching build with scripts/fetch-build.sh NN (or FEDORA_VERSION=NN ./build.sh)
and see the README."
    fi
    new_fedora=""
elif [[ $rc -eq 77 ]] || ! grep -q 'AvailableUpdate' <<< "$check"; then
    echo
    echo "No system update available. Nothing to do."
    exit 0
else
    new_version="$(sed -n 's/^ *Version: *\([0-9][0-9.]*\).*/\1/p' <<< "$check" | head -n1)"
    new_fedora="${new_version%%.*}"
    cur_fedora="$(rpm -E %fedora)"
    [[ "$new_fedora" =~ ^[0-9]+$ ]] || die "Couldn't read the new version from the output above."

    echo
    if [[ "$new_fedora" == "$cur_fedora" ]]; then
        echo "== 3. Installing update $new_version"
        sudo rpm-ostree upgrade || die "The update failed (see above). Nothing was changed."
    else
        echo "== 3. Update $new_version moves Bazzite from Fedora $cur_fedora to $new_fedora"
        echo "   Fetching the matching touch-unlock build and swapping it in."
        "$here/scripts/fetch-build.sh" "$new_fedora" \
            || die "No touch-unlock build for Fedora $new_fedora. Don't update yet, or build one: FEDORA_VERSION=$new_fedora ./build.sh"
        new_rpm="$(ls "$here"/dist/unl0kr-bazzite-*.fc"$new_fedora".*.rpm | head -n1)"
        old_pkg="$(rpm -q unl0kr-bazzite)"
        sudo rpm-ostree upgrade --uninstall="$old_pkg" --install="$new_rpm" \
            || die "The update failed (see above). Nothing was changed."
    fi
fi

echo
echo "== 4. Checking the staged update"
if "$here/status.sh"; then
    cat <<'MSG'

Update installed. Reboot (undocked) to apply it:  systemctl reboot
Afterwards run ./status.sh. When the touch unlock works, pin the new system:
  sudo ostree admin pin 0
If the unlock screen doesn't appear: boot menu (Esc, or try the B button),
pick your pinned entry, then: sudo rpm-ostree rollback
MSG
else
    echo
    echo "The staged update would not keep touch unlock. Discarding it."
    sudo rpm-ostree cleanup -p
    die "Update discarded; you're still on your current system. Please open an issue with the output above."
fi
