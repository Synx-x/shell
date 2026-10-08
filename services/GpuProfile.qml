pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// Detects the current GPU profile (docked = NVIDIA, mobile = Intel)
// Also tracks dGPU power state via /sys/bus/pci/devices/*/power/runtime_status
Singleton {
    id: root

    property string profile: "unknown" // "docked" | "mobile" | "unknown"
    property string dgpuState: "unknown" // "active" | "suspended" | "unknown"
    property real dgpuPowerW: 0
    property real dgpuTempC: 0

    property string _configPath: "%1/.config/hypr/source/environment_variables.conf".arg(Qt.getenv("HOME"))
    property string _dgpuDevicePath: "/sys/bus/pci/devices/0000:01:00.0/power/runtime_status"

    FileView {
        id: configFile
        path: root._configPath
    }

    FileView {
        id: dgpuStatusFile
        path: root._dgpuDevicePath
    }

    Process {
        id: nvidiaStatsProc

        command: ["nvidia-smi", "--format=csv,noheader", "--query-gpu=power.draw,temperature.gpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",").map(s => parseFloat(s.trim()));
                if (parts.length === 2) {
                    root.dgpuPowerW = parts[0];
                    root.dgpuTempC = parts[1];
                }
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: true
        repeat: true

        onTriggered: {
            updateProfile();
            updateDgpuState();
            if (root.profile === "docked" && root.dgpuState === "active") {
                nvidiaStatsProc.running = true;
            }
        }
    }

    function updateProfile() {
        const content = configFile.text();
        if (content.includes("env = AQ_DRM_DEVICES")) {
            root.profile = "docked";
        } else if (content.includes("# env = AQ_DRM_DEVICES")) {
            root.profile = "mobile";
        } else {
            root.profile = "unknown";
        }
    }

    function updateDgpuState() {
        const state = dgpuStatusFile.text().trim().toLowerCase();
        if (state === "active" || state === "D0") {
            root.dgpuState = "active";
        } else if (state === "suspended" || state.includes("RTD3") || state === "D3cold") {
            root.dgpuState = "suspended";
        } else {
            root.dgpuState = "unknown";
        }
    }

    Component.onCompleted: {
        configFile.reload();
        dgpuStatusFile.reload();
        updateProfile();
        updateDgpuState();
    }
}
