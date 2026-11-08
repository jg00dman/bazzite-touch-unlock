#!/bin/bash
# Installed in the initramfs in place of unl0kr. Passes a rotation to the real
# binary: kernel argument unl0kr.rotate=0..3 wins, otherwise the console's
# current rotation (/sys/class/graphics/fbcon/rotate) is used.
rot=""
read -r cmdline < /proc/cmdline
for arg in $cmdline; do
    case "$arg" in
        unl0kr.rotate=*) rot="${arg#unl0kr.rotate=}" ;;
    esac
done
if [[ -z "$rot" && -r /sys/class/graphics/fbcon/rotate ]]; then
    read -r rot < /sys/class/graphics/fbcon/rotate
fi
case "$rot" in
    [0-3]) exec /usr/libexec/unl0kr-bin -r "$rot" "$@" ;;
esac
exec /usr/libexec/unl0kr-bin "$@"
