pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// Top 5 processes by CPU. Polls only while a card holds a ref.
Singleton {
    id: root

    property int refCount: 0

    // [{ pid, cpu, mem, name, protected }]
    property var processes: []

    // Never offer to kill the shell or the compositor
    readonly property var protectedNames: ["qs", "quickshell", "Hyprland", "systemd"]

    function kill(pid: int): void {
        Quickshell.execDetached(["kill", "-TERM", String(pid)]);
    }

    Process {
        id: psProc

        command: ["ps", "-eo", "pid,pcpu,pmem,comm", "--sort=-pcpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const p = line.trim().split(/\s+/);
                    if (p.length < 4 || p[3] === "ps")
                        continue;
                    const name = p.slice(3).join(" ");
                    out.push({
                        pid: parseInt(p[0]),
                        cpu: parseFloat(p[1]),
                        mem: parseFloat(p[2]),
                        name: name,
                        protected: root.protectedNames.includes(name)
                    });
                    if (out.length === 5)
                        break;
                }
                root.processes = out;
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: psProc.running = true
    }
}
