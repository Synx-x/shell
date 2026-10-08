pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// AI coding agents running in herdr panes. Input only ever goes to a herdr pane id.
Singleton {
    id: root

    readonly property string herdr: Quickshell.env("HOME") + "/.local/bin/herdr"

    // Island on or off, saved in $XDG_STATE_HOME/caelestia/island.json. Off also stops polling herdr.
    property bool enabled: true

    function setEnabled(on: bool): void {
        enabled = on;
        settings.setText(JSON.stringify({
            enabled: on
        }));
    }

    // [{ paneId, sessionId, tabId, workspaceId, name, initials, hue, group, cwd, status, ...AgentEvents state }]
    property var agents: []
    readonly property int count: agents.length
    readonly property var working: agents.filter(a => a.status === "working")
    readonly property var waiting: agents.filter(a => a.status === "blocked" || a.status === "question")

    property var panes: []
    // paneId -> doneAt already announced, so each finish flashes once
    property var lastDone: ({})
    property bool primed

    signal agentFinished(string paneId)

    // Claude Code permission dialog: 1 = Yes, 2 = Yes and don't ask again, Esc = No
    function approve(paneId: string, choice: string): void {
        const key = choice === "Always" ? "2" : choice === "Deny" ? "esc" : "1";
        Quickshell.execDetached([herdr, "pane", "send-keys", paneId, key]);
    }

    // AskUserQuestion: options are numbered from 1
    function answer(paneId: string, index: int): void {
        Quickshell.execDetached([herdr, "pane", "send-keys", paneId, String(index + 1)]);
    }

    function message(paneId: string, text: string): void {
        if (!text.trim())
            return;
        Quickshell.execDetached(["sh", "-c", `"$0" pane send-text "$1" "$2" && "$0" pane send-keys "$1" enter`, herdr, paneId, text]);
    }

    function interrupt(paneId: string): void {
        Quickshell.execDetached([herdr, "pane", "send-keys", paneId, "esc"]);
    }

    // Bring the agent's herdr workspace and tab to the front
    function focus(paneId: string): void {
        const a = agents.find(x => x.paneId === paneId);
        if (a)
            Quickshell.execDetached(["sh", "-c", `"$0" workspace focus "$1" && "$0" tab focus "$2"`, herdr, a.workspaceId, a.tabId]);
    }

    // 75000 -> "1m 15s", 4000000 -> "1h 6m"
    function duration(ms: real): string {
        const s = Math.max(0, Math.floor(ms / 1000));
        if (s < 60)
            return `${s}s`;
        const m = Math.floor(s / 60);
        if (m < 60)
            return `${m}m ${s % 60}s`;
        return `${Math.floor(m / 60)}h ${m % 60}m`;
    }

    function initials(name: string): string {
        const words = name.replace(/[^A-Za-z0-9 ]/g, " ").trim().split(/\s+/).filter(w => w);
        if (words.length === 0)
            return "?";
        return (words.length === 1 ? words[0].slice(0, 2) : words[0][0] + words[1][0]).toUpperCase();
    }

    function hue(id: string): int {
        let h = 0;
        for (let i = 0; i < id.length; i++)
            h = (h * 31 + id.charCodeAt(i)) >>> 0;
        return h % 4;
    }

    // Project name: the folder under ~/dev without a -lanes suffix, else the cwd's own name
    function group(cwd: string): string {
        const parts = cwd.split("/").filter(p => p);
        const dev = parts.indexOf("dev");
        const name = dev >= 0 && parts.length > dev + 1 ? parts[dev + 1] : parts[parts.length - 1] ?? "";
        return name.replace(/-lanes$/, "") || "other";
    }

    function rebuild(): void {
        const next = panes.filter(p => p.agent_session).map(p => {
            const cwd = p.foreground_cwd || p.cwd || "";
            const name = p.terminal_title_stripped || cwd.split("/").pop() || p.pane_id;
            const ev = AgentEvents.get(p.pane_id) ?? {};
            const herdrStatus = p.agent_status && p.agent_status !== "unknown" ? p.agent_status : "";
            return Object.assign({}, ev, {
                paneId: p.pane_id,
                sessionId: p.agent_session?.value ?? "",
                tabId: p.tab_id,
                workspaceId: p.workspace_id,
                name: name,
                initials: initials(name),
                hue: hue(p.pane_id),
                group: group(cwd),
                cwd: cwd,
                status: ev.status || herdrStatus || "idle"
            });
        });

        // A finish is a newer doneAt. Comparing statuses can miss a fast turn whose
        // events land in one file reload. The first build only records what is there.
        const done = {};
        for (const a of next) {
            done[a.paneId] = a.doneAt ?? 0;
            if (primed && (a.doneAt ?? 0) > (lastDone[a.paneId] ?? 0) && a.status === "idle")
                agentFinished(a.paneId);
        }
        lastDone = done;
        primed = panes.length > 0 && Object.keys(AgentEvents.byPane).length > 0;
        agents = next;
    }

    Connections {
        target: AgentEvents

        function onByPaneChanged(): void {
            root.rebuild();
        }
    }

    Process {
        id: listProc

        command: [root.herdr, "pane", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.panes = JSON.parse(text).result?.panes ?? [];
                } catch (e) {
                    return;
                }
                root.rebuild();
            }
        }
    }

    // qs ipc call island toggle | enable | disable | isEnabled | status
    IpcHandler {
        target: "island"

        function toggle(): void {
            root.setEnabled(!root.enabled);
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }

        function isEnabled(): bool {
            return root.enabled;
        }

        function status(): string {
            return `enabled=${root.enabled} panes=${root.panes.length} agents=${root.count} working=${root.working.length} waiting=${root.waiting.length}`;
        }
    }

    FileView {
        id: settings

        path: `${Paths.state}/island.json`
        printErrors: false
        onLoaded: {
            try {
                root.enabled = JSON.parse(text()).enabled !== false;
            } catch (e) {}
        }
    }

    Timer {
        interval: 1500
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: listProc.running = true
    }
}
