# Downstream patches

Applied to upstream BuffyBox 3.6.0 (and its bundled LVGL) by
`scripts/container-build.sh`. Build without them with `PATCHES=0 ./build.sh`.

| Patch | What it fixes |
|---|---|
| 0001 | The agent's path unit re-triggering on leftover response sockets (restart loop) |
| 0002 | Rotates the UI to the panel's orientation (the Deck panel is mounted sideways) |
| 0003 | Adds software rotation to LVGL's DRM display driver, which 0002 needs |
| 0004 | Rotates trackpad/mouse motion to match; treats combined keyboard+touchpad devices as keyboards |

These are **downstream only and are not submitted upstream** to BuffyBox
(postmarketOS/Nura) or LVGL.

Source: [erdii/bazzite-playground](https://github.com/erdii/bazzite-playground)
`unl0kr/patches/` at commit `3a42dbb`, by erdii, copied unmodified. That
repository is Apache-2.0; the patches modify GPL-3.0-or-later (BuffyBox) and
MIT (LVGL) code and are distributed here under GPL-3.0-or-later, with which
Apache-2.0 is compatible. 0001 matches the fix in
[jaredbartimus/buffybox-unl0kr-fedora](https://github.com/jaredbartimus/buffybox-unl0kr-fedora).
