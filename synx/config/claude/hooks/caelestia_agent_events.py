#!/usr/bin/env python3
"""Claude Code hook: append one JSON line per agent event for the Caelestia agent island.

Reads the hook payload on stdin and writes to $XDG_STATE_HOME/caelestia/agents.jsonl,
keyed by the herdr pane id. Never blocks or fails the agent: always exits 0.
"""
import json
import os
import sys
import time

MAX_BYTES = 512 * 1024
KEEP_LINES = 400


def state_file():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    path = os.path.join(base, "caelestia")
    os.makedirs(path, exist_ok=True)
    return os.path.join(path, "agents.jsonl")


def line_delta(tool, tool_input):
    """Rough +added -removed line counts for an edit."""
    def count(s):
        return len(s.splitlines()) if s else 0

    if tool == "Write":
        return count(tool_input.get("content", "")), 0
    if tool == "Edit":
        return count(tool_input.get("new_string", "")), count(tool_input.get("old_string", ""))
    if tool == "MultiEdit":
        edits = tool_input.get("edits", [])
        return sum(count(e.get("new_string", "")) for e in edits), sum(count(e.get("old_string", "")) for e in edits)
    return 0, 0


def build(data):
    name = data.get("hook_event_name", "")
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    event = {"event": None, "tool": tool or None, "file": None, "added": 0, "removed": 0, "text": None}

    if name == "UserPromptSubmit":
        event["event"] = "Prompt"
    elif name == "PreToolUse":
        event["event"] = "Read" if tool in ("Read", "Grep", "Glob") else tool or "Tool"
        event["file"] = tool_input.get("file_path") or tool_input.get("path")
        if tool == "Bash":
            event["text"] = (tool_input.get("command") or "")[:120]
    elif name == "PostToolUse":
        if tool not in ("Edit", "Write", "MultiEdit"):
            return None
        event["event"] = tool
        event["file"] = tool_input.get("file_path")
        event["added"], event["removed"] = line_delta(tool, tool_input)
    elif name == "Notification":
        message = data.get("message", "")
        # "Claude needs your permission to use Bash" vs "Claude is waiting for your input"
        event["event"] = "Permission" if "permission" in message.lower() else "Waiting"
        event["text"] = message[:300]
    elif name == "Stop":
        event["event"] = "Stop"
    else:
        return None
    return event


def rotate(path):
    try:
        if os.path.getsize(path) <= MAX_BYTES:
            return
        with open(path) as f:
            lines = f.readlines()[-KEEP_LINES:]
        with open(path, "w") as f:
            f.writelines(lines)
    except OSError:
        pass


def main():
    pane = os.environ.get("HERDR_PANE_ID")
    if not pane:
        return
    try:
        data = json.load(sys.stdin)
    except (ValueError, OSError):
        return
    event = build(data)
    if not event:
        return
    event = {"ts": int(time.time() * 1000), "pane": pane, "session_id": data.get("session_id", ""), **event}
    path = state_file()
    with open(path, "a") as f:
        f.write(json.dumps(event, separators=(",", ":")) + "\n")
    rotate(path)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never fail the agent
        sys.stderr.write(f"caelestia_agent_events: {e}\n")
    sys.exit(0)
