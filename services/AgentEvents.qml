pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property map agentTickers: ({})
    property map agentPermissions: ({})
    property int lastEventCount: 0

    function readEventsFile() {
        const eventsPath = `${Paths.home}/.local/state/caelestia/agents.jsonl`;
        const proc = Quickshell.exec(["tail", "-100", eventsPath], result => {
            if (!result.stdout) return;

            const lines = result.stdout.trim().split("\n");
            for (const line of lines) {
                if (!line.trim()) continue;
                try {
                    const event = JSON.parse(line);
                    const paneId = event.pane || "";
                    if (!paneId) continue;

                    if (event.event === "Permission") {
                        root.agentPermissions[paneId] = {
                            timestamp: event.ts,
                            text: event.text || "",
                            choices: parseChoices(event.text || "")
                        };
                        root.agentPermissionsChanged();
                    } else if (["Edit", "Write", "MultiEdit"].includes(event.event)) {
                        if (!root.agentTickers[paneId]) {
                            root.agentTickers[paneId] = [];
                        }
                        root.agentTickers[paneId].push({
                            file: event.file || "",
                            added: event.added || 0,
                            removed: event.removed || 0,
                            timestamp: event.ts
                        });
                        if (root.agentTickers[paneId].length > 10) {
                            root.agentTickers[paneId].shift();
                        }
                        root.agentTickersChanged();
                    }
                } catch (e) {
                    console.warn("Failed to parse event line:", e);
                }
            }
        });
    }

    function parseChoices(text) {
        const choices = [];
        if (text.includes("Allow")) choices.push("Allow");
        if (text.includes("Deny")) choices.push("Deny");
        if (text.includes("Always")) choices.push("Always");
        return choices;
    }

    function getTicker(paneId) {
        const ticker = root.agentTickers[paneId];
        if (!ticker || ticker.length === 0) {
            return "idle";
        }
        let message = "";
        for (const entry of ticker) {
            if (entry.file) {
                const change = entry.added > 0 || entry.removed > 0 ? ` (+${entry.added} -${entry.removed})` : "";
                message = `${entry.file}${change}`;
            }
        }
        return message;
    }

    Timer {
        id: fileWatchTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: root.readEventsFile()
    }

    Component.onCompleted: {
        Quickshell.exec(["mkdir", "-p", `${Paths.home}/.local/state/caelestia`]);
        root.readEventsFile();
    }
}
