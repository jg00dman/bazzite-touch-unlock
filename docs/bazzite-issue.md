<!-- Draft for a GitHub issue on ublue-os/bazzite. Fill in the [brackets]
     after testing on hardware, and check their contribution guidelines first. -->

**Title:** LUKS unlock needs a keyboard on handhelds — on-screen unlock via unl0kr

### Problem

Bazzite supports installing with full disk encryption, but on handhelds the
boot passphrase prompt (Plymouth) can only be used with a physical keyboard.
On a Steam Deck that means carrying a USB keyboard to boot your own device.
The remaining option, `ujust setup-luks-tpm-unlock`, warns against use on
Zen2/Zen3 because of faulTPM, and the Deck is Zen2; with Gaming Mode
auto-login, TPM-only unlock also leaves a stolen device fully usable.

So portable devices, the ones most likely to be lost or stolen, have no
practical encryption option.

### Proposal

Offer an opt-in on-screen unlock screen using
[unl0kr](https://gitlab.postmarketos.org/postmarketOS/buffybox) (postmarketOS
BuffyBox, GPL-3.0+), which already ships a systemd password agent and is
used this way by NixOS (`boot.initrd.unl0kr`) and Arch (`sd-unl0kr`).

For example a `ujust setup-luks-touch-unlock` command, matching the existing
TPM one, which layers unl0kr and a dracut module and disables Plymouth.

### Proof of concept

[link to repo] packages upstream unl0kr with a dracut module and
setup/uninstall scripts for rpm-ostree. It optionally carries erdii's
downstream orientation patches for the Deck's sideways panel.

Tested on: [device, Bazzite version, image]
- Touch input: [works / doesn't]
- Right trackpad as pointer (lizard mode): [ ]
- Orientation: [portrait / landscape; usable as-is?]
- Updates still boot: [ ]

[photo or video of unlocking]

### Notes

- Trade-off: no boot splash while unl0kr is enabled, hence opt-in.
- Per-device questions are mainly rotation and touch drivers.
- Disclosure: the PoC scripts were written with AI assistance and tested by
  me. Nothing has been submitted to postmarketOS, whose policy forbids AI
  contributions; the proposal only uses their released code.
