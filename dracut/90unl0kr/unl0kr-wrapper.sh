#!/bin/bash
# Installed in the initramfs in place of unl0kr. If the kernel argument
# unl0kr.rotate=0..3 is set, it is passed to the real binary as -r.
# (Upstream unl0kr's DRM backend may not support rotation; without it the
# UI is drawn in the panel's native orientation, which on the Steam Deck is
# portrait. Touch input stays aligned either way.)
rot=""
read -r cmdline < /proc/cmdline
for arg in $cmdline; do
    case "$arg" in
        unl0kr.rotate=*) rot="${arg#unl0kr.rotate=}" ;;
    esac
done
case "$rot" in
    [0-3]) exec /usr/libexec/unl0kr-bin -r "$rot" "$@" ;;
esac
exec /usr/libexec/unl0kr-bin "$@"
