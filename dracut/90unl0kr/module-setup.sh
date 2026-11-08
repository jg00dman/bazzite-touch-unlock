#!/usr/bin/bash
# dracut module: use upstream unl0kr as the systemd password agent in the
# initramfs, so LUKS passphrases can be entered by touch or pointer.
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
    # drm: display drivers are normally pulled in by plymouth, which we omit.
    echo systemd drm
    return 0
}

installkernel() {
    # Input stack, Steam Deck controller (lizard mode = mouse/keys),
    # and common touchscreen paths (the Deck's is I2C HID multitouch).
    instmods evdev hid-generic usbhid hid-steam hid-multitouch \
        i2c-hid i2c-hid-acpi
    instmods =drivers/input/touchscreen
}

install() {
    local real agent unit f
    real="$(command -v unl0kr)"
    agent="$(_unl0kr_agent)"

    inst_binary "$real"
    inst_binary "$agent"

    for unit in unl0kr-agent.path unl0kr-agent.service; do
        inst_simple "$systemdsystemunitdir/$unit"
    done
    mkdir -p "$initdir$systemdsystemunitdir/sysinit.target.wants"
    ln_r "$systemdsystemunitdir/unl0kr-agent.path" \
        "$systemdsystemunitdir/sysinit.target.wants/unl0kr-agent.path"

    # Config: upstream defaults, our handheld defaults, user overrides.
    for f in /usr/share/unl0kr/unl0kr.conf /usr/share/unl0kr/unl0kr.conf.d/* \
             /etc/unl0kr.conf /etc/unl0kr.conf.d/*; do
        [[ -f "$f" ]] && inst_simple "$f"
    done

    # Data libinput and xkbcommon need at runtime.
    inst_multiple -o /usr/lib/udev/hwdb.bin /etc/udev/hwdb.bin
    while IFS= read -r f; do inst_simple "$f"; done \
        < <(find /usr/share/libinput /usr/share/X11/xkb -type f 2>/dev/null)

    # Only one agent should own the screen.
    $SYSTEMCTL -q --root "$initdir" mask \
        systemd-ask-password-console.path systemd-ask-password-console.service \
        systemd-ask-password-plymouth.path systemd-ask-password-plymouth.service || :
}
