# Memory guard redesign: nohang with scope protection

Date: 2026-09-29

Status: approved in chat, awaiting spec review.

## Problem

earlyoom picks victims by process name only. On 2026-09-29 a `rustc` build
used up memory.

earlyoom then killed `steamwebhelper` about 68 times in one minute. Steam
respawns it at once, so each kill freed nothing. Each respawn flashed Steam
windows over the screen.

The name-based churn breaker added that day has two flaws. It counts every
repeat kill as churn, so real tab kills in Zen would get ignored.

Each ignored name also pushes earlyoom toward important processes.

## Goal

When memory runs low, the real memory hog dies once. Nothing protected dies,
and no process gets re-killed in a loop.

## Protected and killable

Protection follows the systemd scope where possible, not a name list.

| Group | Match | Treatment |
| --- | --- | --- |
| Games | cgroup `app-Hyprland-steam-.*\.scope` (Steam, gamescope, the game, helpers) | Large negative badness |
| Terminals | realpath `/usr/bin/kitty`, `/usr/bin/zsh`, `/usr/bin/bash`, `/home/pc/.local/share/claude/versions/.*` | Large negative badness |
| Session core | the current earlyoom `--avoid` list (systemd, Hyprland, dbus, pipewire, wireplumber, portals, uwsm) | Large negative badness |
| Killable | builds and tests inside the kitty scope, browser tabs, other apps | Normal badness |

All kitty windows share one scope, `kitty-2915-0.scope`. So terminals are
protected by binary path, and the jobs they start stay killable.

Set `ignore_positive_oom_score_adj = True`. Chromium and Electron raise their
own oom_score_adj by 300. That self-raise made `steamwebhelper` the first
victim.

## Thresholds

Keep today's behaviour. SIGTERM below 10% available memory, SIGKILL below 5%.

Swap is zram, so swap free does not gate the action.

## Respawn handling

`post_kill_exe` runs a small logger after each kill. A root evaluator waits
5 seconds, then checks whether a process with the same name exists again.

Only a respawn counts. Three respawns within 60 seconds protect that name for
15 minutes, through a generated badness rule and a nohang restart.

A killed tab that stays dead never counts. This reuses the churn units from
commit `ea4c621d`, trimmed to the respawn check.

## Switchover

1. Stop and disable `earlyoom`, `earlyoom-churn.path` and `earlyoom-churn.timer`.
2. Install `nohang` from the AUR.
3. Install the config, then enable and start `nohang.service`.
4. Mirror every file into `synx/config/nohang/` with a README row.

## Testing

Run a controlled memory hog, such as `stress-ng --vm`, from a kitty tab while
Steam is open. The test passes when:

- only the hog is killed,
- Steam, the game, kitty and the agent sessions survive,
- the journal shows one kill, not a loop.

A second test kills a respawning process three times. It passes when the name
gets protected and nohang restarts once.

## Rollback

Disable nohang. Re-enable earlyoom and its churn units from
`synx/config/earlyoom/`. The earlyoom config backups stay in `/etc/default/`.

## Open items for the plan

- Confirm which variables `post_kill_exe` receives from the nohang 0.3.0
  source. The config reference documents `$PID` and `$NAME` only for soft
  actions.
- Confirm the swap threshold value that disables swap gating in nohang.
- Pick badness values after checking how nohang combines matching rules.
