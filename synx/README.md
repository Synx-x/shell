# Synx-x custom build

The `custom` branch is the latest Caelestia release plus these additions:

- PR #2066: configurable bar position (the bar sits on top).
- PR #1908: battery charge limit toggle in the battery popout.
- VRAM usage on the GPU performance card.
- The dashboard opens from the bottom centre when the bar is on top.
- The bar reads its own token layer, so it can be 76% of normal size (43px tall).
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

Copies of these live in `synx/config/`. Put each one back at its path to rebuild this setup on a new machine.

| Copy in `synx/config/` | Goes to | What it sets |
| --- | --- | --- |
| `shell.json` | `~/.config/caelestia/shell.json` | Bar on the bottom with the dashboard on top, background visualiser on, 150% volume cap, Celsius. Add your own `weatherLocation`. |
| `monitors/caelestia-bar/` | `~/.config/caelestia/monitors/caelestia-bar/` | Bar-only scale. Change `innerWidth` in `shell-tokens.json` to resize the bar. |
| `hypr/` | `~/.config/hypr/` | Full Hyprland config: keybinds (Super+V opens `$cae launcher clipboard`), window rules, monitors, input, autostart, animations. |
| `hypr/source/appearance.conf` | `~/.config/hypr/source/appearance.conf` | Window opacity: 90% focused, 75% unfocused. |
| `scripts/hypr_blur_opacity_shadow_toggle.sh` | `~/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh` | Super+Alt+. effects toggle, restoring 90%/75%. |
| `scripts/active_output_volume.sh` | `~/user_scripts/audio/active_output_volume.sh` | Volume keys through swayosd, with `--max-volume 150`. |
| `systemd/caelestia-release-check.*` | `~/.config/systemd/user/` | Weekly `caelestia-update --check`. Run `systemctl --user enable --now caelestia-release-check.timer`. |
| `pacman/ignorepkg.conf` | `/etc/pacman.conf`, `[options]` section | Stops paru replacing this build. |
| `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | Ctrl+V runs `kitty-smart-paste`. |
| `bin/kitty-smart-paste` | `~/.local/bin/kitty-smart-paste` | Passes Ctrl+V through for images, pastes text directly. |

`hypr/scheme/current.conf` is not copied. Caelestia regenerates it from the wallpaper.

`caelestia-update` installs `synx/udev/99-caelestia-battery.rules` to `/etc/udev/rules.d/`.
That rule gives the `wheel` group write access to the battery charge limit.
PR #1908 ships a rule that makes the file writable by all users. This rule replaces it.
