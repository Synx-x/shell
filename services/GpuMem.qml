pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services

// VRAM usage. The built-in Gpu service has no memory field.
// NVIDIA reads nvidia-smi. Other GPUs read amdgpu sysfs counters.
// Also tracks per-process VRAM when dGPU is active.
Singleton {
    id: root

    property int refCount: 0

    // Bytes. NaN until the first reading lands.
    readonly property real used: _used
    readonly property real total: _total
    readonly property real percentage: _total > 0 ? _used / _total : NaN

    // Per-process VRAM data from nvidia-smi --query-compute-apps
    property var processesByVram: ListModel {}

    property real _used: NaN
    property real _total: NaN
    property string _sysfsDir: ""

    function format(bytes: real): string {
        if (isNaN(bytes))
            return "...";
        const gib = bytes / (1024 * 1024 * 1024);
        return gib >= 1 ? `${gib.toFixed(1)} GiB` : `${Math.round(bytes / (1024 * 1024))} MiB`;
    }

    Process {
        id: nvidiaProc

        command: ["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n")[0].split(",").map(s => parseFloat(s));
                if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
                    root._used = parts[0] * 1024 * 1024;
                    root._total = parts[1] * 1024 * 1024;
                }
            }
        }
    }

    Process {
        id: nvidiaComputeAppsProc

        command: ["nvidia-smi", "--query-compute-apps=pid,process_name,used_memory", "--format=csv,noheader"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(",").map(s => s.trim());
                if (parts.length >= 3) {
                    const pid = parseInt(parts[0]);
                    const name = parts[1];
                    const memStr = parts[2].replace(" MiB", "").replace(" GiB", "");
                    let bytes = parseFloat(memStr);
                    if (parts[2].includes("GiB")) {
                        bytes *= 1024 * 1024 * 1024;
                    } else {
                        bytes *= 1024 * 1024;
                    }
                    root.processesByVram.append({ pid, name, bytes });
                }
            }
        }
    }

    Process {
        id: sysfsFind

        running: true
        command: ["sh", "-c", "for d in /sys/class/drm/card*/device; do [ -r \"$d/mem_info_vram_used\" ] && echo \"$d\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root._sysfsDir = text.trim()
        }
    }

    FileView {
        id: sysfsUsed

        path: root._sysfsDir ? `${root._sysfsDir}/mem_info_vram_used` : ""
    }

    FileView {
        id: sysfsTotal

        path: root._sysfsDir ? `${root._sysfsDir}/mem_info_vram_total` : ""
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: root.refCount > 0 && Gpu.type !== GpuType.None
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (Gpu.type === GpuType.Nvidia) {
                if (!nvidiaProc.running)
                    nvidiaProc.running = true;
                root.processesByVram.clear();
                if (!nvidiaComputeAppsProc.running)
                    nvidiaComputeAppsProc.running = true;
            } else if (root._sysfsDir) {
                sysfsUsed.reload();
                sysfsTotal.reload();
                root._used = parseFloat(sysfsUsed.text());
                root._total = parseFloat(sysfsTotal.text());
                root.processesByVram.clear();
            }
        }
    }
}
