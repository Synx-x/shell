#!/usr/bin/env python3
"""
Caelestia agent events hook - tracks Claude Code tool use and permission prompts.
Appends JSONL events to ~/.local/state/caelestia/agents.jsonl for the agent island to consume.
"""

import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

def get_herdr_pane_id():
    """Get the current herdr pane ID from environment."""
    return os.environ.get("HERDR_PANE_ID", "")

def ensure_dir():
    """Ensure the events directory exists."""
    state_dir = Path.home() / ".local" / "state" / "caelestia"
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir / "agents.jsonl"

def compute_edit_delta(tool_input):
    """Extract +/- counts from Edit/Write/MultiEdit tool inputs."""
    added = 0
    removed = 0

    try:
        if isinstance(tool_input, dict):
            # Edit: old_string and new_string
            old_str = tool_input.get("old_string", "")
            new_str = tool_input.get("new_string", "")
            if old_str:
                removed = len(old_str.split("\n"))
            if new_str:
                added = len(new_str.split("\n"))

            # MultiEdit: list of operations
            operations = tool_input.get("operations", [])
            if operations:
                added = removed = 0
                for op in operations:
                    if isinstance(op, dict):
                        old = op.get("old_string", "")
                        new = op.get("new_string", "")
                        if old:
                            removed += len(old.split("\n"))
                        if new:
                            added += len(new.split("\n"))
    except (AttributeError, TypeError, KeyError):
        pass

    return added, removed

def strip_ansi(text):
    """Remove ANSI escape sequences from text."""
    import re
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def handle_hook(hook_data):
    """Process a hook event and append to JSONL file."""
    pane_id = get_herdr_pane_id()
    if not pane_id:
        return 0

    events_file = ensure_dir()
    hook_type = hook_data.get("hook_type", "")

    event = {
        "ts": int(time.time() * 1000),
        "pane": pane_id,
        "session_id": hook_data.get("session_id", ""),
        "event": None,
        "tool": None,
        "file": None,
        "added": 0,
        "removed": 0,
        "text": None,
    }

    if hook_type == "PreToolUse":
        tool_name = hook_data.get("tool_name", "")
        tool_input = hook_data.get("tool_input", {})

        if tool_name in ("Edit", "Write", "MultiEdit"):
            file_path = tool_input.get("file_path", "")
            event["event"] = tool_name
            event["tool"] = tool_name
            event["file"] = os.path.basename(file_path) if file_path else "?"
        elif tool_name == "Bash":
            event["event"] = "Bash"
            event["tool"] = "Bash"
            event["text"] = tool_input.get("command", "")[:100]

        if not event["event"]:
            return 0

    elif hook_type == "PostToolUse":
        tool_name = hook_data.get("tool_name", "")
        tool_input = hook_data.get("tool_input", {})

        if tool_name in ("Edit", "Write", "MultiEdit"):
            file_path = tool_input.get("file_path", "")
            added, removed = compute_edit_delta(tool_input)
            event["event"] = tool_name
            event["tool"] = tool_name
            event["file"] = os.path.basename(file_path) if file_path else "?"
            event["added"] = added
            event["removed"] = removed

        if not event["event"]:
            return 0

    elif hook_type == "Notification":
        # AskUserQuestion or permission prompts show up as notifications
        title = hook_data.get("title", "")
        body = hook_data.get("body", "")

        if "permission" in title.lower() or "allow" in body.lower():
            event["event"] = "Permission"
            event["text"] = strip_ansi(body)[:200]

    elif hook_type == "Stop":
        # Mark agent as done
        event["event"] = "Stop"
        return 0

    else:
        return 0

    try:
        with open(events_file, "a") as f:
            f.write(json.dumps(event, separators=(",", ":")) + "\n")
        return 0
    except Exception as e:
        sys.stderr.write(f"caelestia_agent_events.py error: {e}\n")
        return 0

def main():
    """Main entry point - read hook data from stdin and process it."""
    try:
        hook_data = json.loads(sys.stdin.read())
        sys.exit(handle_hook(hook_data))
    except (json.JSONDecodeError, EOFError, Exception) as e:
        sys.stderr.write(f"caelestia_agent_events.py init error: {e}\n")
        sys.exit(0)

if __name__ == "__main__":
    main()
