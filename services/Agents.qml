pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<Agent> agents
    property int agentCount: agents.length
    readonly property bool hasAgents: agentCount > 0

    function refreshAgents() {
        const proc = Quickshell.exec(["herdr", "agent", "list", "--json"], result => {
            if (result.stdout) {
                try {
                    const data = JSON.parse(result.stdout);
                    const agentList = data.agents || [];
                    const newAgents = [];
                    for (const agent of agentList) {
                        newAgents.push({
                            name: agent.name || "Unknown",
                            paneId: agent.pane_id || "",
                            status: agent.agent_status || "unknown",
                            cwd: agent.cwd || "",
                            workspaceId: agent.workspace_id || ""
                        });
                    }
                    root.agents = newAgents;
                } catch (e) {
                    console.warn("Failed to parse herdr agent list:", e);
                }
            }
        });
    }

    function approve(paneId, choice) {
        const keyMap = {
            "Allow": "Tab",
            "Deny": "d",
            "Always": "a"
        };
        const key = keyMap[choice] || "Tab";
        Quickshell.exec(["herdr", "pane", "send-keys", paneId, key]);
    }

    function focus(paneId) {
        Quickshell.exec(["herdr", "agent", "focus", paneId]);
    }

    function readTail(paneId, lines) {
        return new Promise((resolve) => {
            const proc = Quickshell.exec(["herdr", "pane", "read", paneId, "--source", "recent", "--lines", lines.toString()], result => {
                if (result.stdout) {
                    resolve(result.stdout);
                } else {
                    resolve("");
                }
            });
        });
    }

    component Agent: QtObject {
        property string name: ""
        property string paneId: ""
        property string status: "unknown"
        property string cwd: ""
        property string workspaceId: ""
    }

    Timer {
        id: refreshTimer
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refreshAgents()
    }

    Component.onCompleted: {
        root.refreshAgents();
    }
}
