#!/usr/bin/bash
# dracut module: use upstream unl0kr as the systemd password agent in the
# initramfs, so LUKS passphrases can be entered by touch, pointer or keyboard.
# Plymouth stays for the splash; unl0kr borrows the display while asking.
# The Plymouth/DRM hand-over approach is from erdii/bazzite-playground.
# Only included when explicitly requested (add_dracutmodules+=" unl0kr ").

_unl0kr_agent() {
    local p
    for p in /usr/libexec/unl0kr-agent /usr/lib/unl0kr/unl0kr-agent /usr/lib/unl0kr-agent; do
        [[ -x "$p" ]] && { echo "$p"; return 0; }
    done
    return 1
}

check() {
    require_binaries unl0kr || return 1
    _unl0kr_agent >/dev/null || return 1
    return 255
}

depends() {
    echo systemd drm
    return 0
}

installkernel() {
    # Display (Steam Deck: amdgpu), input stack, Deck controller (lizard
    # mode), and common touchscreen paths (the Deck's is I2C HID multitouch).
    instmods amdgpu evdev hid-generic usbhid hid-steam hid-multitouch \
        i2c-hid i2c-hid-acpi
    instmods =drivers/input/touchscreen
}

install() {
    local unit f
    inst_binary "$(command -v unl0kr)"
    inst_binary "$(_unl0kr_agent)"

    for unit in unl0kr-agent.path unl0kr-agent.service; do
        inst_simple "$systemdsystemunitdir/$unit"
    done
    mkdir -p "$initdir$systemdsystemunitdir/sysinit.target.wants"
    ln_r "$systemdsystemunitdir/unl0kr-agent.path" \
        "$systemdsystemunitdir/sysinit.target.wants/unl0kr-agent.path"

    # Wait for the real GPU driver, and hand the display over from plymouth.
    inst_script "$moddir/unl0kr-wait-drm" /usr/libexec/unl0kr-wait-drm
    inst_multiple sh cat sleep readlink timeout kill
    inst_simple "$moddir/unl0kr-agent.path.conf" \
        "$systemdsystemunitdir/unl0kr-agent.path.d/10-bazzite-touch-unlock.conf"
    inst_simple "$moddir/unl0kr-agent.service.conf" \
        "$systemdsystemunitdir/unl0kr-agent.service.d/10-bazzite-touch-unlock.conf"
    inst_simple "$moddir/systemd-ask-password-plymouth.path.conf" \
        "$systemdsystemunitdir/systemd-ask-password-plymouth.path.d/10-bazzite-touch-unlock.conf"

    # Config: upstream defaults, our handheld defaults, user overrides.
    for f in /usr/share/unl0kr/unl0kr.conf /usr/share/unl0kr/unl0kr.conf.d/* \
             /etc/unl0kr.conf /etc/unl0kr.conf.d/*; do
        [[ -f "$f" ]] && inst_simple "$f"
    done

    # Data libinput and xkbcommon need at runtime.
    inst_multiple -o /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin
    while IFS= read -r f; do inst_simple "$f"; done \
        < <(find /usr/share/libinput /usr/share/X11/xkb -type f 2>/dev/null)
}
