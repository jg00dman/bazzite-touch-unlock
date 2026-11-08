# bazzite-touch-unlock

Unlock a LUKS-encrypted Bazzite handheld (e.g. Steam Deck) **without a USB
keyboard**: an on-screen keyboard you can use by touch, or with the Deck's
right trackpad as a pointer.

This repo writes no unlock code of its own. It packages
[unl0kr](https://gitlab.postmarketos.org/postmarketOS/buffybox) from the
postmarketOS BuffyBox project, **unmodified**, and wires it into Bazzite's
initramfs in place of the Plymouth password prompt.

> **Status: proof of concept, not yet tested on hardware.** Read the whole
> README and keep a USB keyboard nearby the first time.

## How it works

At boot, `systemd-cryptsetup` asks for your passphrase through systemd's
[password agent](https://systemd.io/PASSWORD_AGENTS/) mechanism. Normally
Plymouth answers, with no on-screen keyboard. This setup:

1. builds unl0kr (and its systemd password agent) from upstream into an RPM;
2. adds a dracut module that puts unl0kr, the touchscreen and Deck controller
   drivers, and handheld defaults into the initramfs;
3. removes Plymouth from the initramfs and boot, since unl0kr's agent only
   runs when Plymouth isn't.

On the Deck, with Steam not yet running, the controller is in "lizard mode":
the right trackpad moves a pointer, the triggers click, and A is Enter.

## Steps

All from Desktop Mode, in Konsole, in this folder.

1. **Optional but recommended: add a second way in first.** For example a
   FIDO2 security key (`systemd-cryptenroll --fido2-device=auto
   --fido2-with-client-pin=no`). Keep your passphrase slot.
2. **Build:** `./build.sh`  
   Builds in a Fedora container matching your Bazzite release; needs
   internet. Output goes to `dist/`.
3. **Test without touching boot:** quit Steam, then `sudo ./test-on-vt.sh`  
   unl0kr opens on a spare console. Check touch, the trackpad pointer,
   trigger clicks, the d-pad and the A button, and which way up it draws.
   Type dummy text and press Enter to come back.
4. **Install:** `sudo ./setup.sh`
5. **Reboot** and unlock on screen.

### If it goes wrong

- Plug in the USB keyboard: unl0kr accepts hardware keyboards too.
- Or pick the previous entry in the boot menu (setup pins it, so it stays).
  Bazzite hides the menu; with a USB keyboard attached, press Esc during boot.
- Once booted: `sudo ./uninstall.sh`, then reboot.

### Changing settings

Put overrides in `/etc/unl0kr.conf.d/`, then `sudo ./setup.sh --regenerate` and reboot.
Defaults are in `conf/50-handheld.conf`.

## Known unknowns

These are what hardware testing needs to answer:

- orientation: the Deck panel is natively portrait and unl0kr 3.6.0 has no
  rotation option for its DRM backend (the only one Bazzite's kernel supports),
  so expect a portrait screen; touch should still line up;
- unl0kr opens the first `/dev/dri/card*` it finds, which may not be the
  amdgpu card early in boot;
- whether upstream detects the Deck controller (a combined keyboard + touchpad
  device) correctly;
- whether the d-pad moves around the on-screen keyboard (touch and trackpad
  are the controls this setup relies on; unl0kr isn't patched either way);
- that the dracut module finds unl0kr's agent and units where the upstream
  release installs them.

## What it changes

Listed at the top of `setup.sh`; all reversed by `uninstall.sh`. Updates keep
working: rpm-ostree rebuilds the initramfs with unl0kr on every update, which
makes updates a little slower.

## Licensing and credits

- unl0kr / BuffyBox: GPL-3.0-or-later, by the postmarketOS BuffyBox
  contributors. This repo downloads and builds it; it does not modify it.
- The scripts in this repo were written with AI assistance (Claude) and
  reviewed by the maintainer. **No AI-generated contributions have been or
  will be sent to postmarketOS**, which forbids them; this project only
  consumes their release.
