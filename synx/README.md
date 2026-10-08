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
| `shell.json` | `~/.config/caelestia/shell.json` | Bar on the bottom with the dashboard on top, 150% volume cap, Celsius. Add your own `weatherLocation`. |
| `monitors/caelestia-bar/` | `~/.config/caelestia/monitors/caelestia-bar/` | Bar-only scale. Change `innerWidth` in `shell-tokens.json` to resize the bar. |
| `hypr/` | `~/.config/hypr/` | Full Hyprland config: keybinds (Super+V opens `$cae launcher clipboard`), window rules, monitors, input, autostart, animations. |
| `hypr/source/appearance.conf` | `~/.config/hypr/source/appearance.conf` | Window opacity: 90% focused, 75% unfocused. |
| `scripts/hypr_blur_opacity_shadow_toggle.sh` | `~/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh` | Super+Alt+. effects toggle, restoring 90%/75%. |
| `scripts/active_output_volume.sh` | `~/user_scripts/audio/active_output_volume.sh` | Volume keys through swayosd, with `--max-volume 150`. |
| `systemd/caelestia-release-check.*` | `~/.config/systemd/user/` | Weekly `caelestia-update --check`. Run `systemctl --user enable --now caelestia-release-check.timer`. |
| `systemd/caelestia-shell.service`, `bin/caelestia-hotplug-watch`, `systemd/caelestia-hotplug.service` | `~/.config/systemd/user/`, `~/.local/bin/` | Respawns the shell and rebuilds its windows after monitor hotplug. The Hyprland autostart starts both services. |
| `bin/caelestia-watchdog`, `systemd/caelestia-watchdog.*` | `~/.local/bin/`, `~/.config/systemd/user/` | Restarts a shell whose IPC event loop stops responding. Run `systemctl --user enable --now caelestia-watchdog.timer`. |
| `bin/audio-dedupe-sinks`, `systemd/audio-dedupe-sinks.service` | `~/.local/bin/`, `~/.config/systemd/user/` | Restarts WirePlumber when HDMI reconnects leave duplicate sinks. Run `systemctl --user enable --now audio-dedupe-sinks.service`. |
| `earlyoom/earlyoom` | `/etc/default/earlyoom` | Kills compiler jobs first under memory pressure. |
| `earlyoom/earlyoom-churn-*`, `earlyoom/churn.conf` | `/usr/local/bin/` (scripts), `/etc/systemd/system/` (units), `/etc/systemd/system/earlyoom.service.d/churn.conf` | Churn breaker. A process killed 3 times in 60 s, such as a respawning `steamwebhelper`, goes on earlyoom's ignore list for 15 min. Run `sudo systemctl daemon-reload && sudo systemctl restart earlyoom && sudo systemctl enable --now earlyoom-churn.path earlyoom-churn.timer`. |
| `pacman/ignorepkg.conf` | `/etc/pacman.conf`, `[options]` section | Stops paru replacing this build. |
| `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | Ctrl+V runs `kitty-smart-paste`. |
| `bin/kitty-smart-paste` | `~/.local/bin/kitty-smart-paste` | Passes Ctrl+V through for images, pastes text directly. |
| `bin/computer-use-linux-install` | Run it, do not copy it | Builds the [computer-use-linux fork](https://github.com/Synx-x/computer-use-linux) on branch `feat/grim-capture-backend` and installs it to `~/.local/bin/computer-use-linux`. The binary stays out of this repo. Register it after with `claude mcp add --scope user computer-use-linux -- computer-use-linux mcp`. |
| `claude/hooks/caelestia_agent_events.py` | `~/.claude/hooks/caelestia_agent_events.py` | Hook script for agent island. Tracks Claude Code tool use and permission prompts, appends JSONL events to `~/.local/state/caelestia/agents.jsonl`. Register in `~/.claude/settings.json` with the snippet below. |
| `gaming-mode/gaming-mode.sh` | `~/.claude/scripts/gaming-mode.sh` | Engine behind the bar's game mode button. Needs its sudoers rule, `~/.claude/state/gaming-mode.sudoers`, in `/etc/sudoers.d/zz-gaming-mode`. |
| `gaming-mode/keep.txt` | `~/.config/gaming-mode/keep.txt` | Processes the game mode sweep never kills, one command-line substring per line. |

`hypr/scheme/current.conf` is not copied. Caelestia regenerates it from the wallpaper.

`caelestia-update` installs `synx/udev/99-caelestia-battery.rules` to `/etc/udev/rules.d/`.
That rule gives the `wheel` group write access to the battery charge limit.
PR #1908 ships a rule that makes the file writable by all users. This rule replaces it.

## Agent Island Hook Registration

To enable the agent island in Caelestia, register the hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "pre_tool_use": "~/.claude/hooks/caelestia_agent_events.py",
    "post_tool_use": "~/.claude/hooks/caelestia_agent_events.py",
    "on_notification": "~/.claude/hooks/caelestia_agent_events.py",
    "on_stop": "~/.claude/hooks/caelestia_agent_events.py"
  }
}
```

The hook writes events in real-time to `~/.local/state/caelestia/agents.jsonl` (JSONL format, one event per line).
Each event captures tool use (Edit/Write/MultiEdit), file paths, line counts, and permission prompts.
