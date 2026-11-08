# bazzite-touch-unlock

Unlock a LUKS-encrypted Bazzite handheld (e.g. Steam Deck) **without a USB
keyboard**: an on-screen keyboard you can use by touch, or with the Deck's
right trackpad as a pointer.

This repo writes no unlock code of its own. It packages
[unl0kr](https://gitlab.nura.eco/postmarketOS/buffybox) from the BuffyBox
project (postmarketOS, now Nura) and wires it into Bazzite's initramfs in place
of the Plymouth password prompt. By default it applies four small downstream
patches by erdii for screen and trackpad orientation on the Deck; see
[patches/](patches/README.md). These are not submitted upstream. Build with
`PATCHES=0 ./build.sh` for unmodified upstream.

> **Status: proof of concept, not yet tested on hardware.** Read the whole
> README and keep a USB keyboard nearby the first time.

## How it works

At boot, `systemd-cryptsetup` asks for your passphrase through systemd's
[password agent](https://systemd.io/PASSWORD_AGENTS/) mechanism. Normally
Plymouth answers, with no on-screen keyboard. This setup:

1. builds unl0kr (and its systemd password agent) from upstream into an RPM;
2. adds a dracut module that puts unl0kr, the touchscreen and Deck controller
   drivers, and handheld defaults into the initramfs;
3. keeps Plymouth for the boot splash, but stops it asking for the
   passphrase; unl0kr waits for the Deck's GPU driver, borrows the display
   from Plymouth while asking, then hands it back (approach from erdii).

On the Deck, with Steam not yet running, the controller is in "lizard mode":
the right trackpad moves a pointer, the triggers click, and A is Enter.

## Quick test (no install, nothing changed)

In Desktop Mode, open Konsole and run:

```
git clone https://github.com/jg00dman/bazzite-touch-unlock ~/bazzite-touch-unlock && ~/bazzite-touch-unlock/quick-test.sh
```

It downloads the latest build for your Bazzite version and opens unl0kr on a
spare screen. Type anything and press Enter (or wait two minutes) to return.

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

- with an external monitor connected, the patched build showed nothing at
  all in testing; unplug it to test and to boot (cause not yet known);

These are what hardware testing needs to answer:

- whether the orientation patches rotate the screen, touch and trackpad
  correctly on real hardware (unpatched: portrait screen, touch fine,
  trackpad axes wrong);
- unl0kr opens the first `/dev/dri/card*` it finds, which may not be the
  amdgpu card early in boot;
- whether the d-pad moves around the on-screen keyboard (touch and trackpad
  are the controls this setup relies on; unl0kr isn't patched either way);
- that the dracut module finds unl0kr's agent and units where the upstream
  release installs them.

## What it changes

Listed at the top of `setup.sh`; all reversed by `uninstall.sh`. Updates keep
working: rpm-ostree rebuilds the initramfs with unl0kr on every update, which
makes updates a little slower.

## Licensing and credits

- unl0kr / BuffyBox: GPL-3.0-or-later, by the BuffyBox contributors. This
  repo downloads and builds it, applying the downstream patches credited in
  [patches/README.md](patches/README.md).
- The Plymouth hand-over and GPU wait in `dracut/90unl0kr/` come from
  [erdii/bazzite-playground](https://github.com/erdii/bazzite-playground)
  (Apache-2.0), as marked in each file.
- The scripts in this repo were written with AI assistance (Claude) and
  reviewed by the maintainer. **No AI-generated contributions have been or
  will be sent to postmarketOS**, which forbids them; this project only
  consumes their release.
