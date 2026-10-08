pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Tool events written by the Claude Code hook caelestia_agent_events.py, keyed by herdr pane id.
Singleton {
    id: root

    // paneId -> { ticker, permission }
    property var byPane: ({})

    function tickerFor(paneId: string): string {
        return byPane[paneId]?.ticker ?? "";
    }

    function permissionFor(paneId: string): string {
        return byPane[paneId]?.permission ?? "";
    }

    // working | blocked | idle | "" (no events yet)
    function statusFor(paneId: string): string {
        return byPane[paneId]?.status ?? "";
    }

    function describe(e): string {
        const file = e.file ? e.file.split("/").pop() : "";
        if (["Edit", "Write", "MultiEdit"].includes(e.event))
            return `Edited ${file} +${e.added ?? 0} −${e.removed ?? 0}`;
        if (e.event === "Read")
            return `Reading ${file}`;
        if (e.event === "Bash")
            return `Running ${(e.text || "").split("\n")[0]}`;
        if (e.event === "Stop")
            return "Done";
        if (e.event === "Prompt")
            return "Thinking";
        return e.tool ? `${e.tool} ${file}`.trim() : "";
    }

    function parse(text: string): void {
        const lines = text.trim().split("\n").slice(-200);
        const map = {};
        for (const line of lines) {
            let e;
            try {
                e = JSON.parse(line);
            } catch (err) {
                continue;
            }
            if (!e.pane)
                continue;
            const entry = map[e.pane] ?? (map[e.pane] = {
                    ticker: "",
                    permission: "",
                    status: ""
                });
            if (e.event === "Permission") {
                entry.permission = e.text || "";
                entry.status = "blocked";
            } else if (e.event === "Stop" || e.event === "Waiting") {
                entry.permission = "";
                entry.status = "idle";
            } else {
                const d = describe(e);
                if (d)
                    entry.ticker = d;
                entry.permission = "";
                entry.status = "working";
            }
        }
        byPane = map;
    }

    FileView {
        path: `${Paths.state}/agents.jsonl`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
