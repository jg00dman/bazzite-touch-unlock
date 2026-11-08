# bazzite-touch-unlock

Unlock a LUKS-encrypted Bazzite handheld (e.g. Steam Deck) **without a USB
keyboard**: the boot passphrase screen gets an on-screen keyboard you use by
touch.

- **Works on stock Bazzite.** No custom image or rebase: one small package is
  layered onto your normal Bazzite, and `uninstall.sh` removes it again. You
  keep getting Bazzite's normal updates.
- **Uses existing open source.** The on-screen keyboard is
  [unl0kr](https://gitlab.nura.eco/postmarketOS/buffybox) from BuffyBox
  (postmarketOS, now Nura). For the Deck's sideways screen this repo applies
  four downstream patches by erdii (see [patches/](patches/README.md)); they
  are not submitted upstream.

> **Status: working on a Steam Deck** (bazzite-deck:stable 45.20261105,
> kernel 7.2.15, unl0kr 3.6.0 with the patches): boots with the splash and
> unlocks by touch in the correct orientation. Not yet tested across a Bazzite
> update or on other handhelds. Please report results in an issue.

## Before you start

You need:

- Bazzite installed with disk encryption (LUKS), on a handheld with a
  touchscreen;
- a USB keyboard for the first boot, in case something goes wrong;
- the Deck **undocked, with no external monitor**: with one connected, the
  keyboard currently doesn't appear;
- your user's sudo password (run `passwd` in Konsole if you've never set one).

All commands are run in Desktop Mode, in Konsole.

## 1. Test it (installs nothing)

Quit Steam first (it stops the trackpad acting as a mouse), then:

```
git clone https://github.com/jg00dman/bazzite-touch-unlock ~/bazzite-touch-unlock && ~/bazzite-touch-unlock/quick-test.sh
```

This downloads the build for your Bazzite version and opens the unlock screen
on a spare console. Your desktop's keyboard and mouse stop working while it's
open: type anything **on the on-screen keyboard by touch** and press its
Enter key to return, or wait two minutes and it closes by itself.

If the keyboard doesn't appear, don't install. Open an issue instead.

## 2. Install

```
cd ~/bazzite-touch-unlock && sudo ./setup.sh
```

Setup pins your current system as a fallback, layers the package and turns on
local boot-image rebuilding. Then reboot. After the splash appears, the
on-screen keyboard should show within about 15 seconds.

## 3. Pin the working system

Once you've unlocked by touch:

```
sudo ostree admin pin 0
```

This keeps a keyboard-free system in the boot menu permanently, whatever
future updates do.

## If the boot goes wrong

1. Plug in the USB keyboard. If the on-screen keyboard is there but touch
   isn't working, type your passphrase on the USB keyboard instead.
2. Otherwise restart and tap **Esc** as the Steam Deck logo disappears to get
   the boot menu, choose the **second** entry, and unlock as before.
3. Make that working system the default again: `sudo rpm-ostree rollback`
4. Optionally remove everything: `sudo ./uninstall.sh`, then reboot.

## Updates

Nothing needs re-applying after normal updates: the package stays layered and
Bazzite rebuilds the boot image with the on-screen keyboard included each
time. Updates take a few minutes longer because of that rebuild.

- **Bazzite Deck images don't update automatically.** Update when it suits
  you, from Gaming Mode (Steam menu, Settings, System, Check for updates) or
  with `ujust update` in Konsole. Desktop Bazzite images update automatically
  and apply on the next reboot.
- **Before rebooting into an update, run `./status.sh`.** It checks the
  staged update kept the package and will rebuild the boot image. If it
  says it would not keep touch unlock, don't reboot away from a keyboard.
- **Ideally update at home**, where your USB keyboard is, and reboot straight
  after, undocked, to check the touch unlock appears. Run `./status.sh` again
  after the reboot to confirm.
- **When it works,** pin the new system (`sudo ostree admin pin 0`) and unpin
  older ones you no longer need. `rpm-ostree status` lists them;
  `sudo ostree admin pin --unpin N` unpins entry N.
- **If an update breaks the unlock,** boot the pinned entry (see above) and
  open an issue.

### When Bazzite moves to a new Fedora version

Each build is made for one Fedora version (Bazzite 45 is Fedora 45). When
Bazzite moves to the next one, the old package may stop the update from
installing, or `./status.sh` will warn about a mismatch. Then get a matching
build and re-run setup, which replaces the old package:

```
cd ~/bazzite-touch-unlock && git pull && ./quick-test.sh && sudo ./setup.sh
```

If no build exists yet for the new version, `./build.sh` makes one locally.

## Other options

- **Settings:** put overrides in `/etc/unl0kr.conf.d/` (defaults in
  `conf/50-handheld.conf`), then `sudo ./setup.sh --regenerate` and reboot.
- **Build it yourself:** `./build.sh` builds in a Fedora container matching
  your Bazzite and writes the package to `dist/`; then `sudo ./test-on-vt.sh`
  tests it. `PATCHES=0` builds plain upstream unl0kr (portrait screen,
  trackpad axes swapped, touch fine).
- **A second way in:** a FIDO2 security key can unlock the disk with a touch
  (`systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=no`).
  Keep your passphrase too.

## How it works

At boot, `systemd-cryptsetup` asks for your passphrase through systemd's
[password agent](https://systemd.io/PASSWORD_AGENTS/) mechanism. Normally
Plymouth answers, with no on-screen keyboard. This repo:

1. builds unl0kr and its systemd password agent into an RPM;
2. adds a dracut module that puts unl0kr, the touchscreen, GPU and Deck
   controller drivers, and handheld defaults into the boot image;
3. keeps Plymouth for the splash but stops it asking; unl0kr waits for the
   Deck's GPU driver, borrows the display while asking, then hands it back
   (approach from erdii).

`setup.sh` lists what it changes at the top; `uninstall.sh` reverses it.

## Known issues

- With an external monitor connected, the keyboard doesn't appear.
- Untested: whether the d-pad navigates the keyboard. Touch is the supported control.
- Only tested on one Steam Deck so far.

## Licensing and credits

- unl0kr / BuffyBox: GPL-3.0-or-later, by the BuffyBox contributors. This
  repo downloads and builds it, applying the downstream patches credited in
  [patches/README.md](patches/README.md).
- The Plymouth hand-over and GPU wait in `dracut/90unl0kr/` come from
  [erdii/bazzite-playground](https://github.com/erdii/bazzite-playground)
  (Apache-2.0), as marked in each file.
- The Fedora packaging approach follows
  [jaredbartimus/buffybox-unl0kr-fedora](https://github.com/jaredbartimus/buffybox-unl0kr-fedora).
- The scripts in this repo were written with AI assistance (Claude) and
  reviewed by the maintainer. **No AI-generated contributions have been or
  will be sent to postmarketOS/Nura**, which forbids them; this project only
  consumes their release.
