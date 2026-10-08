pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config

// CPU temperature, fan RPM, and other system thermal metrics
Singleton {
    id: root

    property int refCount: 0

    property real cpuTempC: NaN
    property int fanRpmMin: 0
    property int fanRpmMax: 0

    Process {
        id: sensorsProc

        command: ["sensors", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                parseSensorsOutput(text);
            }
        }
    }

    Timer {
        interval: GlobalConfig.dashboard.resourceUpdateInterval
        running: root.refCount > 0
        repeat: true

        onTriggered: {
            sensorsProc.running = true;
        }
    }

    function parseSensorsOutput(json: string): void {
        let data;
        try {
            data = JSON.parse(json);
        } catch (e) {
            return;
        }

        // sensors -j: { chip: { feature: { name_input: value } } }, values already in °C / RPM
        let pkg = NaN;
        let hottest = NaN;
        let fanMin = 0;
        let fanMax = 0;
        for (const chip in data) {
            for (const feature in data[chip]) {
                const f = data[chip][feature];
                if (typeof f !== "object")
                    continue;
                for (const key in f) {
                    if (!key.endsWith("_input"))
                        continue;
                    const v = f[key];
                    if (chip.startsWith("coretemp") && key.startsWith("temp")) {
                        if (feature.startsWith("Package"))
                            pkg = v;
                        hottest = isNaN(hottest) ? v : Math.max(hottest, v);
                    } else if (key.startsWith("fan") && v > 0) {
                        fanMin = fanMin === 0 ? v : Math.min(fanMin, v);
                        fanMax = Math.max(fanMax, v);
                    }
                }
            }
        }

        const cpu = isNaN(pkg) ? hottest : pkg;
        if (!isNaN(cpu))
            root.cpuTempC = cpu;
        root.fanRpmMin = Math.round(fanMin);
        root.fanRpmMax = Math.round(fanMax);
    }

    Component.onCompleted: {
        sensorsProc.running = true;
    }
}
