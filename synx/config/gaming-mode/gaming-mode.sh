#!/bin/bash
# gaming-mode state-tracking helper. Records what it actually stopped so `undo`
# restarts exactly that set, persisted across sessions/reboots.
#
#   gaming-mode.sh on            stop active managed services + docker, record state
#   gaming-mode.sh kill-firefox  kill firefox, record it in state
#   gaming-mode.sh reclaim       free RAM: /tmp, Hyprland log, Caelestia restart, zram push
#   gaming-mode.sh undo          restart everything recorded, archive the state
#   gaming-mode.sh status        show current tracked state
set -u
STATE_DIR=/home/pc/.claude/state
STATE="$STATE_DIR/gaming-mode.state.json"
HIST="$STATE_DIR/gaming-mode.history.jsonl"
GUARD=/home/pc/.claude/scripts/dota-performance-guard.sh
GUARD_UNIT=dota-performance-guard.service
mkdir -p "$STATE_DIR"

SERVICES="bonsai-server forge f5-tts-server dusky-voice llama-ornith ornith-thinkoff jcodemunch-bridge jcodemunch-watch \
llm-gateway hermes-gateway agentos-api agentos-worker cron-workflow-engine agent-session-tailer \
brief-voice-delivery replay-browser openclaw-tts-bridge dusky-kokoro"
# Sunshine remains managed independently: stopping/restarting its Wayland
# screencopy path around GPU/display changes can crash Hyprland/Mesa.
# These are safe to drain in the background and have historically needed
# 10-25 seconds each to finish. None owns GPU memory or the game launch path.
SLOW_STOP_SERVICES="jcodemunch-watch cron-workflow-engine agent-session-tailer"
# Remaining system workloads which are unnecessary while gaming. They are
# recorded and restored exactly like user services.
SYSTEM_SERVICES="ollama waydroid-container containerd"

# --- Nits: units found enabled-but-down during the 2026-08-23 audit. Kept as a
# separate group so the primary lists stay readable and so this set can be
# dropped without touching them. The "on" branch only records units that are
# ACTUALLY active, so dormant or oneshot entries here cost nothing and undo
# never starts something that was already off.
#   hypridle          - stopping it prevents an idle blank/lock mid-game
#   hyprpolkitagent   - was crashlooping (start-limit-hit, 2026-08-18)
#   cron-catchup      - oneshot; listed for completeness, stop is a no-op
#   remainder         - background bridges/dashboards with no role while gaming
EXTRA_SERVICES="hypridle hyprpolkitagent cron-catchup fumon battery_notify \
claude-codex-proxy cli-inference-bridge openclaw-ops-dashboard"
# Both are oneshots, so stopping them is a no-op. Listed so the audit set is
# complete in one place rather than split across the script and a doc.
EXTRA_SYSTEM_SERVICES="shadow waydroid-fix-route"

# ASUS EC power limits can remain latched at 5 W even after Linux requests the
# performance governor.  Dota then runs at ~400 MHz despite cool temperatures.
# Reapply sane gaming limits and cycle the platform profile so the EC consumes
# them.  The limits are ceilings, so they do not prevent normal idle downclocking.
apply_asus_gaming_power() {
  local spl=/sys/devices/platform/asus-nb-wmi/ppt_pl1_spl
  local sppt=/sys/devices/platform/asus-nb-wmi/ppt_pl2_sppt

  if [ -w "$spl" ] || sudo -n test -w "$spl" 2>/dev/null; then
    printf '%s\n' 45 | sudo -n tee "$spl" >/dev/null || return 1
    printf '%s\n' 60 | sudo -n tee "$sppt" >/dev/null || return 1
  else
    return 0
  fi

  if command -v asusctl >/dev/null 2>&1; then
    asusctl profile set Quiet >/dev/null 2>&1 || return 1
    sleep 1
    asusctl profile set Performance >/dev/null 2>&1 || return 1
  fi
}

apply_dota_focus_policy() {
  local cfg=/home/pc/.local/share/Steam/userdata/970601775/570/local/cfg/machine_convars.vcfg

  [ -f "$cfg" ] || return 0
  sed -i -E 's/("engine_no_focus_sleep"[[:space:]]+")[^"]+(".*)/\10\2/' "$cfg"
}

start_dota_performance_guard() {
  [ -x "$GUARD" ] || return 0
  systemctl --user stop "$GUARD_UNIT" >/dev/null 2>&1 || true
  systemctl --user reset-failed "$GUARD_UNIT" >/dev/null 2>&1 || true
  systemd-run --user --quiet --collect --unit="$GUARD_UNIT" "$GUARD"
}

