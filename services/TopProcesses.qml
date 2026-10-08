pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// Track top 5 processes by CPU usage
Singleton {
    id: root

    // ListModel with pid, name, cpu, memory fields
    property var processes: ListModel {}

    readonly property var blacklist: ["qs", "quickshell", "hyprland"]

    Process {
        id: psProc

        command: ["bash", "-c", "ps aux --sort=-%cpu | awk 'NR>1 {print $2, $3, $4, $11}' | head -20"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                processPsLine(line);
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: true
        repeat: true

        onTriggered: {
            root.processes.clear();
            psProc.running = true;
        }
    }

    function processPsLine(line: string): void {
        const parts = line.trim().split(/\s+/);
        if (parts.length >= 4) {
            const pid = parseInt(parts[0]);
            const cpu = parseFloat(parts[1]);
            const mem = parseFloat(parts[2]);
            const name = parts[3];

            // Filter out blacklisted processes
            if (!blacklist.some(b => name.toLowerCase().includes(b))) {
                if (root.processes.count < 5 && cpu > 0.1) {
                    root.processes.append({ pid, cpu, mem, name });
                }
            }
        }
    }

    function killProcess(pid: number): boolean {
        const proc = Process.spawn(["kill", "-15", String(pid)]);
        return proc.waitForFinished(1000);
    }

    Component.onCompleted: {
        psProc.running = true;
    }
}
