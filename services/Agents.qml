pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// AI coding agents running in herdr panes. Input only ever goes to a herdr pane id.
Singleton {
    id: root

    // [{ paneId, name, status, cwd }]
    property var agents: []
    readonly property int count: agents.length
    readonly property int workingCount: agents.filter(a => a.status === "working").length
    readonly property var blocked: agents.filter(a => a.status === "blocked")

    property var lastStatus: ({})

    signal agentBlocked(string paneId)
    signal agentFinished(string paneId)

    // Claude Code permission dialog: 1 = Yes, 2 = Yes and don't ask again, Esc = No
    function approve(paneId: string, choice: string): void {
        const key = choice === "Always" ? "2" : choice === "Deny" ? "esc" : "1";
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/herdr", "pane", "send-keys", paneId, key]);
    }

    function answer(paneId: string, index: int): void {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/herdr", "pane", "send-keys", paneId, String(index + 1)]);
    }

    // Bring the agent's herdr workspace and tab to the front
    function focus(paneId: string): void {
        const a = agents.find(x => x.paneId === paneId);
        if (!a)
            return;
        const herdr = Quickshell.env("HOME") + "/.local/bin/herdr";
        Quickshell.execDetached(["sh", "-c", `"${herdr}" workspace focus "$1" && "${herdr}" tab focus "$2"`, "sh", a.workspaceId, a.tabId]);
    }

    function parse(text: string): void {
        let panes;
        try {
            panes = JSON.parse(text).result?.panes ?? [];
        } catch (e) {
            return;
        }

        // A pane is an agent when herdr knows its agent session; herdr's own status is
        // often "unknown", so fall back to the Claude hook's events.
        const next = panes.filter(p => p.agent_session).map(p => {
            const herdrStatus = p.agent_status && p.agent_status !== "unknown" ? p.agent_status : "";
            const cwd = p.foreground_cwd || p.cwd || "";
            return {
                paneId: p.pane_id,
                name: p.terminal_title_stripped || cwd.split("/").pop() || p.pane_id,
                status: herdrStatus || AgentEvents.statusFor(p.pane_id) || "idle",
                cwd: cwd,
                tabId: p.tab_id,
                workspaceId: p.workspace_id
            };
        });

        const prev = lastStatus;
        const seen = {};
        for (const a of next) {
            seen[a.paneId] = a.status;
            if (a.status === "blocked" && prev[a.paneId] !== "blocked")
                agentBlocked(a.paneId);
            else if (a.status === "idle" && prev[a.paneId] === "working")
                agentFinished(a.paneId);
        }
        lastStatus = seen;
        agents = next;
    }

    Process {
        id: listProc

        command: [Quickshell.env("HOME") + "/.local/bin/herdr", "pane", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: listProc.running = true
    }
}
