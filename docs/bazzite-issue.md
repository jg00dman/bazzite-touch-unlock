<!-- Comment for the existing Bazzite feature request:
     https://github.com/ublue-os/bazzite/issues/5842
     Fill in the [brackets] before posting. -->

I've got this working on a Steam Deck on stock Bazzite, in case it helps move
this forward.

**Setup:** Steam Deck [LCD/OLED], bazzite-deck:stable 45.20261105, kernel 7.2.15.
Upstream unl0kr (BuffyBox 3.6.0) as the systemd password agent in the
initramfs, layered with rpm-ostree plus local initramfs regeneration, so no
custom image: https://github.com/jg00dman/bazzite-touch-unlock

**Results:**
- Boot: Plymouth splash shows, unl0kr takes over the display, LUKS unlocks by
  touch, and boot continues normally.
- Orientation: plain upstream unl0kr draws in the Deck panel's native portrait
  orientation (touch still lines up). Correct orientation needed downstream
  patches by erdii (https://github.com/erdii/bazzite-playground), which also
  provides the Plymouth hand-over and an amdgpu wait that made it reliable.
- An external monitor connected stops the keyboard appearing; fine undocked.
- Removing Plymouth and masking the other password agents gave a blank boot
  with no prompt. Keeping Plymouth and borrowing the display works.

**Related work:** jaredbartimus maintains Fedora 44 packaging of unl0kr aimed
at the ROG Ally X (https://github.com/jaredbartimus/buffybox-unl0kr-fedora),
and erdii has a full Bazzite Deck image with it. So three people have
independently needed this.

**Suggestion:** an opt-in `ujust setup-luks-touch-unlock`, alongside the
existing `ujust setup-luks-tpm-unlock`, would make encryption practical on
handhelds. That matters because TPM-only unlock is discouraged on the Deck's
Zen 2 chip (faulTPM), and Gaming Mode auto-login means a stolen Deck with TPM
unlock is fully usable. The main per-device work is display rotation and
touch drivers.

Happy to test on the Deck. Disclosure: my repo's scripts were written with AI
assistance and tested by me; unl0kr and erdii's patches are their authors' work.
