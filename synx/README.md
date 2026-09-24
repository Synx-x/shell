# Synx-x custom build

The `custom` branch is the latest Caelestia release plus these additions:

- PR #2066: configurable bar position (the bar sits on top).
- PR #1908: battery charge limit toggle in the battery popout.
- VRAM usage on the GPU performance card.
- The dashboard opens from the bottom centre when the bar is on top.
- The bar reads its own token layer, so it can be 80% of normal size.
- A 150% volume toggle in the audio popout, ported from PR #1113.
- Free space on the root filesystem in the storage card.
- USB connect and disconnect toasts, ported from PR #1204.
- Clipboard history and an emoji picker in the launcher, ported from PR #1298.
  Open them with `caelestia shell launcher clipboard` or `caelestia shell launcher emoji`.
- Earlier local edits to network, launcher apps, toggles, audio cycling and Nexus.

## Update

Run `caelestia-update`. It does these steps:

1. It merges the newest upstream release tag into `custom`.
2. It builds and installs the package.
3. It installs `synx/udev/99-caelestia-battery.rules`.
4. It pushes `custom` back to this fork.

When the merge conflicts, the script changes nothing. Resolve the conflict in
`~/.cache/caelestia-build/src` on `custom`, commit, then run it again.

A weekly user timer runs `caelestia-update --check`. It sends a desktop
notification when a new release is out.

`/etc/pacman.conf` lists `caelestia-shell` in `IgnorePkg`, so paru never replaces this build.

## Files outside the package

- `synx/config/monitors/caelestia-bar/` goes to `~/.config/caelestia/monitors/caelestia-bar/`.
  It sets the bar-only scale. Change `innerWidth` in `shell-tokens.json` to resize the bar.
- `synx/udev/99-caelestia-battery.rules` gives the `wheel` group write access to the battery charge limit.
  PR #1908 ships a rule that makes the file writable by all users. This rule replaces it.
- `~/.config/hypr/source/keybinds.conf` binds Super+V to `$cae launcher clipboard`.
- `~/.config/caelestia/shell.json` sets `services.maxVolume` to 1.5.
- `~/user_scripts/audio/active_output_volume.sh` passes `--max-volume 150` to swayosd, which handles the volume keys.