avail_mib(){ awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo; }

# /tmp is tmpfs, so every file in it costs RAM. Remove top-level entries that
# pc owns, that are older than an hour, and that no process holds open.
# Keep hidden entries, sockets and claude-* dirs: live sessions use those.
clean_tmp() {
  local open f
  open=$(ls -l /proc/[0-9]*/cwd /proc/[0-9]*/fd/* 2>/dev/null \
    | grep -o ' /tmp/[^/ ]*' | sed 's/^ //'
    cat /proc/[0-9]*/maps 2>/dev/null | grep -o '/tmp/[^/ ]*')
  open=$(printf '%s\n' "$open" | sort -u)
  find /tmp -mindepth 1 -maxdepth 1 -user "$(id -u)" -mmin +60 \
    ! -name '.*' ! -name 'claude-*' ! -type s -print0 |
  while IFS= read -r -d '' f; do
    case "$f" in /tmp/?*) ;; *) continue ;; esac
    printf '%s\n' "$open" | grep -qxF -- "$f" && continue
    rm -rf -- "$f"
  done
}

# Hyprland writes its whole-uptime log to /run/user, which is also tmpfs.
# It keeps the file open, so truncate it instead of deleting it. Only
# truncate past 50 MiB: a fresh log holds the startup record, which is the
# evidence for monitor and GPU faults.
truncate_hypr_log() {
  local f
  for f in /run/user/"$(id -u)"/hypr/*/hyprland.log; do
    [ -f "$f" ] || continue
    [ "$(stat -c %s "$f")" -gt 52428800 ] && : > "$f"
  done
}

# Push the coldest anonymous pages of every app into zram. Pages compress
# about 5:1 and come back on first touch. swappiness=200 skips file cache,
# which already counts as available. Needs kernel 6.8 or later.
# Never run swapoff here: zram lives in RAM, so swapoff decompresses it
# and lowers available memory.
zram_push() {
  local cg=/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/app.slice
  [ -w "$cg/memory.reclaim" ] || return 0
  echo "1G swappiness=200" > "$cg/memory.reclaim" 2>/dev/null || true
}

reclaim_memory() {
  local before after
  before=$(avail_mib)
  clean_tmp
  truncate_hypr_log
  # Caelestia grows over a long uptime. A restart resets it, and the bar
  # blinks for a few seconds.
  if systemctl --user is-active --quiet caelestia-shell.service; then
    systemctl --user restart caelestia-shell.service
    sleep 5
  fi
  zram_push
  after=$(avail_mib)
  echo "memory reclaim: available ${before} -> ${after} MiB"
  hist reclaim "avail_mib=${before}->${after}"
}

now(){ date +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo unknown; }
hist(){ printf '{"action":"%s","ts":"%s","detail":"%s"}\n' "$1" "$(now)" "$2" >> "$HIST"; }

case "${1:-status}" in
on)
  stopped_svcs=""; fast_svcs=""; slow_svcs=""
  for s in $SERVICES $EXTRA_SERVICES; do
    if systemctl --user is-active --quiet "$s" 2>/dev/null; then
      stopped_svcs="$stopped_svcs $s"
      case " $SLOW_STOP_SERVICES " in
        *" $s "*) slow_svcs="$slow_svcs $s" ;;
        *) fast_svcs="$fast_svcs $s" ;;
      esac
    fi
  done
  # Stop the set in one systemd transaction. The old serial loop made a
  # Waybar click appear dead for 30+ seconds while each unit stopped in turn.
  # A single transaction lets independent services shut down concurrently.
  [ -z "$fast_svcs" ] || systemctl --user stop $fast_svcs 2>/dev/null
  [ -z "$slow_svcs" ] || systemctl --user stop --no-block $slow_svcs 2>/dev/null
  # docker: record running containers BEFORE stopping, and whether daemon was up
  docker_was=false; containers=""
  if systemctl is-active --quiet docker 2>/dev/null; then
    docker_was=true
    containers=$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')
    [ -n "$containers" ] && docker stop -t 2 $(docker ps -q) >/dev/null 2>&1
    for u in docker.socket docker; do sudo -n systemctl stop "$u" 2>/dev/null; done
  fi
  system_svcs=""
  for s in $SYSTEM_SERVICES $EXTRA_SYSTEM_SERVICES; do
    if sudo -n systemctl is-active --quiet "$s" 2>/dev/null; then
      system_svcs="$system_svcs $s"
    fi
  done
  # One unit per call: the sudoers rule allows exact commands only.
  for s in $system_svcs; do sudo -n systemctl stop "$s" 2>/dev/null; done
  # merge firefox flag from any prior state in this same session
  # CPU governor: record what it was, then pin performance. intel_pstate idles
  # cores hard on "powersave", which costs frames in CPU-bound games.
  gov_was=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "")
  if [ -n "$gov_was" ] && [ "$gov_was" != performance ]; then
    if command -v cpupower >/dev/null 2>&1; then sudo -n cpupower frequency-set -g performance >/dev/null 2>&1
    else for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo -n tee "$g" >/dev/null; done; fi
  else
    gov_was=""   # already performance, or unreadable: nothing to restore
  fi
  if apply_asus_gaming_power; then
    echo "ASUS gaming power: 45W sustained / 60W burst; EC profile reloaded"
  else
    echo "warning: ASUS gaming power recovery failed" >&2
  fi
  if apply_dota_focus_policy; then
    echo "Dota background rendering: full speed (engine_no_focus_sleep=0)"
  else
    echo "warning: Dota background rendering policy failed" >&2
  fi
  python3 - "$STATE" "$(now)" "$docker_was" "$stopped_svcs" "$containers" "$gov_was" "$system_svcs" <<'PY'
import json,os,sys
state,ts,dock,svcs,conts,gov,system_svcs=sys.argv[1:8]

# MERGE with any existing state rather than overwriting it. Running "on" twice
# used to clobber the restore data: the second pass finds nothing left running,
# records an empty service list and an empty governor, and undo becomes a no-op
# while everything stays stopped.
prev = {}
if os.path.exists(state):
    try: prev = json.load(open(state))
    except Exception: prev = {}

def union(a, b):
    out = list(a)
    for x in b:
        if x not in out: out.append(x)
    return out

# Sunshine owns its own lifecycle because its capture backend must be
# coordinated with the compositor transition. Never inherit an old record of
# it into gaming-mode state; otherwise a later RMB undo can restart Sunshine
# as an unmanaged side effect.
def managed(a):
    return [x for x in a if x != "sunshine"]

json.dump({
    "ts": prev.get("ts", ts),                      # first-stop time is the useful one
    "ts_last": ts,
    "services":   union(managed(prev.get("services", [])), managed(svcs.split())),
    "system_services": union(prev.get("system_services", []), system_svcs.split()),
    "containers": union(prev.get("containers", []), conts.split()),
    "docker_daemon": bool(prev.get("docker_daemon")) or dock == "true",
    "firefox": bool(prev.get("firefox")),           # only kill-firefox sets this
    # Keep the ORIGINAL governor. On a second pass the live value is already
    # "performance", so trusting the new read would lose what to restore to.
    "cpu_governor": prev.get("cpu_governor") or gov,
}, open(state, "w"), indent=2)
PY
  if start_dota_performance_guard; then
    echo "Dota runtime guard: nice -10, CPUs 0-15"
  else
    echo "warning: Dota runtime guard failed to start" >&2
  fi
  hist on "services=$(echo $stopped_svcs|wc -w) docker=$docker_was"
  echo "stopped services:$stopped_svcs"
  echo "stopped system services:$system_svcs"
  echo "docker_was_running=$docker_was containers=[$containers]"
  [ -n "$gov_was" ] && echo "cpu governor: $gov_was -> performance (will restore on undo)"
  echo "state written: $STATE"
  # Core focus of gaming mode is freeing the most resources: strip the
  # runtime down to the minimal GUI items and services actually needed to
  # game. So this also kills live project dev-server stacks (vite, tsx
  # watch, netlify dev, nodemon, etc. — see DEV_STACK_SIGNATURES below),
  # not just stale/idle sessions. Not recorded in gaming-mode state and not
  # touched by undo — a dev server killed this way has no known restart
  # command, unlike the systemd SERVICES list above. Restart it by hand
  # when you're done gaming.
  echo "--- sweeping stale agent sessions and live dev-server stacks ---"
  "$0" sweep --go --dev-stacks
  echo "--- reclaiming memory: /tmp, Hyprland log, Caelestia, zram ---"
  reclaim_memory
  ;;
reclaim)
  reclaim_memory
  ;;
kill-firefox)
  pkill -x firefox 2>/dev/null
  python3 - "$STATE" <<'PY'
import json,os,sys
s=sys.argv[1]
d=json.load(open(s)) if os.path.exists(s) else {"services":[],"containers":[],"docker_daemon":False}
d["firefox"]=True
json.dump(d,open(s,"w"),indent=2)
PY
  hist kill-firefox ""
  echo "firefox killed + recorded"
  ;;
undo)
  [ -f "$STATE" ] || { echo "no state file — nothing to undo"; exit 0; }
  systemctl --user stop "$GUARD_UNIT" >/dev/null 2>&1 || true
  echo "restoring from $STATE ..."
  # All restore logic in python to avoid shell word-splitting on multi-entry lists.
  python3 - "$STATE" <<'PY'
import json,sys,subprocess
d=json.load(open(sys.argv[1]))
def run(cmd): return subprocess.run(cmd,capture_output=True,text=True)
for s in d.get("system_services",[]):
    if run(["sudo","-n","systemctl","start",s]).returncode==0: print(f"system service up: {s}")
    else: print(f"system service FAILED: {s}")
if d.get("docker_daemon"):
    if run(["sudo","-n","systemctl","start","docker"]).returncode==0: print("docker daemon: up")
    for c in d.get("containers",[]):
        if run(["docker","start",c]).returncode==0: print(f"container up: {c}")
        else: print(f"container FAILED: {c}")
for s in d.get("services",[]):
    if run(["systemctl","--user","start",s]).returncode==0: print(f"service up: {s}")
    else: print(f"service FAILED: {s}")
gov=d.get("cpu_governor") or ""
if gov:
    import glob,shutil
    if shutil.which("cpupower"): ok=run(["sudo","-n","cpupower","frequency-set","-g",gov]).returncode==0
    else: ok=all(subprocess.run(["sudo","-n","tee",g],input=gov+"\n",capture_output=True,text=True).returncode==0 for g in glob.glob("/sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor"))
    if ok: print(f"cpu governor restored: {gov}")
    else: print(f"cpu governor FAILED to restore to {gov}; set it by hand")
if d.get("firefox"): print("note: firefox was killed — relaunch manually (it restores its own tabs)")
PY
  # archive state so a second undo is a no-op
  mv "$STATE" "$STATE.done.$(date +%s 2>/dev/null || echo prev)" 2>/dev/null
  hist undo "restored from state"
  echo "undo complete; state archived"
  ;;
status)
  if [ -f "$STATE" ]; then echo "ACTIVE gaming-mode state:"; cat "$STATE"
  else echo "no active gaming-mode state (nothing stopped, or already undone)"; fi
  ;;
sweep)
  # Reclaim RAM from abandoned agent sessions, stale scratchpad dev servers,
  # and (with --dev-stacks) live project dev-server stacks. Dry run by
  # default. Pass --go to actually kill. Deliberately not recorded in state,
  # because killed processes cannot be restored and undo has no job here —
  # this applies to --dev-stacks too: a dev server killed this way is not
  # relaunched by `undo`, since it was never a systemd unit with a known
  # start command. Restart it by hand when you're done gaming.
  shift
  SWEEP_GO=0
  SWEEP_AGE=14400
  SWEEP_DEV_STACKS=0
  while [ $# -gt 0 ]
  do
    case "$1" in
      --go) SWEEP_GO=1 ;;
      --dev-stacks) SWEEP_DEV_STACKS=1 ;;
      --age)
        shift
        SWEEP_AGE=$(( ${1:-4} * 3600 ))
        ;;
      *) echo "usage: gaming-mode.sh sweep [--go] [--age HOURS] [--dev-stacks]" && exit 1 ;;
    esac
    shift
  done
  SWEEP_GO=$SWEEP_GO SWEEP_AGE=$SWEEP_AGE SWEEP_SELF=$$ SWEEP_DEV_STACKS=$SWEEP_DEV_STACKS python3 <<'PY'
import os, signal, subprocess, sys

GO         = os.environ["SWEEP_GO"] == "1"
AGE        = int(os.environ["SWEEP_AGE"])
SELF       = int(os.environ["SWEEP_SELF"])
DEV_STACKS = os.environ["SWEEP_DEV_STACKS"] == "1"

cols = subprocess.run(
    ["ps", "-eo", "pid=,ppid=,etimes=,rss=,comm=,args="],
    capture_output=True, text=True).stdout.splitlines()

procs = {}
for line in cols:
    f = line.split(None, 5)
    if len(f) < 6:
        continue
    pid, ppid, etimes, rss, comm, args = f
    procs[int(pid)] = dict(ppid=int(ppid), etimes=int(etimes),
                           rss=int(rss), comm=comm, args=args)

# Never touch this session. Walk our own ancestry up and protect all of it.
protected = set()
p = SELF
while p in procs and p > 1:
    protected.add(p)
    p = procs[p]["ppid"]

children = {}
for pid, d in procs.items():
    children.setdefault(d["ppid"], []).append(pid)

# Keep list: one case-insensitive substring per line, matched against each
# process's full command line. A match protects that process and everything
# it launched, and the sweep skips any tree that contains one.
KEEP_FILE = os.path.expanduser("~/.config/gaming-mode/keep.txt")
keep = []
try:
    with open(KEEP_FILE) as fh:
        keep = [l.strip().lower() for l in fh if l.strip() and not l.lstrip().startswith("#")]
except FileNotFoundError:
    pass

def kept_self(pid):
    return any(k in procs[pid]["args"].lower() for k in keep)

def is_kept(pid):
    p = pid
    while p in procs and p > 1:
        if kept_self(p):
            return True
        p = procs[p]["ppid"]
    return False

def tree(pid):
    out, stack = [], [pid]
    while stack:
        cur = stack.pop()
        out.append(cur)
        stack.extend(children.get(cur, []))
    return out

SCRATCH = ("/tmp/claude-", "scratchpad", "/.npm/_npx/")

# Command-line signatures of real dev-server tooling, not a bare "dev"/"serve"
# substring match — a project script or a systemd unit could legitimately
# contain either word, and this list is meant to be precise, not broad.
# Confirmed against this machine's own running processes (abacus stack):
# netlify-cli, vite, tsx watch, plus the common framework dev servers.
DEV_STACK_SIGNATURES = (
    "netlify-cli", "vite/bin/vite.js", "vite.js", "tsx/dist/cli.mjs watch",
    "tsx watch", "webpack-dev-server", "next dev", "nodemon",
    "ts-node-dev", "wrangler dev", "remix dev", "astro dev", "ng serve",
)

targets = {}
for pid, d in procs.items():
    if pid in protected:
        continue
    stale_agent = d["etimes"] >= AGE and d["comm"] == "claude"
    stale_dev = (d["etimes"] >= AGE and d["comm"].startswith(("node", "npm"))
                 and any(s in d["args"] for s in SCRATCH))
    # Dev-stack processes are killed regardless of age — the point is
    # freeing resources for gaming now, not reclaiming abandoned ones.
    live_dev_stack = (DEV_STACKS and d["comm"].startswith(("node", "npm", "pnpm", "yarn", "bun"))
                       and any(s in d["args"] for s in DEV_STACK_SIGNATURES))
    if stale_agent or stale_dev:
        targets[pid] = "agent session" if stale_agent else "scratchpad dev server"
    elif live_dev_stack:
        targets[pid] = "dev stack"

# Drop any target whose tree holds a kept process, so killing it spares them.
skipped = [p for p in targets if any(is_kept(t) for t in tree(p) if t in procs)]
for p in skipped:
    del targets[p]
if skipped:
    print("keep list: spared %d tree(s)" % len(skipped))

# A target inside another target's tree dies with its parent. Drop it as a root.
covered = set()
for pid in targets:
    covered.update(t for t in tree(pid) if t != pid)
roots = {p: k for p, k in targets.items() if p not in covered}

if not roots:
    scope = "stale (dev stacks included)" if DEV_STACKS else "older than %dh" % (AGE // 3600)
    print("sweep: nothing %s to reclaim" % scope)
    sys.exit(0)

total = 0
print("%9s  %8s  %6s  KIND" % ("PID", "RSS", "AGE"))
for pid in sorted(roots, key=lambda p: -procs[p]["rss"]):
    kids = [k for k in tree(pid) if k in procs]
    rss = sum(procs[k]["rss"] for k in kids)
    total += rss
    plural = "s" if len(kids) != 1 else ""
    print("%9d  %6.0fM  %5.1fh  %s (%d proc%s)"
          % (pid, rss / 1024, procs[pid]["etimes"] / 3600,
             roots[pid], len(kids), plural))

print("\nreclaimable: %.2f GiB across %d tree(s)" % (total / 1048576, len(roots)))

if not GO:
    print("dry run. re-run with --go to kill.")
    sys.exit(0)

killed = 0
for pid in roots:
    for k in sorted(tree(pid), reverse=True):
        try:
            os.kill(k, signal.SIGTERM)
            killed += 1
        except (ProcessLookupError, PermissionError):
            pass
print("sent SIGTERM to %d process(es)" % killed)
PY
  if [ "$SWEEP_GO" = "1" ]
  then
    sleep 2
    hist sweep "age=$((SWEEP_AGE/3600))h"
    echo "sweep complete"
  fi
  ;;
*) echo "usage: gaming-mode.sh {on|kill-firefox|sweep|undo|status}" && exit 1 ;;
esac
